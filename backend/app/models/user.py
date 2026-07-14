"""
User model - Authentication and staff management
"""
from datetime import datetime
from app.extensions import db
from passlib.hash import pbkdf2_sha256
import enum


class UserRole(enum.Enum):
    """User roles in the system"""
    SUPER_ADMIN = 'super_admin'
    OWNER = 'owner'
    BRANCH_MANAGER = 'branch_manager'
    FRONT_DESK = 'front_desk'
    ACCOUNTANT = 'accountant'
    BRANCH_ACCOUNTANT = 'branch_accountant'
    CENTRAL_ACCOUNTANT = 'central_accountant'


class User(db.Model):
    """User model for staff and administrators"""
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False, index=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    full_name = db.Column(db.String(150), nullable=False)
    phone = db.Column(db.String(20), nullable=True)
    role = db.Column(db.Enum(UserRole), nullable=False, index=True)
    
    # Gym ownership — every staff member belongs to a gym (set on creation)
    gym_id = db.Column(db.Integer, db.ForeignKey('gyms.id'), nullable=True, index=True)

    # Branch relationship (nullable for Owner and Central roles)
    branch_id = db.Column(db.Integer, db.ForeignKey('branches.id'), nullable=True, index=True)
    branch = db.relationship('Branch', back_populates='staff')
    
    # Status
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login = db.Column(db.DateTime, nullable=True)
    
    # Relationships
    transactions = db.relationship('Transaction', back_populates='created_by_user', lazy='dynamic')
    expenses = db.relationship('Expense', foreign_keys='Expense.created_by_id', back_populates='created_by', lazy='dynamic')
    daily_closings = db.relationship('DailyClosing', back_populates='closed_by_user', lazy='dynamic')

    def __repr__(self):
        return f'<User {self.username} ({self.role.value})>'

    def set_password(self, password):
        """Hash and set password"""
        self.password_hash = pbkdf2_sha256.hash(password)

    def check_password(self, password):
        """Verify password"""
        return pbkdf2_sha256.verify(password, self.password_hash)

    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'full_name': self.full_name,
            'phone': self.phone,
            'role': self.role.value,
            'gym_id': self.gym_id,
            'branch_id': self.branch_id,
            'branch_name': self.branch.name if self.branch else None,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat(),
            'last_login': self.last_login.isoformat() if self.last_login else None
        }

    @staticmethod
    def validate_owner_uniqueness():
        """Ensure only ONE owner exists in the system"""
        owner_count = User.query.filter_by(role=UserRole.OWNER).count()
        return owner_count < 1
