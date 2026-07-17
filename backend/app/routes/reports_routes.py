"""
Reports routes - Business intelligence and analytics
Maps /api/reports/* for Flutter app compatibility
"""
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from app.models import Transaction, Subscription, Customer, Branch, User, Expense
from app.models.transaction import PaymentMethod, TransactionType
from app.models.subscription import SubscriptionStatus
from app.models.complaint import ComplaintStatus
from app.models.expense import ExpenseStatus
from app.utils import (
    success_response, error_response, get_current_user, role_required,
    get_current_gym_id, get_accessible_branch_ids, scope_query_to_branches
)
from app.models.user import UserRole
from app.extensions import db
from datetime import date, datetime, timedelta
from sqlalchemy import func, and_
from collections import defaultdict

reports_bp = Blueprint('reports', __name__, url_prefix='/api/reports')


@reports_bp.route('/revenue', methods=['GET'])
@jwt_required()
@role_required([UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT, UserRole.BRANCH_ACCOUNTANT, UserRole.ACCOUNTANT, UserRole.BRANCH_MANAGER])
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
    query = scope_query_to_branches(query, Transaction.branch_id, current_user, branch_id)
    
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

    # Revenue by category — the income side of the chart of accounts.
    #
    # There is no Transaction.category column and deliberately so: transaction_type
    # already enumerates exactly the income lines a P&L wants (subscription,
    # renewal, freeze, other), so a second field would restate it and drift.
    # Every type is seeded at 0.0 so a line never silently vanishes from a report.
    revenue_by_category = {t_type.value: 0.0 for t_type in TransactionType}
    transactions_by_category = {t_type.value: 0 for t_type in TransactionType}
    for t in transactions:
        key = t.transaction_type.value
        revenue_by_category[key] += float(t.amount) - float(t.discount or 0)
        transactions_by_category[key] += 1

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
        'revenue_by_payment_method': revenue_by_payment_method,
        'revenue_by_category': [
            {
                'category': category,
                'total': total,
                'count': transactions_by_category[category]
            }
            for category, total in sorted(
                revenue_by_category.items(), key=lambda kv: kv[1], reverse=True
            )
        ]
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
    query = scope_query_to_branches(query, Transaction.branch_id, current_user, branch_id)

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
    
    sub_query = scope_query_to_branches(sub_query, Subscription.branch_id, current_user, branch_id)
    
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
    query = scope_query_to_branches(query, Transaction.branch_id, current_user, branch_id)
    
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
    
    query = scope_query_to_branches(query, Transaction.branch_id, current_user, branch_id)

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

    sub_query = scope_query_to_branches(sub_query, Subscription.branch_id, current_user, branch_id)

    new_subscriptions = sub_query.count()
    active_subscriptions = Subscription.query.filter_by(status=SubscriptionStatus.ACTIVE)

    active_subscriptions = scope_query_to_branches(active_subscriptions, Subscription.branch_id, current_user, branch_id)
    
    active_subscriptions_count = active_subscriptions.count()
    
    return success_response({
        'month': month_start.strftime('%Y-%m'),
        'total_revenue': total_revenue,
        'total_transactions': total_transactions,
        'new_subscriptions': new_subscriptions,
        'active_subscriptions': active_subscriptions_count,
        'average_transaction_value': total_revenue / total_transactions if total_transactions > 0 else 0
    })


