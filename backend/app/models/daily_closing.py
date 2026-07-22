"""
Daily Closing model - Daily cash reconciliation
"""
from datetime import datetime
from app.extensions import db


class DailyClosing(db.Model):
    """Daily cash closing/reconciliation"""
    __tablename__ = 'daily_closings'

    id = db.Column(db.Integer, primary_key=True)
    
    # Branch
    branch_id = db.Column(db.Integer, db.ForeignKey('branches.id'), nullable=False, index=True)
    branch = db.relationship('Branch', back_populates='daily_closings')
    
    # Date
    closing_date = db.Column(db.Date, nullable=False, index=True, unique=False)
    
    # Cash amounts
    expected_cash = db.Column(db.Numeric(10, 2), nullable=False)  # From system
    actual_cash = db.Column(db.Numeric(10, 2), nullable=False)  # Physical count
    cash_difference = db.Column(db.Numeric(10, 2), nullable=False)  # Difference
    
    # Other payment methods (for reference)
    network_total = db.Column(db.Numeric(10, 2), default=0)
    transfer_total = db.Column(db.Numeric(10, 2), default=0)
    
    # Total revenue
    total_revenue = db.Column(db.Numeric(10, 2), nullable=False)
    
    # Closed by
    closed_by = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    closed_by_user = db.relationship('User', back_populates='daily_closings')
    
    # Notes
    notes = db.Column(db.Text, nullable=True)
    
    # Timestamp
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def __repr__(self):
        return f'<DailyClosing {self.closing_date} - Branch {self.branch_id}>'

    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'branch_id': self.branch_id,
            'branch_name': self.branch.name,
            'closing_date': self.closing_date.isoformat(),
            'expected_cash': float(self.expected_cash),
            'actual_cash': float(self.actual_cash),
            'cash_difference': float(self.cash_difference),
            'network_total': float(self.network_total),
            'transfer_total': float(self.transfer_total),
            'total_revenue': float(self.total_revenue),
            'closed_by': self.closed_by,
            'closed_by_name': self.closed_by_user.full_name,
            'notes': self.notes,
            'created_at': self.created_at.isoformat()
        }
