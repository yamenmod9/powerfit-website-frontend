"""
Utility functions and decorators
"""
from functools import wraps
from flask import jsonify
from flask_jwt_extended import get_jwt_identity, verify_jwt_in_request
from app.models.user import User, UserRole
from app.extensions import db


def role_required(*allowed_roles):
    """
    Decorator to check if user has required role
    Usage: @role_required(UserRole.OWNER, UserRole.BRANCH_MANAGER)
           @role_required([UserRole.OWNER, UserRole.BRANCH_MANAGER])  # also supported
    """
    # Flatten: if caller passed a single list/tuple, unpack it
    if len(allowed_roles) == 1 and isinstance(allowed_roles[0], (list, tuple)):
        allowed_roles = tuple(allowed_roles[0])

    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            verify_jwt_in_request()
            user_id = int(get_jwt_identity())
            user = db.session.get(User, user_id)
            
            if not user:
                return jsonify({'success': False, 'error': 'Session expired. Please log in again.'}), 401
            
            if not user.is_active:
                return jsonify({'success': False, 'error': 'User account is inactive'}), 403
            
            if user.role not in allowed_roles:
                return jsonify({'success': False, 'error': 'Insufficient permissions'}), 403
            
            return fn(*args, **kwargs)
        return wrapper
    return decorator


def branch_access_required(fn):
    """
    Decorator to ensure user has access to the branch they're trying to access
    For branch-specific roles, ensures they can only access their own branch
    Owner and central roles can access all branches
    """
    @wraps(fn)
    def wrapper(*args, **kwargs):
        verify_jwt_in_request()
        user_id = int(get_jwt_identity())
        user = db.session.get(User, user_id)
        
        if not user:
            return jsonify({'success': False, 'error': 'Session expired. Please log in again.'}), 401
        
        # Owner, super admin, and central accountant can access all branches
        if user.role in [UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
            return fn(*args, **kwargs)
        
        # Branch-specific roles must have branch_id
        if not user.branch_id:
            return jsonify({'success': False, 'error': 'User not assigned to any branch'}), 403
        
        # Check if the requested branch_id matches user's branch
        requested_branch_id = kwargs.get('branch_id')
        if requested_branch_id and requested_branch_id != user.branch_id:
            return jsonify({'success': False, 'error': 'Access denied to this branch'}), 403
        
        return fn(*args, **kwargs)
    return wrapper


def get_current_user():
    """Get current authenticated user"""
    verify_jwt_in_request()
    user_id = int(get_jwt_identity())
    return db.session.get(User, user_id)


def get_current_gym_id(user=None):
    """Resolve the gym_id for the current user.
    
    - OWNER → gym they own
    - Staff  → their gym_id field (set at creation)
    - SUPER_ADMIN → None (sees everything)
    """
    if user is None:
        user = get_current_user()
    if user.role == UserRole.SUPER_ADMIN:
        return None  # super admin is above gym scope
    if user.role == UserRole.OWNER:
        from app.models.gym import Gym
        gym = Gym.query.filter_by(owner_id=user.id).first()
        return gym.id if gym else None
    return user.gym_id


def paginate(query, page=1, per_page=20):
    """
    Paginate a SQLAlchemy query
    Returns: (items, total, pages, current_page)
    """
    if page < 1:
        page = 1
    if per_page < 1 or per_page > 100:
        per_page = 20
    
    total = query.count()
    items = query.offset((page - 1) * per_page).limit(per_page).all()
    pages = (total + per_page - 1) // per_page
    
    return items, total, pages, page


def format_pagination_response(items, total, pages, current_page, schema):
    """Format paginated response"""
    return {
        'items': schema.dump(items, many=True),
        'pagination': {
            'total': total,
            'pages': pages,
            'current_page': current_page,
            'per_page': len(items)
        }
    }


def success_response(data=None, message=None, status=200):
    """Standard success response"""
    response = {'success': True}
    if message:
        response['message'] = message
    if data is not None:
        response['data'] = data
    return jsonify(response), status


def error_response(message, status=400, errors=None):
    """Standard error response"""
    response = {'success': False, 'error': message}
    if errors:
        response['errors'] = errors
    return jsonify(response), status
