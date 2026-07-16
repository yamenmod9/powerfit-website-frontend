"""
Expense model - Business expenses tracking
"""
from datetime import datetime
from app.extensions import db
import enum


class ExpenseStatus(enum.Enum):
    """Expense approval status"""
    PENDING = 'pending'
    APPROVED = 'approved'
    REJECTED = 'rejected'


class ExpenseCategory(enum.Enum):
    """
    The spending side of the chart of accounts.

    The union of what the two halves of the app already used while this was free
    text: the record-expense dialog offered rent/salaries/marketing and friends,
    while seed.py's templates also produce services, safety, insurance, training
    and software. Both sets are kept so no existing row has to be reinterpreted.

    Revenue has no twin here on purpose — Transaction.transaction_type already
    enumerates the income lines (subscription, renewal, freeze, other).
    """
    RENT = 'rent'
    SALARIES = 'salaries'
    UTILITIES = 'utilities'
    EQUIPMENT = 'equipment'
    MAINTENANCE = 'maintenance'
    SUPPLIES = 'supplies'
    MARKETING = 'marketing'
    INSURANCE = 'insurance'
    TRAINING = 'training'
    SERVICES = 'services'
    SAFETY = 'safety'
    SOFTWARE = 'software'
    OTHER = 'other'

    @classmethod
    def parse(cls, value):
        """
        Resolve a category from an API string, by value ('rent') or name ('RENT').

        Returns None for blank input; raises ValueError for anything unknown, so
        a typo is rejected at the boundary rather than stored.
        """
        if value is None or str(value).strip() == '':
            return None
        text = str(value).strip()
        try:
            return cls(text.lower())
        except ValueError:
            try:
                return cls[text.upper()]
            except KeyError:
                raise ValueError(f'Unknown expense category: {value}')


class Expense(db.Model):
    """Expense model - Track business expenses"""
    __tablename__ = 'expenses'

    id = db.Column(db.Integer, primary_key=True)
    
    # Expense details
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=True)
    amount = db.Column(db.Numeric(10, 2), nullable=False)
    # Stored as the enum's VALUE ('rent'), not its name — unlike the other enum
    # columns in this database, which hold names ('APPROVED', 'SUBSCRIPTION').
    # This column predates the enum as free text and every writer and reader
    # already speaks the lowercase form: the rows on disk, seed.py's templates,
    # the record-expense dialog, and the JSON the clients label. Matching it
    # keeps all four working untouched.
    #
    # validate_strings makes a bad write fail at insert. Without it SQLAlchemy
    # passes unknown strings straight through and only raises on the way back
    # out, which turns one typo into a table nobody can read.
    #
    # Indexed: the money page filters on it and the reports group by it.
    category = db.Column(
        db.Enum(
            ExpenseCategory,
            values_callable=lambda enum: [member.value for member in enum],
            validate_strings=True,
        ),
        nullable=True,
        index=True,
    )
    
    # Branch
    branch_id = db.Column(db.Integer, db.ForeignKey('branches.id'), nullable=False, index=True)
    branch = db.relationship('Branch', back_populates='expenses')
    
    # Approval workflow
    status = db.Column(db.Enum(ExpenseStatus), default=ExpenseStatus.PENDING, nullable=False, index=True)
    
    # Created by (who requested)
    created_by_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    created_by = db.relationship('User', foreign_keys=[created_by_id], back_populates='expenses')
    
    # Approved/Rejected by
    reviewed_by_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    reviewed_by = db.relationship('User', foreign_keys=[reviewed_by_id])
    
    review_notes = db.Column(db.Text, nullable=True)
    reviewed_at = db.Column(db.DateTime, nullable=True)
    
    # Timestamps
    expense_date = db.Column(db.Date, nullable=False, index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f'<Expense {self.title} - {self.amount}>'

    @property
    def branch_name(self):
        """Branch name for schema serialization"""
        return self.branch.name if self.branch else 'N/A'

    @property
    def created_by_name(self):
        """Creator name for schema serialization"""
        return self.created_by.full_name if self.created_by else 'N/A'

    @property
    def reviewed_by_name(self):
        """Reviewer name for schema serialization"""
        return self.reviewed_by.full_name if self.reviewed_by else None

    def approve(self, reviewer_id, notes=None):
        """Approve expense"""
        self.status = ExpenseStatus.APPROVED
        self.reviewed_by_id = reviewer_id
        self.review_notes = notes
        self.reviewed_at = datetime.utcnow()

    def reject(self, reviewer_id, notes):
        """Reject expense"""
        self.status = ExpenseStatus.REJECTED
        self.reviewed_by_id = reviewer_id
        self.review_notes = notes
        self.reviewed_at = datetime.utcnow()

    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'amount': float(self.amount),
            # The column is an enum now; the API keeps speaking the lowercase
            # value the clients already map to labels.
            'category': self.category.value if self.category else None,
            'branch_id': self.branch_id,
            'branch_name': self.branch.name,
            'status': self.status.value,
            'created_by_id': self.created_by_id,
            'created_by_name': self.created_by.full_name,
            'reviewed_by_id': self.reviewed_by_id,
            'reviewed_by_name': self.reviewed_by.full_name if self.reviewed_by else None,
            'review_notes': self.review_notes,
            'reviewed_at': self.reviewed_at.isoformat() if self.reviewed_at else None,
            'expense_date': self.expense_date.isoformat(),
            'created_at': self.created_at.isoformat()
        }
