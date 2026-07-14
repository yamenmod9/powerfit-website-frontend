"""
Fingerprint access control routes
"""
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from marshmallow import ValidationError
from app.schemas import FingerprintSchema, FingerprintRegisterSchema, FingerprintValidateSchema
from app.models.fingerprint import Fingerprint
from app.models.customer import Customer
from app.utils import (
    success_response, error_response, role_required,
    paginate, format_pagination_response, get_current_user
)
from app.models.user import UserRole
from app.extensions import db

fingerprints_bp = Blueprint('fingerprints', __name__, url_prefix='/api/fingerprints')


@fingerprints_bp.route('', methods=['GET'])
@jwt_required()
def get_fingerprints():
    """Get all fingerprints (paginated)"""
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    customer_id = request.args.get('customer_id', type=int)
    is_active = request.args.get('is_active', type=bool)
    
    query = Fingerprint.query
    
    if customer_id:
        query = query.filter_by(customer_id=customer_id)
    
    if is_active is not None:
        query = query.filter_by(is_active=is_active)
    
    query = query.order_by(Fingerprint.created_at.desc())
    
    items, total, pages, current_page = paginate(query, page, per_page)
    
    schema = FingerprintSchema()
    return success_response(
        format_pagination_response(items, total, pages, current_page, schema)
    )


@fingerprints_bp.route('/register', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK)
def register_fingerprint():
    """Register new fingerprint for customer"""
    try:
        schema = FingerprintRegisterSchema()
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    # Validate customer
    customer = db.session.get(Customer, data['customer_id'])
    if not customer:
        return error_response("Customer not found", 404)
    
    # Check if customer already has an active fingerprint
    existing = Fingerprint.query.filter_by(
        customer_id=customer.id,
        is_active=True
    ).first()
    
    if existing:
        return error_response("Customer already has an active fingerprint", 400)

    # ── Duplicate biometric check ──────────────────────────────
    # Compute a deterministic hash of just the biometric data
    # and verify it isn't already registered to another customer.
    template_hash = Fingerprint.generate_template_hash(data['unique_data'])

    duplicate = Fingerprint.query.filter(
        Fingerprint.template_hash == template_hash,
        Fingerprint.customer_id != customer.id,
        Fingerprint.is_active == True,
    ).first()

    if duplicate:
        return error_response(
            "This fingerprint is already registered to another customer "
            f"(Customer #{duplicate.customer_id} - {duplicate.customer.full_name})",
            400,
        )
    
    # Generate fingerprint hash (simulated)
    fingerprint_hash = Fingerprint.generate_fingerprint_hash(
        customer.id,
        data['unique_data']
    )
    
    fingerprint = Fingerprint(
        customer_id=customer.id,
        fingerprint_hash=fingerprint_hash,
        template_hash=template_hash,
        is_active=True
    )
    
    db.session.add(fingerprint)
    db.session.commit()
    
    return success_response(fingerprint.to_dict(), "Fingerprint registered successfully", 201)


@fingerprints_bp.route('/validate', methods=['POST'])
def validate_fingerprint():
    """Validate fingerprint for access (public endpoint for kiosk)"""
    try:
        schema = FingerprintValidateSchema()
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    # Find fingerprint
    fingerprint = Fingerprint.query.filter_by(
        fingerprint_hash=data['fingerprint_hash']
    ).first()
    
    if not fingerprint:
        return error_response("Fingerprint not recognized", 404)
    
    # Validate access
    success, message = fingerprint.validate_access()
    
    if not success:
        return error_response(message, 403)
    
    return success_response({
        'customer': fingerprint.customer.to_dict(),
        'access_granted': True,
        'message': message
    })


@fingerprints_bp.route('/<int:fingerprint_id>/deactivate', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK)
def deactivate_fingerprint(fingerprint_id):
    """Deactivate fingerprint"""
    fingerprint = db.session.get(Fingerprint, fingerprint_id)
    
    if not fingerprint:
        return error_response("Fingerprint not found", 404)
    
    data = request.json or {}
    reason = data.get('reason', 'Manual deactivation')
    
    fingerprint.deactivate(reason)
    db.session.commit()
    
    return success_response(fingerprint.to_dict(), "Fingerprint deactivated successfully")


@fingerprints_bp.route('/<int:fingerprint_id>/reactivate', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK)
def reactivate_fingerprint(fingerprint_id):
    """Reactivate fingerprint"""
    fingerprint = db.session.get(Fingerprint, fingerprint_id)
    
    if not fingerprint:
        return error_response("Fingerprint not found", 404)
    
    fingerprint.is_active = True
    fingerprint.deactivation_reason = None
    db.session.commit()
    
    return success_response(fingerprint.to_dict(), "Fingerprint reactivated successfully")
