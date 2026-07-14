"""
Service management routes
"""
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from marshmallow import ValidationError
from app.schemas import ServiceSchema
from app.models.service import Service, ServiceType
from app.utils import (
    success_response, error_response, role_required,
    paginate, format_pagination_response
)
from app.models.user import UserRole
from app.extensions import db

services_bp = Blueprint('services', __name__, url_prefix='/api/services')


@services_bp.route('', methods=['GET'])
@jwt_required()
def get_services():
    """Get all services"""
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 50, type=int)
    service_type = request.args.get('type', type=str)
    is_active = request.args.get('is_active', True, type=bool)
    
    query = Service.query.filter_by(is_active=is_active)
    
    if service_type:
        try:
            query = query.filter_by(service_type=ServiceType(service_type))
        except ValueError:
            return error_response("Invalid service type", 400)
    
    query = query.order_by(Service.name)
    
    items, total, pages, current_page = paginate(query, page, per_page)
    
    schema = ServiceSchema()
    return success_response(
        format_pagination_response(items, total, pages, current_page, schema)
    )


@services_bp.route('/<int:service_id>', methods=['GET'])
@jwt_required()
def get_service(service_id):
    """Get service by ID"""
    service = db.session.get(Service, service_id)
    
    if not service:
        return error_response("Service not found", 404)
    
    return success_response(service.to_dict())


@services_bp.route('', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER)
def create_service():
    """Create new service"""
    try:
        schema = ServiceSchema()
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    service = Service(**data)
    db.session.add(service)
    db.session.commit()
    
    return success_response(service.to_dict(), "Service created successfully", 201)


@services_bp.route('/<int:service_id>', methods=['PUT'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER)
def update_service(service_id):
    """Update service"""
    service = db.session.get(Service, service_id)
    
    if not service:
        return error_response("Service not found", 404)
    
    try:
        schema = ServiceSchema(partial=True)
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    # Update fields
    for field in ['name', 'description', 'price', 'duration_days', 'allowed_days_per_week',
                  'class_limit', 'freeze_count_limit', 'freeze_max_days', 'freeze_is_paid',
                  'freeze_cost', 'is_active']:
        if field in data:
            setattr(service, field, data[field])
    
    db.session.commit()
    
    return success_response(service.to_dict(), "Service updated successfully")


@services_bp.route('/<int:service_id>', methods=['DELETE'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER)
def delete_service(service_id):
    """Deactivate service (soft delete)"""
    service = db.session.get(Service, service_id)
    
    if not service:
        return error_response("Service not found", 404)
    
    service.is_active = False
    db.session.commit()
    
    return success_response(message="Service deactivated successfully")
