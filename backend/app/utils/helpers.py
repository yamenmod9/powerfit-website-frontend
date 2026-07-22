"""
Helper utility functions
"""
from datetime import datetime, date, timedelta
from decimal import Decimal
from sqlalchemy import func, and_, or_
from app.extensions import db
from app.models.transaction import Transaction, PaymentMethod, TransactionType
from app.models.subscription import Subscription, SubscriptionStatus
from app.models.expense import Expense, ExpenseStatus
from app.models.complaint import Complaint, ComplaintStatus


def calculate_branch_revenue(branch_id, start_date=None, end_date=None):
    """Calculate total revenue for a branch in date range"""
    query = Transaction.query.filter_by(branch_id=branch_id)
    
    if start_date:
        query = query.filter(Transaction.transaction_date >= start_date)
    if end_date:
        query = query.filter(Transaction.transaction_date <= end_date)
    
    total = db.session.query(func.sum(Transaction.amount)).filter(
        Transaction.branch_id == branch_id
    )
    
    if start_date:
        total = total.filter(Transaction.transaction_date >= start_date)
    if end_date:
        total = total.filter(Transaction.transaction_date <= end_date)
    
    result = total.scalar()
    return float(result) if result else 0.0


def get_expiring_subscriptions(days=7, branch_id=None):
    """Get subscriptions expiring within X days.

    branch_id accepts either a single id or a list/tuple of ids, so callers
    scoping to a branch group can do it in one query instead of one per branch.
    """
    today = date.today()
    expiry_date = today + timedelta(days=days)

    query = Subscription.query.filter(
        Subscription.status == SubscriptionStatus.ACTIVE,
        Subscription.end_date >= today,
        Subscription.end_date <= expiry_date
    )

    if branch_id is not None:
        if isinstance(branch_id, (list, tuple, set)):
            query = query.filter(Subscription.branch_id.in_(branch_id))
        else:
            query = query.filter_by(branch_id=branch_id)

    return query.all()


def get_daily_transactions_summary(branch_id, transaction_date):
    """Get summary of transactions for a specific day"""
    start_datetime = datetime.combine(transaction_date, datetime.min.time())
    end_datetime = datetime.combine(transaction_date, datetime.max.time())
    
    transactions = Transaction.query.filter(
        Transaction.branch_id == branch_id,
        Transaction.transaction_date >= start_datetime,
        Transaction.transaction_date <= end_datetime
    ).all()
    
    summary = {
        'total': 0,
        'cash': 0,
        'network': 0,
        'transfer': 0,
        'count': len(transactions)
    }
    
    for txn in transactions:
        amount = float(txn.amount)
        summary['total'] += amount
        
        if txn.payment_method == PaymentMethod.CASH:
            summary['cash'] += amount
        elif txn.payment_method == PaymentMethod.NETWORK:
            summary['network'] += amount
        elif txn.payment_method == PaymentMethod.TRANSFER:
            summary['transfer'] += amount
    
    return summary


def get_pending_expenses(branch_id=None):
    """Get pending expenses"""
    query = Expense.query.filter_by(status=ExpenseStatus.PENDING)
    
    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    
    return query.all()


def get_open_complaints(branch_id=None):
    """Get open complaints"""
    query = Complaint.query.filter(
        or_(
            Complaint.status == ComplaintStatus.OPEN,
            Complaint.status == ComplaintStatus.IN_PROGRESS
        )
    )
    
    if branch_id:
        query = query.filter_by(branch_id=branch_id)
    
    return query.all()


def get_active_customers_count(branch_id=None):
    """Get count of customers with active subscriptions"""
    from app.models.customer import Customer
    
    query = db.session.query(Customer.id).join(Subscription).filter(
        Subscription.status == SubscriptionStatus.ACTIVE
    )
    
    if branch_id:
        query = query.filter(Customer.branch_id == branch_id)
    
    return query.distinct().count()


