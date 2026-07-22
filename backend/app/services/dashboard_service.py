"""
Dashboard service - analytics and reports
"""
from datetime import datetime, date, timedelta
from sqlalchemy import func, and_, or_, extract
from app.extensions import db
from app.models.user import User, UserRole
from app.models.branch import Branch
from app.models.customer import Customer
from app.models.subscription import Subscription, SubscriptionStatus
from app.models.transaction import Transaction, PaymentMethod
from app.models.expense import Expense, ExpenseStatus
from app.models.complaint import Complaint, ComplaintStatus
from app.utils.helpers import (
    get_expiring_subscriptions,
    get_open_complaints,
    calculate_branch_revenue,
    compare_branches_performance,
    get_staff_performance
)


class DashboardService:
    """Dashboard and reporting service"""
    
    @staticmethod
    def get_owner_dashboard(branch_ids=None):
        """Get comprehensive owner dashboard.

        branch_ids: optional list restricting every metric to those branches
        (used for regional managers, who see only their branch group).
        """
        today = date.today()
        thirty_days_ago = today - timedelta(days=30)
        seven_days_ago = today - timedelta(days=7)

        def branch_scoped(query, column):
            return query.filter(column.in_(branch_ids)) if branch_ids is not None else query

        # Smart alerts
        if branch_ids is not None:
            expiring_7 = len(get_expiring_subscriptions(days=7, branch_id=branch_ids))
            expiring_3 = len(get_expiring_subscriptions(days=3, branch_id=branch_ids))
        else:
            expiring_7 = len(get_expiring_subscriptions(days=7))
            expiring_3 = len(get_expiring_subscriptions(days=3))
        alerts = {
            'expiring_subscriptions': expiring_7,
            'expiring_soon': expiring_3,
            'open_complaints': branch_scoped(Complaint.query.filter(
                Complaint.status == ComplaintStatus.OPEN
            ), Complaint.branch_id).count(),
            'pending_expenses': branch_scoped(Expense.query.filter(
                Expense.status == ExpenseStatus.PENDING
            ), Expense.branch_id).count()
        }

        # Revenue summary (last 30 days)
        total_revenue = branch_scoped(db.session.query(func.sum(Transaction.amount)).filter(
            Transaction.transaction_date >= thirty_days_ago
        ), Transaction.branch_id).scalar() or 0

        # Active subscriptions
        active_subscriptions = branch_scoped(Subscription.query.filter(
            Subscription.status == SubscriptionStatus.ACTIVE
        ), Subscription.branch_id).count()

        # Total customers
        total_customers = branch_scoped(
            Customer.query.filter_by(is_active=True), Customer.branch_id
        ).count()

        # Branch comparison
        branch_performance = compare_branches_performance(thirty_days_ago, today)
        if branch_ids is not None:
            branch_performance = [
                b for b in branch_performance
                if (b.get('branch_id') or b.get('id')) in branch_ids
            ]

        # Best and worst branches
        best_branch = branch_performance[0] if branch_performance else None
        worst_branch = branch_performance[-1] if len(branch_performance) > 1 else None

        # Recent complaints by type
        complaints_by_type = branch_scoped(db.session.query(
            Complaint.complaint_type,
            func.count(Complaint.id)
        ).filter(
            Complaint.created_at >= thirty_days_ago
        ), Complaint.branch_id).group_by(Complaint.complaint_type).all()

        # Staff performance (top 5)
        staff_revenue = branch_scoped(db.session.query(
            User.id,
            User.full_name,
            func.sum(Transaction.amount).label('total')
        ).join(Transaction, Transaction.created_by == User.id).filter(
            Transaction.transaction_date >= thirty_days_ago
        ), Transaction.branch_id).group_by(User.id, User.full_name).order_by(func.sum(Transaction.amount).desc()).limit(5).all()
        
        return {
            'alerts': alerts,
            'revenue': {
                'total_30_days': float(total_revenue),
                'active_subscriptions': active_subscriptions,
                'total_customers': total_customers
            },
            'branches': {
                'performance': branch_performance,
                'best_branch': best_branch,
                'worst_branch': worst_branch
            },
            'complaints': {
                'by_type': [{'type': c[0].value, 'count': c[1]} for c in complaints_by_type]
            },
            'top_staff': [
                {'id': s[0], 'name': s[1], 'revenue': float(s[2])}
                for s in staff_revenue
            ]
        }
    
    @staticmethod
    def get_accountant_dashboard(branch_id=None, branch_ids=None):
        """Get accountant dashboard.

        branch_id restricts to one branch; branch_ids to a set (regional
        accountants). Passing neither means gym-wide (central tier).
        """
        today = date.today()
        current_month_start = today.replace(day=1)
        last_month_start = (current_month_start - timedelta(days=1)).replace(day=1)

        def scoped(query, column):
            if branch_id:
                return query.filter(column == branch_id)
            if branch_ids is not None:
                return query.filter(column.in_(branch_ids))
            return query

        # Daily sales (today)
        today_transactions = scoped(Transaction.query.filter(
            func.date(Transaction.transaction_date) == today
        ), Transaction.branch_id)
        
        today_summary = {
            'cash': 0,
            'network': 0,
            'transfer': 0,
            'total': 0
        }
        
        for txn in today_transactions.all():
            amount = float(txn.amount)
            today_summary['total'] += amount
            if txn.payment_method == PaymentMethod.CASH:
                today_summary['cash'] += amount
            elif txn.payment_method == PaymentMethod.NETWORK:
                today_summary['network'] += amount
            elif txn.payment_method == PaymentMethod.TRANSFER:
                today_summary['transfer'] += amount
        
        # Monthly revenue
        current_month_revenue = scoped(db.session.query(func.sum(Transaction.amount)).filter(
            Transaction.transaction_date >= current_month_start
        ), Transaction.branch_id)

        last_month_revenue = scoped(db.session.query(func.sum(Transaction.amount)).filter(
            and_(
                Transaction.transaction_date >= last_month_start,
                Transaction.transaction_date < current_month_start
            )
        ), Transaction.branch_id)

        current_month_total = current_month_revenue.scalar() or 0
        last_month_total = last_month_revenue.scalar() or 0

        # Expenses
        expenses_query = scoped(Expense.query.filter(
            Expense.expense_date >= current_month_start
        ), Expense.branch_id)
        
        approved_expenses = expenses_query.filter(
            Expense.status == ExpenseStatus.APPROVED
        ).all()
        
        total_expenses = sum(float(e.amount) for e in approved_expenses)
        
        # Pending expenses
        pending_expenses = expenses_query.filter(
            Expense.status == ExpenseStatus.PENDING
        ).count()
        
        return {
            'today': today_summary,
            'current_month': {
                'revenue': float(current_month_total),
                'expenses': total_expenses,
                'net': float(current_month_total) - total_expenses,
                'pending_expenses': pending_expenses
            },
            'last_month': {
                'revenue': float(last_month_total)
            },
            'comparison': {
                'change': float(current_month_total) - float(last_month_total),
                'percentage': ((float(current_month_total) - float(last_month_total)) / float(last_month_total) * 100)
                if last_month_total > 0 else 0
            }
        }
    
    @staticmethod
    def get_branch_manager_dashboard(branch_id):
        """Get branch manager dashboard"""
        today = date.today()
        seven_days_ago = today - timedelta(days=7)
        
        # Branch stats
        active_customers = db.session.query(Customer.id).join(Subscription).filter(
            Customer.branch_id == branch_id,
            Subscription.status == SubscriptionStatus.ACTIVE
        ).distinct().count()
        
        total_customers = Customer.query.filter_by(
            branch_id=branch_id,
            is_active=True
        ).count()
        
        # Revenue (last 7 days)
        weekly_revenue = calculate_branch_revenue(branch_id, seven_days_ago, today)
        
        # Expiring subscriptions
        expiring = get_expiring_subscriptions(days=7, branch_id=branch_id)
        
        # Open complaints
        open_complaints = get_open_complaints(branch_id=branch_id)
        
        # Staff count
        staff_count = User.query.filter_by(
            branch_id=branch_id,
            is_active=True
        ).count()
        
        return {
            'customers': {
                'active': active_customers,
                'total': total_customers
            },
            'revenue': {
                'last_7_days': weekly_revenue
            },
            'alerts': {
                'expiring_subscriptions': len(expiring),
                'open_complaints': len(open_complaints)
            },
            'staff': {
                'count': staff_count
            }
        }
    
    @staticmethod
    def get_revenue_report(start_date, end_date, branch_id=None, group_by='day'):
        """Get detailed revenue report"""
        query = Transaction.query.filter(
            and_(
                Transaction.transaction_date >= start_date,
                Transaction.transaction_date <= end_date
            )
        )
        
        if branch_id:
            query = query.filter_by(branch_id=branch_id)
        
        if group_by == 'day':
            results = db.session.query(
                func.date(Transaction.transaction_date).label('date'),
                func.sum(Transaction.amount).label('total'),
                func.count(Transaction.id).label('count')
            ).filter(
                and_(
                    Transaction.transaction_date >= start_date,
                    Transaction.transaction_date <= end_date
                )
            )
            
            if branch_id:
                results = results.filter(Transaction.branch_id == branch_id)
            
            results = results.group_by(func.date(Transaction.transaction_date)).all()
            
            return [{
                'date': r[0].isoformat(),
                'total': float(r[1]),
                'count': r[2]
            } for r in results]
        
        elif group_by == 'month':
            results = db.session.query(
                extract('year', Transaction.transaction_date).label('year'),
                extract('month', Transaction.transaction_date).label('month'),
                func.sum(Transaction.amount).label('total')
            ).filter(
                and_(
                    Transaction.transaction_date >= start_date,
                    Transaction.transaction_date <= end_date
                )
            )
            
            if branch_id:
                results = results.filter(Transaction.branch_id == branch_id)
            
            results = results.group_by('year', 'month').all()
            
            return [{
                'year': int(r[0]),
                'month': int(r[1]),
                'total': float(r[2])
            } for r in results]
        
        return []
