"""
Branch model - Multi-branch support (scoped to a gym)
"""
from datetime import datetime
from app.extensions import db


class Branch(db.Model):
    """Branch/Location model — belongs to a Gym."""
    __tablename__ = 'branches'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), nullable=False, index=True)
    code = db.Column(db.String(20), nullable=False, index=True)
    address = db.Column(db.Text, nullable=True)
    phone = db.Column(db.String(20), nullable=True)
    city = db.Column(db.String(100), nullable=True)

    # Gym ownership — every branch belongs to exactly one gym
    gym_id = db.Column(db.Integer, db.ForeignKey('gyms.id'), nullable=True, index=True)
    gym = db.relationship('Gym', backref=db.backref('branches', lazy='dynamic'))
    
    # Status
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    staff = db.relationship('User', back_populates='branch', lazy='dynamic')
    customers = db.relationship('Customer', back_populates='branch', lazy='dynamic')
    subscriptions = db.relationship('Subscription', back_populates='branch', lazy='dynamic')
    transactions = db.relationship('Transaction', back_populates='branch', lazy='dynamic')
    expenses = db.relationship('Expense', back_populates='branch', lazy='dynamic')
    complaints = db.relationship('Complaint', back_populates='branch', lazy='dynamic')
    daily_closings = db.relationship('DailyClosing', back_populates='branch', lazy='dynamic')

    # Unique constraint: branch name + code unique within a gym
    __table_args__ = (
        db.UniqueConstraint('gym_id', 'name', name='uq_gym_branch_name'),
        db.UniqueConstraint('gym_id', 'code', name='uq_gym_branch_code'),
    )

    @property
    def staff_count(self):
        """Count of staff members at this branch"""
        return self.staff.count()

    @property
    def customers_count(self):
        """Count of customers at this branch"""
        return self.customers.count()

    def __repr__(self):
        return f'<Branch {self.name} ({self.code})>'

    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'name': self.name,
            'code': self.code,
            'address': self.address,
            'phone': self.phone,
            'city': self.city,
            'gym_id': self.gym_id,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat(),
            'staff_count': self.staff.count(),
            'customers_count': self.customers.count()
        }
