"""
Complaint management routes
"""
import logging
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from marshmallow import ValidationError
from app.schemas import ComplaintSchema, ComplaintUpdateSchema
from app.models.complaint import Complaint, ComplaintStatus
from app.utils import (
    success_response, error_response, role_required,
    paginate, format_pagination_response, get_current_user
)
from app.models.user import UserRole
from app.extensions import db

logger = logging.getLogger(__name__)

complaints_bp = Blueprint('complaints', __name__, url_prefix='/api/complaints')


@complaints_bp.route('', methods=['GET'])
@jwt_required()
def get_complaints():
    """Get all complaints (paginated)"""
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    branch_id = request.args.get('branch_id', type=int)
    status = request.args.get('status', type=str)
    
    user = get_current_user()
    
    query = Complaint.query
    
    # Branch filtering based on role
    if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id:
            query = query.filter_by(branch_id=user.branch_id)
    elif branch_id:
        query = query.filter_by(branch_id=branch_id)
    
    # Status filter
    if status:
        try:
            query = query.filter_by(status=ComplaintStatus(status))
        except ValueError:
            return error_response("Invalid status", 400)
    
    query = query.order_by(Complaint.created_at.desc())
    
    items, total, pages, current_page = paginate(query, page, per_page)
    
    schema = ComplaintSchema()
    return success_response(
        format_pagination_response(items, total, pages, current_page, schema)
    )


@complaints_bp.route('/<int:complaint_id>', methods=['GET'])
@jwt_required()
def get_complaint(complaint_id):
    """Get complaint by ID"""
    complaint = db.session.get(Complaint, complaint_id)
    
    if not complaint:
        return error_response("Complaint not found", 404)
    
    # Check branch access
    user = get_current_user()
    if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id and complaint.branch_id != user.branch_id:
            return error_response("Access denied", 403)
    
    return success_response(complaint.to_dict())


@complaints_bp.route('', methods=['POST'])
@jwt_required()
def create_complaint():
    """Create new complaint"""
    try:
        schema = ComplaintSchema()
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    user = get_current_user()
    
    # Validate branch access
    if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id and data['branch_id'] != user.branch_id:
            return error_response("Cannot create complaint for another branch", 403)
    
    complaint = Complaint(
        title=data['title'],
        description=data['description'],
        complaint_type=data['complaint_type'],
        branch_id=data['branch_id'],
        customer_id=data.get('customer_id'),
        customer_name=data.get('customer_name'),
        customer_phone=data.get('customer_phone'),
        status=ComplaintStatus.OPEN
    )
    
    db.session.add(complaint)
    db.session.commit()
    
    # Notify owner/branch manager about the new complaint
    try:
        from app.services.fcm_service import notify_role
        notify_role(
            'owner',
            '📋 شكوى جديدة',
            f'{complaint.title}',
            {'type': 'new_complaint', 'complaint_id': str(complaint.id)},
        )
        notify_role(
            'branch_manager',
            '📋 شكوى جديدة',
            f'{complaint.title}',
            {'type': 'new_complaint', 'complaint_id': str(complaint.id)},
        )
    except Exception as e:
        logger.exception('Push notification failed: %s', e)

    return success_response(complaint.to_dict(), "Complaint created successfully", 201)


@complaints_bp.route('/<int:complaint_id>', methods=['PUT'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK)
def update_complaint(complaint_id):
    """Update complaint status"""
    complaint = db.session.get(Complaint, complaint_id)
    
    if not complaint:
        return error_response("Complaint not found", 404)
    
    # Check branch access
    user = get_current_user()
    if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id and complaint.branch_id != user.branch_id:
            return error_response("Access denied", 403)
    
    try:
        schema = ComplaintUpdateSchema()
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    if 'status' in data:
        complaint.status = ComplaintStatus(data['status'])
        
        if complaint.status == ComplaintStatus.CLOSED:
            from datetime import datetime
            complaint.resolved_at = datetime.utcnow()
    
    if 'resolution_notes' in data:
        complaint.resolution_notes = data['resolution_notes']
    
    db.session.commit()
    
    return success_response(complaint.to_dict(), "Complaint updated successfully")


@complaints_bp.route('/<int:complaint_id>', methods=['DELETE'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER)
def delete_complaint(complaint_id):
    """Delete complaint"""
    complaint = db.session.get(Complaint, complaint_id)
    
    if not complaint:
        return error_response("Complaint not found", 404)
    
    # Check branch access
    user = get_current_user()
    if user.role not in [UserRole.OWNER]:
        if user.branch_id and complaint.branch_id != user.branch_id:
            return error_response("Access denied", 403)
    
    db.session.delete(complaint)
    db.session.commit()
    
    return success_response(message="Complaint deleted successfully")
