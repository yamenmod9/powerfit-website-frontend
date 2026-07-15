"""
Reports routes - Business intelligence and analytics
Maps /api/reports/* for Flutter app compatibility
"""
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from app.models import Transaction, Subscription, Customer, Branch, User
from app.models.transaction import PaymentMethod
from app.models.subscription import SubscriptionStatus
from app.models.complaint import ComplaintStatus
from app.utils import success_response, error_response, get_current_user, role_required, get_current_gym_id
from app.models.user import UserRole
from app.extensions import db
from datetime import datetime, timedelta
from sqlalchemy import func, and_
from collections import defaultdict

reports_bp = Blueprint('reports', __name__, url_prefix='/api/reports')


@reports_bp.route('/revenue', methods=['GET'])
@jwt_required()
@role_required([UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT, UserRole.BRANCH_ACCOUNTANT, UserRole.ACCOUNTANT])
def get_revenue_report():
    """
    Revenue report with breakdown by branch, service, and payment method
    
    Query params:
        - branch_id: Filter by specific branch
        - date_from: Start date (YYYY-MM-DD)
        - date_to: End date (YYYY-MM-DD)
    """
    branch_id = request.args.get('branch_id', type=int)
    date_from = request.args.get('date_from')
    date_to = request.args.get('date_to')
    
    current_user = get_current_user()
    
    # Build query
    query = Transaction.query
    
    # Role-based filtering
    if current_user.role == UserRole.BRANCH_ACCOUNTANT:
        query = query.filter(Transaction.branch_id == current_user.branch_id)
    elif branch_id:
        query = query.filter(Transaction.branch_id == branch_id)
    
    # Date range
    if date_from:
        try:
            start_date = datetime.strptime(date_from, '%Y-%m-%d')
            query = query.filter(Transaction.created_at >= start_date)
        except ValueError:
            pass
    
    if date_to:
        try:
            end_date = datetime.strptime(date_to, '%Y-%m-%d')
            query = query.filter(Transaction.created_at <= end_date)
        except ValueError:
            pass
    
    transactions = query.all()
    
    # Calculate total revenue
    total_revenue = float(sum(float(t.amount) - float(t.discount or 0) for t in transactions))

    # Revenue by branch
    revenue_by_branch = defaultdict(float)
    for t in transactions:
        if t.branch:
            revenue_by_branch[t.branch.name] += float(t.amount) - float(t.discount or 0)

    # Revenue by service
    revenue_by_service = defaultdict(float)
    for t in transactions:
        if t.subscription and t.subscription.service:
            service_name = t.subscription.service.name
            revenue_by_service[service_name] += float(t.amount) - float(t.discount or 0)

    # Revenue by payment method (keys match PaymentMethod enum values)
    revenue_by_payment_method = {
        'cash': 0.0,
        'network': 0.0,
        'transfer': 0.0
    }
    for t in transactions:
        key = t.payment_method.value
        if key in revenue_by_payment_method:
            revenue_by_payment_method[key] += float(t.amount) - float(t.discount or 0)

    # Format response
    revenue_by_branch_list = [
        {
            'branch_name': name,
            'revenue': float(revenue)
        }
        for name, revenue in revenue_by_branch.items()
    ]
    
    revenue_by_service_list = [
        {
            'service_name': name,
            'revenue': float(revenue)
        }
        for name, revenue in revenue_by_service.items()
    ]
    
    return success_response({
        'total_revenue': total_revenue,
        'revenue_by_branch': revenue_by_branch_list,
        'revenue_by_service': revenue_by_service_list,
        'revenue_by_payment_method': revenue_by_payment_method
    })


