"""
Authentication routes
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from marshmallow import ValidationError
from app.schemas import UserSchema, LoginSchema
from app.services import AuthService
from app.utils import success_response, error_response, get_current_user, role_required
from app.models.user import UserRole

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')


@auth_bp.route('/login', methods=['POST'])
def login():
    """User login"""
    try:
        schema = LoginSchema()
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    result, error = AuthService.login(data['username'], data['password'])
    
    if error:
        return error_response(error, 401)
    
    return success_response(result, "Login successful")


@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user_info():
    """Get current user information"""
    user = get_current_user()
    
    if not user:
        return error_response("Session expired. Please log in again.", 401)
    
    return success_response(user.to_dict())


@auth_bp.route('/change-password', methods=['POST'])
@jwt_required()
def change_password():
    """Change current user password"""
    data = request.json
    
    if not data.get('old_password') or not data.get('new_password'):
        return error_response("Old password and new password are required", 400)
    
    user_id = int(get_jwt_identity())
    success, message = AuthService.change_password(
        user_id,
        data['old_password'],
        data['new_password']
    )
    
    if not success:
        return error_response(message, 400)
    
    return success_response(message=message)


@auth_bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    """
    Logout current user
    Note: Since we're using stateless JWT, this is mainly for client-side cleanup.
    In production, consider implementing JWT blacklisting.
    """
    return success_response(message="Logged out successfully")