@reports_bp.route('/revenue-trend', methods=['GET'])
@jwt_required()
def get_revenue_trend():
    """
    Revenue as a time series, for trend charts.

    /daily, /weekly and /monthly each answer for a single window; this returns
    one point per period so a chart can plot movement over time in one request.

    Empty periods are returned with revenue 0.0 rather than omitted — a day with
    no sales genuinely earned nothing, and a gapless series keeps the x-axis
    honest about the passage of time.

    Query params:
        - period: daily | weekly | monthly (default: daily)
        - buckets: how many periods back, including the current one (max 36)
        - branch_id: Filter by branch
    """
    period = (request.args.get('period') or 'daily').lower()
    if period not in ('daily', 'weekly', 'monthly'):
        return error_response('period must be one of: daily, weekly, monthly', 400)

    default_buckets = {'daily': 14, 'weekly': 8, 'monthly': 6}[period]
    buckets = request.args.get('buckets', default_buckets, type=int)
    buckets = max(1, min(buckets, 36))
    branch_id = request.args.get('branch_id', type=int)

    today = datetime.utcnow().date()

    # Bucket start dates, oldest first.
    if period == 'daily':
        starts = [today - timedelta(days=i) for i in range(buckets - 1, -1, -1)]
    elif period == 'weekly':
        current_week = today - timedelta(days=today.weekday())
        starts = [current_week - timedelta(weeks=i) for i in range(buckets - 1, -1, -1)]
    else:
        starts = []
        for i in range(buckets - 1, -1, -1):
            month = today.month - i
            year = today.year
            while month <= 0:
                month += 12
                year -= 1
            starts.append(date(year, month, 1))

    def bucket_of(day):
        if period == 'daily':
            return day
        if period == 'weekly':
            return day - timedelta(days=day.weekday())
        return day.replace(day=1)

    current_user = get_current_user()

    # One query for the whole range; bucketing happens in memory rather than
    # per-period round trips.
    query = Transaction.query.filter(
        and_(
            Transaction.created_at >= datetime.combine(starts[0], datetime.min.time()),
            Transaction.created_at <= datetime.combine(today, datetime.max.time())
        )
    )

    # Never let one gym's revenue leak into another's chart.
    gym_id = get_current_gym_id(current_user)
    if gym_id:
        query = query.join(Branch, Transaction.branch_id == Branch.id).filter(
            Branch.gym_id == gym_id
        )

    query = scope_query_to_branches(query, Transaction.branch_id, current_user, branch_id)

    revenue_by_bucket = defaultdict(float)
    count_by_bucket = defaultdict(int)
    for t in query.all():
        key = bucket_of(t.created_at.date())
        revenue_by_bucket[key] += float(t.amount) - float(t.discount or 0)
        count_by_bucket[key] += 1

    def label_of(start):
        if period == 'daily':
            return start.strftime('%d %b')
        if period == 'weekly':
            return start.strftime('%d %b')
        return start.strftime('%b %Y')

    points = [
        {
            'date': start.isoformat(),
            'label': label_of(start),
            'revenue': revenue_by_bucket.get(start, 0.0),
            'transactions': count_by_bucket.get(start, 0)
        }
        for start in starts
    ]

    return success_response({
        'period': period,
        'buckets': buckets,
        'start_date': starts[0].isoformat(),
        'end_date': today.isoformat(),
        'total_revenue': float(sum(p['revenue'] for p in points)),
        'points': points
    })


@reports_bp.route('/expenses-by-category', methods=['GET'])
@jwt_required()
def get_expenses_by_category():
    """
    Expense totals grouped by category, for breakdown charts.

    Aggregated in SQL rather than by summing a page of /finance/expenses, so the
    totals stay correct however many expenses fall in the window.

    Dates filter on expense_date (when the money was spent) rather than
    created_at (when the row was filed), since this feeds accounting views.

    Query params:
        - date_from / date_to: Expense date range (YYYY-MM-DD)
        - branch_id: Filter by branch
        - status: pending | approved | rejected | all (default: approved)
    """
    date_from = request.args.get('date_from')
    date_to = request.args.get('date_to')
    branch_id = request.args.get('branch_id', type=int)
    status = (request.args.get('status') or 'approved').lower()

    query = db.session.query(
        Expense.category,  # an ExpenseCategory member, unwrapped below
        func.sum(Expense.amount).label('total'),
        func.count(Expense.id).label('count')
    )

    # 'all' opts out of the approved-only default (e.g. to include pending spend).
    if status != 'all':
        try:
            query = query.filter(Expense.status == ExpenseStatus(status))
        except ValueError:
            return error_response('status must be one of: pending, approved, rejected, all', 400)

    current_user = get_current_user()

    # Never let one gym's spending leak into another's breakdown.
    gym_id = get_current_gym_id(current_user)
    if gym_id:
        query = query.join(Branch, Expense.branch_id == Branch.id).filter(
            Branch.gym_id == gym_id
        )

    query = scope_query_to_branches(query, Expense.branch_id, current_user, branch_id)

    if date_from:
        try:
            query = query.filter(Expense.expense_date >= datetime.strptime(date_from, '%Y-%m-%d').date())
        except ValueError:
            return error_response('Invalid date format. Use YYYY-MM-DD', 400)

    if date_to:
        try:
            query = query.filter(Expense.expense_date <= datetime.strptime(date_to, '%Y-%m-%d').date())
        except ValueError:
            return error_response('Invalid date format. Use YYYY-MM-DD', 400)

    rows = query.group_by(Expense.category).all()

    categories = [
        {
            # row[0] is an ExpenseCategory; keep emitting the lowercase value the
            # clients label. Uncategorised spend is real money and still has to
            # show up somewhere.
            'category': row[0].value if row[0] else 'uncategorized',
            'total': float(row[1] or 0),
            'count': int(row[2] or 0)
        }
        for row in rows
    ]
    categories.sort(key=lambda c: c['total'], reverse=True)

    return success_response({
        'status': status,
        'total': float(sum(c['total'] for c in categories)),
        'categories': categories
    })


