"""
Dashboard and reporting routes
"""
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from datetime import datetime, date, timedelta
from app.services import DashboardService
from app.utils import (
    success_response, error_response, role_required, get_current_user,
    get_current_gym_id,
    calculate_branch_revenue, get_expiring_subscriptions
)
from app.models.user import UserRole
from app.models.complaint import ComplaintStatus
from app.models.expense import ExpenseStatus
from app.models.subscription import SubscriptionStatus
from app.extensions import db

dashboards_bp = Blueprint('dashboards', __name__, url_prefix='/api/dashboards')


@dashboards_bp.route('/overview', methods=['GET'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER)
def get_dashboard_overview():
    """Get overall gym system metrics (gym-scoped for owners)"""
    from app.models import Branch, Customer, Subscription, Transaction
    from app.models.expense import Expense, ExpenseStatus
    from sqlalchemy import func

    user = get_current_user()
    gym_id = get_current_gym_id(user)

    # Build branch filter
    branch_query = Branch.query.filter_by(is_active=True)
    if gym_id is not None:
        branch_query = branch_query.filter_by(gym_id=gym_id)
    branches = branch_query.all()
    branch_ids = [b.id for b in branches]

    if branch_ids:
        total_customers = Customer.query.filter(Customer.branch_id.in_(branch_ids)).count()
        active_subscriptions = Subscription.query.filter(
            Subscription.branch_id.in_(branch_ids),
            Subscription.status == SubscriptionStatus.ACTIVE,
        ).count()
        revenue_query = db.session.query(func.sum(Transaction.amount)).filter(
            Transaction.branch_id.in_(branch_ids)
        ).scalar()
        expenses_query = db.session.query(func.sum(Expense.amount)).filter(
            Expense.branch_id.in_(branch_ids),
            Expense.status == ExpenseStatus.APPROVED,
        ).scalar()
    else:
        total_customers = 0
        active_subscriptions = 0
        revenue_query = None
        expenses_query = None

    total_revenue = float(revenue_query) if revenue_query else 0.0
    total_expenses = float(expenses_query) if expenses_query else 0.0
    net_profit = total_revenue - total_expenses

    # Revenue by branch
    revenue_by_branch = []
    
    for branch in branches:
        branch_revenue = db.session.query(func.sum(Transaction.amount)).filter(
            Transaction.branch_id == branch.id
        ).scalar()
        
        branch_customers = Customer.query.filter_by(branch_id=branch.id).count()
        branch_active_subs = Subscription.query.filter_by(
            branch_id=branch.id,
            status=SubscriptionStatus.ACTIVE
        ).count()
        
        revenue_by_branch.append({
            'branch_id': branch.id,
            'branch_name': branch.name,
            'name': branch.name,
            'revenue': float(branch_revenue) if branch_revenue else 0.0,
            'customers': branch_customers,
            'customer_count': branch_customers,
            'active_subscriptions': branch_active_subs
        })
    
    return success_response({
        'total_revenue': total_revenue,
        'total_customers': total_customers,
        'active_subscriptions': active_subscriptions,
        'total_branches': len(branches),
        'total_expenses': total_expenses,
        'net_profit': net_profit,
        'revenue_by_branch': revenue_by_branch
    })


@dashboards_bp.route('/owner', methods=['GET'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER)
def get_owner_dashboard():
    """Get owner dashboard with smart alerts and analytics"""
    data = DashboardService.get_owner_dashboard()
    return success_response(data)


@dashboards_bp.route('/accountant', methods=['GET'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT, UserRole.ACCOUNTANT, UserRole.BRANCH_ACCOUNTANT)
def get_accountant_dashboard():
    """Get accountant dashboard"""
    user = get_current_user()
    
    # Branch accountants can only see their branch
    branch_id = None
    if user.role in [UserRole.ACCOUNTANT, UserRole.BRANCH_ACCOUNTANT]:
        branch_id = user.branch_id
    else:
        branch_id = request.args.get('branch_id', type=int)
    
    data = DashboardService.get_accountant_dashboard(branch_id)
    return success_response(data)


@dashboards_bp.route('/branch/<int:branch_id>', methods=['GET'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER)
def get_branch_dashboard(branch_id):
    """Get branch-specific metrics"""
    from app.models import Branch, Customer, Subscription, Transaction, User, Complaint, Expense
    from sqlalchemy import func
    
    user = get_current_user()
    
    # Branch managers can only see their own branch (not super_admin or owner)
    if user.role == UserRole.BRANCH_MANAGER and user.branch_id != branch_id:
        return error_response("Access denied to this branch", 403)
    
    branch = db.session.get(Branch, branch_id)
    if not branch:
        return error_response("Branch not found", 404)
    
    # Branch metrics
    total_customers = Customer.query.filter_by(branch_id=branch_id).count()
    active_subscriptions = Subscription.query.filter_by(
        branch_id=branch_id,
        status=SubscriptionStatus.ACTIVE
    ).count()
    
    branch_revenue = db.session.query(func.sum(Transaction.amount)).filter(
        Transaction.branch_id == branch_id
    ).scalar()
    total_revenue = float(branch_revenue) if branch_revenue else 0.0
    
    staff_count = User.query.filter_by(branch_id=branch_id, is_active=True).count()
    open_complaints = Complaint.query.filter_by(
        branch_id=branch_id,
        status=ComplaintStatus.OPEN
    ).count()
    pending_expenses = Expense.query.filter_by(
        branch_id=branch_id,
        status=ExpenseStatus.PENDING
    ).count()
    
    return success_response({
        'branch': {
            'id': branch.id,
            'name': branch.name,
            'location': f"{branch.city}, {branch.address}" if branch.city else branch.address
        },
        'total_customers': total_customers,
        'active_subscriptions': active_subscriptions,
        'total_revenue': total_revenue,
        'staff_count': staff_count,
        'open_complaints': open_complaints,
        'pending_expenses': pending_expenses
    })


@dashboards_bp.route('/branch-manager', methods=['GET'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER)
def get_branch_manager_dashboard():
    """Get branch manager dashboard"""
    user = get_current_user()
    
    # Branch managers can only see their branch
    if user.role == UserRole.BRANCH_MANAGER:
        branch_id = user.branch_id
        if not branch_id:
            return error_response("User not assigned to a branch", 403)
    else:
        branch_id = request.args.get('branch_id', type=int)
        if not branch_id and user.role not in [UserRole.SUPER_ADMIN, UserRole.OWNER]:
            return error_response("branch_id is required", 400)
    
    data = DashboardService.get_branch_manager_dashboard(branch_id)
    return success_response(data)


@dashboards_bp.route('/reports/revenue', methods=['GET'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT, UserRole.ACCOUNTANT, UserRole.BRANCH_ACCOUNTANT)
def get_revenue_report():
    """Get revenue report"""
    start_date = request.args.get('start_date', type=str)
    end_date = request.args.get('end_date', type=str)
    branch_id = request.args.get('branch_id', type=int)
    group_by = request.args.get('group_by', 'day', type=str)
    
    if not start_date or not end_date:
        return error_response("start_date and end_date are required", 400)
    
    try:
        start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
        end_date = datetime.strptime(end_date, '%Y-%m-%d').date()
    except ValueError:
        return error_response("Invalid date format. Use YYYY-MM-DD", 400)
    
    user = get_current_user()
    
    # Branch-specific roles can only see their branch
    if user.role in [UserRole.ACCOUNTANT, UserRole.BRANCH_ACCOUNTANT]:
        branch_id = user.branch_id
    
    data = DashboardService.get_revenue_report(start_date, end_date, branch_id, group_by)
    return success_response(data)


@dashboards_bp.route('/alerts/expiring-subscriptions', methods=['GET'])
@jwt_required()
def get_expiring_subscriptions_alert():
    """Get expiring subscriptions alert"""
    days = request.args.get('days', 7, type=int)
    branch_id = request.args.get('branch_id', type=int)
    
    user = get_current_user()
    
    # Branch-specific roles can only see their branch
    if user.role not in [UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        branch_id = user.branch_id
    
    subscriptions = get_expiring_subscriptions(days, branch_id)
    
    from app.schemas import SubscriptionSchema
    schema = SubscriptionSchema()
    
    return success_response({
        'count': len(subscriptions),
        'subscriptions': schema.dump(subscriptions, many=True)
    })


@dashboards_bp.route('/staff-performance', methods=['GET'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER)
def get_staff_performance():
    """Get staff performance metrics"""
    start_date = request.args.get('start_date', type=str)
    end_date = request.args.get('end_date', type=str)
    branch_id = request.args.get('branch_id', type=int)
    
    if not start_date or not end_date:
        # Default to last 30 days
        end_date_obj = date.today()
        start_date_obj = end_date_obj - timedelta(days=30)
    else:
        try:
            start_date_obj = datetime.strptime(start_date, '%Y-%m-%d').date()
            end_date_obj = datetime.strptime(end_date, '%Y-%m-%d').date()
        except ValueError:
            return error_response('Invalid date format. Use YYYY-MM-DD', 400)
    
    user = get_current_user()
    
    # Branch managers can only see their branch
    if user.role == UserRole.BRANCH_MANAGER:
        branch_id = user.branch_id
    
    from app.models import User, Transaction, Subscription
    from sqlalchemy import func
    
    # Staff revenue generation
    query = db.session.query(
        User.id,
        User.full_name,
        User.role,
        func.count(Transaction.id).label('transaction_count'),
        func.sum(Transaction.amount).label('total_revenue')
    ).join(Transaction, Transaction.created_by == User.id).filter(
        Transaction.transaction_date >= start_date_obj,
        Transaction.transaction_date <= end_date_obj
    )
    
    if branch_id:
        query = query.filter(User.branch_id == branch_id)
    
    staff_data = query.group_by(User.id, User.full_name, User.role).order_by(
        func.sum(Transaction.amount).desc()
    ).all()
    
    # Customer retention (subscriptions created)
    retention_query = db.session.query(
        User.id,
        func.count(Subscription.id).label('subscriptions_created')
    ).join(Subscription, Subscription.created_by == User.id).filter(
        Subscription.start_date >= start_date_obj,
        Subscription.start_date <= end_date_obj
    )
    
    if branch_id:
        retention_query = retention_query.filter(User.branch_id == branch_id)
    
    retention_data = {r[0]: r[1] for r in retention_query.group_by(User.id).all()}
    
    # Combine data
    performance = []
    for staff in staff_data:
        performance.append({
            'user_id': staff[0],
            'full_name': staff[1],
            'role': staff[2].value,
            'transaction_count': staff[3],
            'total_revenue': float(staff[4] or 0),
            'subscriptions_created': retention_data.get(staff[0], 0)
        })
    
    return success_response({
        'start_date': start_date_obj.isoformat(),
        'end_date': end_date_obj.isoformat(),
        'branch_id': branch_id,
        'staff': performance
    })


@dashboards_bp.route('/alerts', methods=['GET'])
@jwt_required()
def get_all_alerts():
    """Get all smart alerts for the user"""
    user = get_current_user()
    branch_id = user.branch_id if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT] else None
    
    from app.models import Complaint, Expense, Subscription
    
    # Expiring subscriptions (within 48 hours)
    expiring_soon = get_expiring_subscriptions(days=2, branch_id=branch_id)
    
    # Expiring within week
    expiring_week = get_expiring_subscriptions(days=7, branch_id=branch_id)
    
    # Open complaints
    complaints_query = Complaint.query.filter_by(status=ComplaintStatus.OPEN)
    if branch_id:
        complaints_query = complaints_query.filter_by(branch_id=branch_id)
    open_complaints = complaints_query.count()
    
    # Pending expenses
    expenses_query = Expense.query.filter_by(status=ExpenseStatus.PENDING)
    if branch_id:
        expenses_query = expenses_query.filter_by(branch_id=branch_id)
    pending_expenses = expenses_query.count()
    
    # Blocked members (stopped subscriptions)
    blocked_query = Subscription.query.filter_by(status=SubscriptionStatus.STOPPED)
    if branch_id:
        blocked_query = blocked_query.filter_by(branch_id=branch_id)
    blocked_members = blocked_query.count()
    
    return success_response({
        'alerts': {
            'expiring_48h': {
                'count': len(expiring_soon),
                'priority': 'high',
                'message': f'{len(expiring_soon)} subscription(s) expiring in 48 hours'
            },
            'expiring_7d': {
                'count': len(expiring_week),
                'priority': 'medium',
                'message': f'{len(expiring_week)} subscription(s) expiring in 7 days'
            },
            'open_complaints': {
                'count': open_complaints,
                'priority': 'high' if open_complaints > 5 else 'medium',
                'message': f'{open_complaints} open complaint(s)'
            },
            'pending_expenses': {
                'count': pending_expenses,
                'priority': 'medium',
                'message': f'{pending_expenses} pending expense(s) need approval'
            },
            'blocked_members': {
                'count': blocked_members,
                'priority': 'low',
                'message': f'{blocked_members} blocked member(s)'
            }
        },
        'branch_id': branch_id,
        'timestamp': datetime.utcnow().isoformat()
    })