@reports_bp.route('/daily', methods=['GET'])
@jwt_required()
def get_daily_report():
    """
    Daily sales report
    
    Query params:
        - date: Specific date (YYYY-MM-DD, default: today)
        - branch_id: Filter by branch
    """
    date_str = request.args.get('date')
    branch_id = request.args.get('branch_id', type=int)
    
    if date_str:
        try:
            report_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return error_response('Invalid date format. Use YYYY-MM-DD', 400)
    else:
        report_date = datetime.utcnow().date()
    
    current_user = get_current_user()
    
    # Build query for transactions on this date
    start_datetime = datetime.combine(report_date, datetime.min.time())
    end_datetime = datetime.combine(report_date, datetime.max.time())
    
    query = Transaction.query.filter(
        and_(
            Transaction.created_at >= start_datetime,
            Transaction.created_at <= end_datetime
        )
    )
    
    # Role-based filtering
    if current_user.role not in [UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        query = query.filter(Transaction.branch_id == current_user.branch_id)
    elif branch_id:
        query = query.filter(Transaction.branch_id == branch_id)

    transactions = query.all()
    
    # Calculate metrics
    total_transactions = len(transactions)
    total_revenue = float(sum(float(t.amount) - float(t.discount or 0) for t in transactions))
    total_discount = float(sum(float(t.discount or 0) for t in transactions))

    # Payment method breakdown (keys match PaymentMethod enum values)
    payment_breakdown = {
        'cash': 0.0,
        'network': 0.0,
        'transfer': 0.0
    }
    for t in transactions:
        key = t.payment_method.value
        if key in payment_breakdown:
            payment_breakdown[key] += float(t.amount) - float(t.discount or 0)

    # New subscriptions today
    sub_query = Subscription.query.filter(
        func.date(Subscription.start_date) == report_date
    )
    
    if current_user.role not in [UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        sub_query = sub_query.filter(Subscription.branch_id == current_user.branch_id)
    elif branch_id:
        sub_query = sub_query.filter(Subscription.branch_id == branch_id)
    
    new_subscriptions = sub_query.count()
    
    return success_response({
        'date': report_date.isoformat(),
        'total_transactions': total_transactions,
        'total_revenue': total_revenue,
        'total_discount': total_discount,
        'new_subscriptions': new_subscriptions,
        'payment_breakdown': payment_breakdown,
        'transactions': [
            {
                'id': t.id,
                'customer_name': t.customer.full_name if t.customer else 'N/A',
                'amount': float(t.amount),
                'discount': float(t.discount or 0),
                'payment_method': t.payment_method.value,
                'time': t.created_at.strftime('%H:%M:%S')
            }
            for t in transactions
        ]
    })


@reports_bp.route('/weekly', methods=['GET'])
@jwt_required()
def get_weekly_report():
    """
    Weekly sales report
    
    Query params:
        - week_start: Week start date (YYYY-MM-DD, default: this week's Monday)
        - branch_id: Filter by branch
    """
    week_start_str = request.args.get('week_start')
    branch_id = request.args.get('branch_id', type=int)
    
    if week_start_str:
        try:
            week_start = datetime.strptime(week_start_str, '%Y-%m-%d').date()
        except ValueError:
            return error_response('Invalid date format. Use YYYY-MM-DD', 400)
    else:
        # Default to this week's Monday
        today = datetime.utcnow().date()
        week_start = today - timedelta(days=today.weekday())
    
    week_end = week_start + timedelta(days=6)
    
    current_user = get_current_user()
    
    # Build query
    start_datetime = datetime.combine(week_start, datetime.min.time())
    end_datetime = datetime.combine(week_end, datetime.max.time())
    
    query = Transaction.query.filter(
        and_(
            Transaction.created_at >= start_datetime,
            Transaction.created_at <= end_datetime
        )
    )
    
    # Role-based filtering
    if current_user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        query = query.filter(Transaction.branch_id == current_user.branch_id)
    elif branch_id:
        query = query.filter(Transaction.branch_id == branch_id)
    
    transactions = query.all()
    
    # Daily breakdown
    daily_revenue = defaultdict(float)
    for t in transactions:
        day = t.created_at.date()
        daily_revenue[day.isoformat()] += float(t.amount) - float(t.discount or 0)

    total_revenue = float(sum(float(t.amount) - float(t.discount or 0) for t in transactions))

    return success_response({
        'week_start': week_start.isoformat(),
        'week_end': week_end.isoformat(),
        'total_revenue': total_revenue,
        'total_transactions': len(transactions),
        'average_daily_revenue': total_revenue / 7,
        'daily_breakdown': [
            {'date': date, 'revenue': float(revenue)}
            for date, revenue in sorted(daily_revenue.items())
        ]
    })


@reports_bp.route('/monthly', methods=['GET'])
@jwt_required()
def get_monthly_report():
    """
    Monthly sales report
    
    Query params:
        - month: Month (YYYY-MM, default: current month)
        - branch_id: Filter by branch
    """
    month_str = request.args.get('month')
    branch_id = request.args.get('branch_id', type=int)
    
    if month_str:
        try:
            month_date = datetime.strptime(month_str, '%Y-%m')
        except ValueError:
            return error_response('Invalid month format. Use YYYY-MM', 400)
    else:
        month_date = datetime.utcnow().replace(day=1)
    
    # Calculate month range
    month_start = month_date.replace(day=1)
    if month_date.month == 12:
        month_end = month_date.replace(year=month_date.year + 1, month=1, day=1) - timedelta(days=1)
    else:
        month_end = month_date.replace(month=month_date.month + 1, day=1) - timedelta(days=1)
    
    current_user = get_current_user()
    
    # Build query
    start_datetime = datetime.combine(month_start.date(), datetime.min.time())
    end_datetime = datetime.combine(month_end.date(), datetime.max.time())
    
    query = Transaction.query.filter(
        and_(
            Transaction.created_at >= start_datetime,
            Transaction.created_at <= end_datetime
        )
    )
    
    if current_user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        query = query.filter(Transaction.branch_id == current_user.branch_id)
    elif branch_id:
        query = query.filter(Transaction.branch_id == branch_id)
    
    transactions = query.all()
    
    # Calculate metrics
    total_revenue = float(sum(float(t.amount) - float(t.discount or 0) for t in transactions))
    total_transactions = len(transactions)
    
    # New subscriptions this month
    sub_query = Subscription.query.filter(
        and_(
            Subscription.start_date >= month_start.date(),
            Subscription.start_date <= month_end.date()
        )
    )
    
    if current_user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        sub_query = sub_query.filter(Subscription.branch_id == current_user.branch_id)
    elif branch_id:
        sub_query = sub_query.filter(Subscription.branch_id == branch_id)
    
    new_subscriptions = sub_query.count()
    active_subscriptions = Subscription.query.filter_by(status=SubscriptionStatus.ACTIVE)
    
    if current_user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        active_subscriptions = active_subscriptions.filter(Subscription.branch_id == current_user.branch_id)
    elif branch_id:
        active_subscriptions = active_subscriptions.filter(Subscription.branch_id == branch_id)
    
    active_subscriptions_count = active_subscriptions.count()
    
    return success_response({
        'month': month_start.strftime('%Y-%m'),
        'total_revenue': total_revenue,
        'total_transactions': total_transactions,
        'new_subscriptions': new_subscriptions,
        'active_subscriptions': active_subscriptions_count,
        'average_transaction_value': total_revenue / total_transactions if total_transactions > 0 else 0
    })


@reports_bp.route('/branch-comparison', methods=['GET'])
@jwt_required()
@role_required([UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT])
def get_branch_comparison():
    """
    Compare performance across all branches
    
    Query params:
        - start_date: Start date (YYYY-MM-DD)
        - end_date: End date (YYYY-MM-DD)
        - month: Month for comparison (YYYY-MM, fallback if no start/end)
    """
    start_str = request.args.get('start_date')
    end_str = request.args.get('end_date')
    month_str = request.args.get('month')
    
    if start_str and end_str:
        try:
            month_start = datetime.strptime(start_str, '%Y-%m-%d')
            month_end = datetime.strptime(end_str, '%Y-%m-%d')
        except ValueError:
            return error_response('Invalid date format. Use YYYY-MM-DD', 400)
    elif month_str:
        try:
            month_date = datetime.strptime(month_str, '%Y-%m')
        except ValueError:
            return error_response('Invalid month format. Use YYYY-MM', 400)
        month_start = month_date.replace(day=1)
        if month_date.month == 12:
            month_end = month_date.replace(year=month_date.year + 1, month=1, day=1) - timedelta(days=1)
        else:
            month_end = month_date.replace(month=month_date.month + 1, day=1) - timedelta(days=1)
    else:
        # Default: last 90 days (captures more data than just current month)
        month_end = datetime.utcnow()
        month_start = month_end - timedelta(days=90)
    
    current_user = get_current_user()
    gym_id = get_current_gym_id(current_user)
    
    branch_query = Branch.query.filter_by(is_active=True)
    if gym_id:
        branch_query = branch_query.filter_by(gym_id=gym_id)
    branches = branch_query.all()
    
    branch_data = []
    
    for branch in branches:
        # Revenue
        transactions = Transaction.query.filter(
            and_(
                Transaction.branch_id == branch.id,
                Transaction.created_at >= datetime.combine(month_start.date(), datetime.min.time()),
                Transaction.created_at <= datetime.combine(month_end.date(), datetime.max.time())
            )
        ).all()
        
        revenue = float(sum(float(t.amount) - float(t.discount or 0) for t in transactions))

        # Customers
        customers = Customer.query.filter_by(branch_id=branch.id, is_active=True).count()
        
        # Active subscriptions
        active_subs = Subscription.query.filter_by(
            branch_id=branch.id,
            status=SubscriptionStatus.ACTIVE
        ).count()
        
        # Complaints
        from app.models import Complaint
        from app.models.complaint import ComplaintStatus
        complaints = Complaint.query.filter_by(branch_id=branch.id).count()
        open_complaints = Complaint.query.filter_by(branch_id=branch.id, status=ComplaintStatus.OPEN).count()

        # Calculate performance score (simple metric)
        performance_score = min(100, int(
            (active_subs / max(customers, 1) * 50) +  # Subscription rate
            (revenue / 100000 * 30) +  # Revenue factor
            (max(0, 20 - open_complaints * 2))  # Penalty for complaints
        ))
        
        # Staff count
        staff_count = User.query.filter_by(branch_id=branch.id, is_active=True).count()

        branch_data.append({
            'id': branch.id,
            'branch_id': branch.id,
            'name': branch.name,
            'branch_name': branch.name,
            'city': branch.city,
            'is_active': branch.is_active,
            'customers': customers,
            'active_subscriptions': active_subs,
            'staff_count': staff_count,
            'revenue': revenue,
            'complaints': complaints,
            'open_complaints': open_complaints,
            'performance_score': performance_score
        })
    
    # Sort by performance score
    branch_data.sort(key=lambda x: x['performance_score'], reverse=True)
    
    return success_response(branch_data)


@reports_bp.route('/employee-performance', methods=['GET'])
@jwt_required()
@role_required([UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.CENTRAL_ACCOUNTANT])
def get_employee_performance():
    """
    Employee performance report
    
    Query params:
        - branch_id: Filter by branch (required for branch manager)
        - start_date: Start date (YYYY-MM-DD)
        - end_date: End date (YYYY-MM-DD)
        - month: Month (YYYY-MM, fallback if no start/end)
    """
    branch_id = request.args.get('branch_id', type=int)
    start_str = request.args.get('start_date')
    end_str = request.args.get('end_date')
    month_str = request.args.get('month')
    
    current_user = get_current_user()
    
    # Branch managers can only see their branch
    if current_user.role == UserRole.BRANCH_MANAGER:
        branch_id = current_user.branch_id

    gym_id = get_current_gym_id(current_user)

    if not branch_id and current_user.role not in [UserRole.OWNER, UserRole.SUPER_ADMIN, UserRole.CENTRAL_ACCOUNTANT]:
        return error_response('branch_id is required', 400)
    
    if start_str and end_str:
        try:
            month_start = datetime.strptime(start_str, '%Y-%m-%d')
            month_end = datetime.strptime(end_str, '%Y-%m-%d')
        except ValueError:
            return error_response('Invalid date format. Use YYYY-MM-DD', 400)
    elif month_str:
        try:
            month_date = datetime.strptime(month_str, '%Y-%m')
        except ValueError:
            return error_response('Invalid month format. Use YYYY-MM', 400)
        month_start = month_date.replace(day=1)
        if month_date.month == 12:
            month_end = month_date.replace(year=month_date.year + 1, month=1, day=1) - timedelta(days=1)
        else:
            month_end = month_date.replace(month=month_date.month + 1, day=1) - timedelta(days=1)
    else:
        # Default: last 90 days
        month_end = datetime.utcnow()
        month_start = month_end - timedelta(days=90)
    
    # Get staff for branch
    staff_query = User.query.filter(User.role.in_([
        UserRole.BRANCH_MANAGER,
        UserRole.FRONT_DESK,
        UserRole.CENTRAL_ACCOUNTANT,
        UserRole.BRANCH_ACCOUNTANT
    ]))
    
    if gym_id:
        staff_query = staff_query.filter_by(gym_id=gym_id)
    
    if branch_id:
        staff_query = staff_query.filter_by(branch_id=branch_id)
    
    staff_members = staff_query.all()
    
    performance_data = []
    
    for staff in staff_members:
        # Count transactions created by this staff member
        transactions = Transaction.query.filter(
            and_(
                Transaction.created_by == staff.id,
                Transaction.created_at >= datetime.combine(month_start.date(), datetime.min.time()),
                Transaction.created_at <= datetime.combine(month_end.date(), datetime.max.time())
            )
        ).all()
        
        transactions_count = len(transactions)
        total_revenue = float(sum(float(t.amount) - float(t.discount or 0) for t in transactions))

        performance_data.append({
            'staff_id': staff.id,
            'staff_name': staff.username,
            'full_name': staff.full_name,
            'role': staff.role.value,
            'branch_name': staff.branch.name if staff.branch else 'N/A',
            'transactions_count': transactions_count,
            'total_revenue': total_revenue
        })
    
    # Sort by revenue
    performance_data.sort(key=lambda x: x['total_revenue'], reverse=True)
    
    return success_response(performance_data)