def compare_branches_performance(start_date=None, end_date=None):
    """Compare revenue performance across all branches.

    One grouped query per metric across every branch, instead of the
    previous 5-queries-per-branch loop (calculate_branch_revenue,
    get_active_customers_count, plus 3 more .count() calls each) — this
    runs on every owner-dashboard load.
    """
    from app.models.branch import Branch
    from app.models.user import User
    from app.models.complaint import Complaint, ComplaintStatus
    from app.models.customer import Customer

    branches = Branch.query.filter_by(is_active=True).all()
    branch_ids = [b.id for b in branches]
    if not branch_ids:
        return []

    revenue_query = db.session.query(
        Transaction.branch_id, func.sum(Transaction.amount)
    ).filter(Transaction.branch_id.in_(branch_ids))
    if start_date:
        revenue_query = revenue_query.filter(Transaction.transaction_date >= start_date)
    if end_date:
        revenue_query = revenue_query.filter(Transaction.transaction_date <= end_date)
    revenue_by_branch = dict(revenue_query.group_by(Transaction.branch_id).all())

    active_customers_by_branch = dict(
        db.session.query(Customer.branch_id, func.count(func.distinct(Customer.id)))
        .join(Subscription, Subscription.customer_id == Customer.id)
        .filter(Customer.branch_id.in_(branch_ids), Subscription.status == SubscriptionStatus.ACTIVE)
        .group_by(Customer.branch_id).all()
    )

    customers_by_branch = dict(
        db.session.query(Customer.branch_id, func.count(Customer.id))
        .filter(Customer.branch_id.in_(branch_ids), Customer.is_active == True)
        .group_by(Customer.branch_id).all()
    )

    active_subs_by_branch = dict(
        db.session.query(Subscription.branch_id, func.count(Subscription.id))
        .filter(Subscription.branch_id.in_(branch_ids), Subscription.status == SubscriptionStatus.ACTIVE)
        .group_by(Subscription.branch_id).all()
    )

    staff_by_branch = dict(
        db.session.query(User.branch_id, func.count(User.id))
        .filter(User.branch_id.in_(branch_ids), User.is_active == True)
        .group_by(User.branch_id).all()
    )

    complaints_by_branch = dict(
        db.session.query(Complaint.branch_id, func.count(Complaint.id))
        .filter(Complaint.branch_id.in_(branch_ids), Complaint.status == ComplaintStatus.OPEN)
        .group_by(Complaint.branch_id).all()
    )

    performance = []
    for branch in branches:
        revenue = float(revenue_by_branch.get(branch.id) or 0)
        active_customers = active_customers_by_branch.get(branch.id, 0)
        customers = customers_by_branch.get(branch.id, 0)
        active_subs = active_subs_by_branch.get(branch.id, 0)
        staff_count = staff_by_branch.get(branch.id, 0)
        open_complaints = complaints_by_branch.get(branch.id, 0)

        # Simple performance score
        performance_score = min(100, int(
            (active_subs / max(customers, 1) * 50) +
            (revenue / 100000 * 30) +
            (max(0, 20 - open_complaints * 2))
        ))

        performance.append({
            'branch_id': branch.id,
            'branch_name': branch.name,
            'name': branch.name,
            'city': branch.city,
            'is_active': branch.is_active,
            'revenue': revenue,
            'active_customers': active_customers,
            'customers': customers,
            'active_subscriptions': active_subs,
            'staff_count': staff_count,
            'open_complaints': open_complaints,
            'performance_score': performance_score
        })

    # Sort by revenue descending
    performance.sort(key=lambda x: x['revenue'], reverse=True)

    return performance


def get_staff_performance(user_id, start_date=None, end_date=None):
    """Get performance metrics for a staff member"""
    query = Transaction.query.filter_by(created_by=user_id)
    
    if start_date:
        query = query.filter(Transaction.transaction_date >= start_date)
    if end_date:
        query = query.filter(Transaction.transaction_date <= end_date)
    
    transactions = query.all()
    
    total_revenue = sum(float(t.amount) for t in transactions)
    subscription_count = sum(1 for t in transactions if t.transaction_type == TransactionType.SUBSCRIPTION)
    
    return {
        'total_transactions': len(transactions),
        'total_revenue': total_revenue,
        'new_subscriptions': subscription_count
    }


def validate_subscription_dates(start_date, end_date):
    """Validate subscription date range"""
    if isinstance(start_date, str):
        start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
    if isinstance(end_date, str):
        end_date = datetime.strptime(end_date, '%Y-%m-%d').date()
    
    if end_date <= start_date:
        return False, "End date must be after start date"
    
    return True, None


def auto_expire_subscriptions():
    """Auto-expire subscriptions that have passed their end date"""
    today = date.today()
    
    expired = Subscription.query.filter(
        Subscription.status == SubscriptionStatus.ACTIVE,
        Subscription.end_date < today
    ).all()
    
    count = 0
    for sub in expired:
        sub.status = SubscriptionStatus.EXPIRED
        
        # Deactivate associated fingerprints
        from app.models.fingerprint import Fingerprint
        fingerprints = Fingerprint.query.filter_by(
            customer_id=sub.customer_id,
            is_active=True
        ).all()
        
        for fp in fingerprints:
            # Check if customer has other active subscriptions
            other_active = Subscription.query.filter(
                Subscription.customer_id == sub.customer_id,
                Subscription.id != sub.id,
                Subscription.status == SubscriptionStatus.ACTIVE
            ).first()
            
            if not other_active:
                fp.deactivate("Subscription expired")
        
        count += 1
    
    if count > 0:
        db.session.commit()
    
    return count