@reports_bp.route('/branch-comparison', methods=['GET'])
@jwt_required()
@role_required([UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT, UserRole.BRANCH_MANAGER])
def get_branch_comparison():
    """
    Compare performance across all branches

    Branch managers receive the same report scoped to their own branch only —
    they never see peer branches' revenue.

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

    # Branch managers get the same report scoped to their own branch — never a
    # view of peer branches' revenue. Regional managers see their branch group.
    accessible = get_accessible_branch_ids(current_user)
    if accessible is not None:
        if not accessible:
            return success_response([])
        branch_query = branch_query.filter(Branch.id.in_(accessible))

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

    # Branch managers can only see their branch; regional managers their group
    accessible = get_accessible_branch_ids(current_user)
    if current_user.role == UserRole.BRANCH_MANAGER:
        branch_id = current_user.branch_id
    elif accessible is not None and branch_id and branch_id not in accessible:
        return error_response('Access denied to this branch', 403)

    gym_id = get_current_gym_id(current_user)

    if (not branch_id and accessible is None
            and current_user.role not in [UserRole.OWNER, UserRole.SUPER_ADMIN, UserRole.CENTRAL_ACCOUNTANT]):
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
    elif accessible is not None:
        staff_query = staff_query.filter(User.branch_id.in_(accessible))

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

        # Share of this staff member's sales that were renewals rather than new
        # business. Null rather than 0 when they sold nothing in the window, so
        # "no sales" never renders as "0% renewals".
        renewals_count = sum(
            1 for t in transactions if t.transaction_type == TransactionType.RENEWAL
        )
        renewal_rate = (
            renewals_count / transactions_count * 100 if transactions_count else None
        )

        # Retention: of the customers this staff member signed up during the
        # window, how many still hold an active subscription now. Attribution is
        # via Subscription.created_by, so it credits whoever filed the signup.
        signed_customer_ids = {
            row[0]
            for row in db.session.query(Subscription.customer_id).filter(
                and_(
                    Subscription.created_by == staff.id,
                    Subscription.created_at >= datetime.combine(month_start.date(), datetime.min.time()),
                    Subscription.created_at <= datetime.combine(month_end.date(), datetime.max.time())
                )
            ).distinct()
        }
        if signed_customer_ids:
            retained_customer_ids = {
                row[0]
                for row in db.session.query(Subscription.customer_id).filter(
                    and_(
                        Subscription.customer_id.in_(signed_customer_ids),
                        Subscription.status == SubscriptionStatus.ACTIVE
                    )
                ).distinct()
            }
            retention_rate = len(retained_customer_ids) / len(signed_customer_ids) * 100
        else:
            retention_rate = None

        performance_data.append({
            'staff_id': staff.id,
            'staff_name': staff.username,
            'full_name': staff.full_name,
            'role': staff.role.value,
            'branch_name': staff.branch.name if staff.branch else 'N/A',
            'transactions_count': transactions_count,
            'total_revenue': total_revenue,
            'renewals_count': renewals_count,
            'renewal_rate': renewal_rate,
            'customers_signed': len(signed_customer_ids),
            'retention_rate': retention_rate
        })
    
    # Sort by revenue
    performance_data.sort(key=lambda x: x['total_revenue'], reverse=True)
    
    return success_response(performance_data)
