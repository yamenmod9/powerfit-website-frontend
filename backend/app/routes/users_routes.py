"""
User management routes
"""
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from marshmallow import ValidationError
from app.schemas import UserSchema
from app.services import AuthService
from app.utils import (
    success_response, error_response, role_required,
    paginate, format_pagination_response,
    get_current_user, get_current_gym_id
)
from app.models.user import User, UserRole
from app.extensions import db

users_bp = Blueprint('users', __name__, url_prefix='/api/users')


@users_bp.route('', methods=['GET'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER)
def get_users():
    """Get all users (paginated, gym-scoped)"""
    user = get_current_user()
    gym_id = get_current_gym_id(user)

    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    role = request.args.get('role', type=str)
    branch_id = request.args.get('branch_id', type=int)
    
    query = User.query

    # Scope to gym (super admin sees all)
    if gym_id is not None:
        query = query.filter_by(gym_id=gym_id)
    
    if role:
        try:
            query = query.filter_by(role=UserRole(role))
        except ValueError:
            return error_response("Invalid role", 400)
    
    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    
    query = query.order_by(User.created_at.desc())
    
    items, total, pages, current_page = paginate(query, page, per_page)
    
    schema = UserSchema()
    return success_response(
        format_pagination_response(items, total, pages, current_page, schema)
    )


@users_bp.route('/employees', methods=['GET'])
@users_bp.route('/staff', methods=['GET'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER)
def get_employees():
    """Get all staff members (gym-scoped)"""
    user = get_current_user()
    gym_id = get_current_gym_id(user)
    
    role = request.args.get('role', type=str)
    branch_id = request.args.get('branch_id', type=int)
    
    query = User.query

    # Scope to gym
    if gym_id is not None:
        query = query.filter_by(gym_id=gym_id)
    
    # Branch managers can only see their own branch staff
    if user.role == UserRole.BRANCH_MANAGER:
        query = query.filter_by(branch_id=user.branch_id)
    elif branch_id:
        query = query.filter_by(branch_id=branch_id)
    
    if role:
        try:
            query = query.filter_by(role=UserRole(role))
        except ValueError:
            return error_response("Invalid role", 400)
    
    query = query.order_by(User.created_at.desc())
    users = query.all()
    
    return success_response([{
        'id': u.id,
        'username': u.username,
        'role': u.role.value,
        'full_name': u.full_name,
        'email': u.email,
        'phone': u.phone,
        'branch_id': u.branch_id,
        'branch_name': u.branch.name if u.branch else None,
        'is_active': u.is_active,
        'created_at': u.created_at.isoformat()
    } for u in users])


@users_bp.route('/<int:user_id>', methods=['GET'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER)
def get_user(user_id):
    """Get user by ID"""
    user = db.session.get(User, user_id)
    
    if not user:
        return error_response("User not found", 404)
    
    return success_response(user.to_dict())


@users_bp.route('', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER)
def create_user():
    """Create new user (auto-scoped to creator's gym)"""
    creator = get_current_user()
    gym_id = get_current_gym_id(creator)

    try:
        schema = UserSchema()
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    # Inject gym_id so the new user belongs to the same gym
    if gym_id is not None:
        data['gym_id'] = gym_id
    
    user, error = AuthService.create_user(data)
    
    if error:
        return error_response(error, 400)
    
    return success_response(user.to_dict(), "User created successfully", 201)


@users_bp.route('/<int:user_id>', methods=['PUT'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER)
def update_user(user_id):
    """Update user"""
    try:
        schema = UserSchema(partial=True)
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    user, error = AuthService.update_user(user_id, data)
    
    if error:
        return error_response(error, 400)
    
    return success_response(user.to_dict(), "User updated successfully")


@users_bp.route('/<int:user_id>', methods=['DELETE'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER)
def delete_user(user_id):
    """Deactivate user (soft delete)"""
    user = db.session.get(User, user_id)
    
    if not user:
        return error_response("User not found", 404)
    
    if user.role == UserRole.OWNER:
        return error_response("Cannot delete owner account", 403)
    
    user.is_active = False
    db.session.commit()
    
    return success_response(message="User deactivated successfully")
