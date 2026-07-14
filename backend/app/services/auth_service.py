"""
Authentication service - handles login, JWT, and user management
"""
from datetime import datetime
from flask_jwt_extended import create_access_token, create_refresh_token
from app.extensions import db
from app.models.user import User, UserRole
from app.models.gym import Gym


class AuthService:
    """Authentication and user management service"""
    
    @staticmethod
    def login(username, password):
        """Authenticate user and return tokens"""
        user = User.query.filter_by(username=username).first()
        
        if not user:
            return None, "Invalid username or password"
        
        if not user.check_password(password):
            return None, "Invalid username or password"
        
        if not user.is_active:
            return None, "Account is inactive"
        
        # Update last login
        user.last_login = datetime.utcnow()
        db.session.commit()
        
        # Create tokens - identity must be a string
        access_token = create_access_token(identity=str(user.id))
        refresh_token = create_refresh_token(identity=str(user.id))
        
        result = {
            'access_token': access_token,
            'refresh_token': refresh_token,
            'user': user.to_dict()
        }

        # Include gym data for owners
        if user.role == UserRole.OWNER:
            gym = Gym.query.filter_by(owner_id=user.id).first()
            if gym:
                result['gym'] = gym.to_dict()
        # For staff, find the gym they belong to
        elif user.gym_id:
            gym = Gym.query.get(user.gym_id)
            if gym:
                result['gym'] = gym.to_dict()

        return result, None
    
    @staticmethod
    def create_user(data):
        """Create a new user"""
        # Check if username already exists
        if User.query.filter_by(username=data['username']).first():
            return None, "Username already exists"
        
        # Check if email already exists
        if User.query.filter_by(email=data['email']).first():
            return None, "Email already exists"
        
        # Validate owner uniqueness (disabled for multi-gym SaaS - super admin can create multiple owners)
        # role = UserRole(data['role'])
        # if role == UserRole.OWNER:
        #     if not User.validate_owner_uniqueness():
        #         return None, "Owner account already exists. Only ONE owner is allowed."
        role = UserRole(data['role'])
        
        # Validate branch requirement for branch-specific roles
        branch_specific_roles = [
            UserRole.BRANCH_MANAGER,
            UserRole.FRONT_DESK,
            UserRole.BRANCH_ACCOUNTANT
        ]
        
        if role in branch_specific_roles and not data.get('branch_id'):
            return None, f"{role.value} must be assigned to a branch"
        
        # Create user
        user = User(
            username=data['username'],
            email=data['email'],
            full_name=data['full_name'],
            phone=data.get('phone'),
            role=role,
            gym_id=data.get('gym_id'),
            branch_id=data.get('branch_id'),
            is_active=data.get('is_active', True)
        )
        user.set_password(data['password'])
        
        db.session.add(user)
        db.session.commit()

        # Auto-create a Gym record for new owners
        if role == UserRole.OWNER:
            gym = Gym(
                name=f"{data['full_name']}'s Gym",
                owner_id=user.id,
                is_setup_complete=False,
            )
            db.session.add(gym)
            db.session.commit()

        return user, None
    
    @staticmethod
    def update_user(user_id, data):
        """Update user details"""
        user = db.session.get(User, user_id)
        if not user:
            return None, "User not found"
        
        # Update allowed fields
        if 'full_name' in data:
            user.full_name = data['full_name']
        if 'email' in data and data['email'] != user.email:
            if User.query.filter_by(email=data['email']).first():
                return None, "Email already exists"
            user.email = data['email']
        if 'phone' in data:
            user.phone = data['phone']
        if 'is_active' in data:
            user.is_active = data['is_active']
        if 'branch_id' in data:
            user.branch_id = data['branch_id']
        
        db.session.commit()
        return user, None
    
    @staticmethod
    def change_password(user_id, old_password, new_password):
        """Change user password"""
        user = db.session.get(User, user_id)
        if not user:
            return False, "User not found"
        
        if not user.check_password(old_password):
            return False, "Current password is incorrect"
        
        user.set_password(new_password)
        db.session.commit()
        
        return True, "Password changed successfully"
