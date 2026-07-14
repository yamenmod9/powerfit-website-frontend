"""
Branch management routes (gym-scoped)
"""
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from marshmallow import ValidationError
from app.schemas import BranchSchema
from app.models.branch import Branch
from app.utils import (
    success_response, error_response, role_required,
    paginate, format_pagination_response, get_current_user,
    get_current_gym_id
)
from app.models.user import UserRole
from app.models.complaint import ComplaintStatus
from app.extensions import db

branches_bp = Blueprint('branches', __name__, url_prefix='/api/branches')


@branches_bp.route('', methods=['GET'])
@jwt_required()
def get_branches():
    """Get branches for the current user's gym."""
    user = get_current_user()
    gym_id = get_current_gym_id(user)

    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    is_active = request.args.get('is_active', type=bool)
    
    query = Branch.query

    # Scope to the user's gym (super admin sees all)
    if gym_id is not None:
        query = query.filter_by(gym_id=gym_id)
    
    if is_active is not None:
        query = query.filter_by(is_active=is_active)
    
    query = query.order_by(Branch.name)
    
    items, total, pages, current_page = paginate(query, page, per_page)
    
    # Enhanced: Add more details for each branch
    branch_list = []
    from app.models.user import UserRole, User
    from app.models.subscription import SubscriptionStatus
    from app.models.transaction import Transaction
    from sqlalchemy import func, and_
    from datetime import datetime, timedelta
    
    # Revenue period: last 90 days
    revenue_start = datetime.utcnow() - timedelta(days=90)
    
    for branch in items:
        # Find branch manager
        manager = User.query.filter_by(branch_id=branch.id, role=UserRole.BRANCH_MANAGER).first()
        manager_name = manager.full_name if manager else None
        # Count of active subscriptions
        active_subs = branch.subscriptions.filter_by(status=SubscriptionStatus.ACTIVE).count()
        # Revenue from transactions in last 90 days
        revenue_result = db.session.query(
            func.coalesce(func.sum(Transaction.amount - func.coalesce(Transaction.discount, 0)), 0)
        ).filter(
            and_(
                Transaction.branch_id == branch.id,
                Transaction.created_at >= revenue_start
            )
        ).scalar()
        revenue = float(revenue_result or 0)
        
        branch_dict = branch.to_dict()
        branch_dict.update({
            'manager': manager_name,
            'active_subscriptions': active_subs,
            'revenue': revenue,
        })
        branch_list.append(branch_dict)
    return success_response({
        'items': branch_list,
        'total': total,
        'pages': pages,
        'current_page': current_page
    })


@branches_bp.route('/<int:branch_id>', methods=['GET'])
@jwt_required()
def get_branch(branch_id):
    """Get branch by ID"""
    branch = db.session.get(Branch, branch_id)
    
    if not branch:
        return error_response("Branch not found", 404)
    
    return success_response(branch.to_dict())


@branches_bp.route('', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER)
def create_branch():
    """Create new branch (scoped to the owner's gym)"""
    user = get_current_user()
    gym_id = get_current_gym_id(user)

    try:
        schema = BranchSchema()
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    # Check uniqueness within the gym
    existing_code = Branch.query.filter_by(gym_id=gym_id, code=data['code']).first()
    if existing_code:
        return error_response("Branch code already exists in this gym", 400)
    
    existing_name = Branch.query.filter_by(gym_id=gym_id, name=data['name']).first()
    if existing_name:
        return error_response("Branch name already exists in this gym", 400)
    
    branch = Branch(gym_id=gym_id, **data)
    db.session.add(branch)
    db.session.commit()
    
    return success_response(branch.to_dict(), "Branch created successfully", 201)


@branches_bp.route('/<int:branch_id>', methods=['PUT'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER)
def update_branch(branch_id):
    """Update branch"""
    branch = db.session.get(Branch, branch_id)
    
    if not branch:
        return error_response("Branch not found", 404)
    
    try:
        schema = BranchSchema(partial=True)
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    # Update fields
    for field in ['name', 'address', 'phone', 'city', 'is_active']:
        if field in data:
            setattr(branch, field, data[field])
    
    db.session.commit()
    
    return success_response(branch.to_dict(), "Branch updated successfully")


@branches_bp.route('/<int:branch_id>', methods=['DELETE'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER)
def delete_branch(branch_id):
    """Deactivate branch (soft delete)"""
    branch = db.session.get(Branch, branch_id)
    
    if not branch:
        return error_response("Branch not found", 404)
    
    branch.is_active = False
    db.session.commit()
    
    return success_response(message="Branch deactivated successfully")


@branches_bp.route('/<int:branch_id>/performance', methods=['GET'])
@jwt_required()
def get_branch_performance(branch_id):
    """
    Get branch performance metrics
    
    Query params:
        - month: Month for analysis (YYYY-MM, default: current month)
    """
    from app.models import Customer, Subscription, Transaction, Complaint
    from app.models.subscription import SubscriptionStatus
    from datetime import datetime, timedelta
    from sqlalchemy import and_, func
    
    branch = db.session.get(Branch, branch_id)
    
    if not branch:
        return error_response("Branch not found", 404)
    
    # Check access
    current_user = get_current_user()
    if current_user.role not in [UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if current_user.branch_id and branch_id != current_user.branch_id:
            return error_response("Access denied", 403)
    
    month_str = request.args.get('month')
    
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
    
    # Total customers
    total_customers = Customer.query.filter_by(
        branch_id=branch_id,
        is_active=True
    ).count()
    
    # New customers this month
    new_customers = Customer.query.filter(
        and_(
            Customer.branch_id == branch_id,
            Customer.created_at >= datetime.combine(month_start.date(), datetime.min.time()),
            Customer.created_at <= datetime.combine(month_end.date(), datetime.max.time())
        )
    ).count()
    
    # Active subscriptions
    active_subscriptions = Subscription.query.filter_by(
        branch_id=branch_id,
        status=SubscriptionStatus.ACTIVE
    ).count()
    
    # Expired subscriptions this month
    expired_subscriptions = Subscription.query.filter(
        and_(
            Subscription.branch_id == branch_id,
            Subscription.status == SubscriptionStatus.EXPIRED,
            Subscription.end_date >= month_start.date(),
            Subscription.end_date <= month_end.date()
        )
    ).count()
    
    # Frozen subscriptions
    frozen_subscriptions = Subscription.query.filter_by(
        branch_id=branch_id,
        status=SubscriptionStatus.FROZEN
    ).count()
    
    # Revenue
    transactions = Transaction.query.filter(
        and_(
            Transaction.branch_id == branch_id,
            Transaction.created_at >= datetime.combine(month_start.date(), datetime.min.time()),
            Transaction.created_at <= datetime.combine(month_end.date(), datetime.max.time())
        )
    ).all()
    
    total_revenue = float(sum(float(t.amount) - float(t.discount or 0) for t in transactions))

    # Revenue by service
    from collections import defaultdict
    revenue_by_service = defaultdict(float)
    for t in transactions:
        if t.subscription and t.subscription.service:
            service_name = t.subscription.service.name
            revenue_by_service[service_name] += float(t.amount) - float(t.discount or 0)

    # Average subscription value
    avg_subscription_value = total_revenue / len(transactions) if transactions else 0.0

    # Check-ins count (entry logs)
    from app.models import EntryLog
    check_ins_count = EntryLog.query.filter(
        and_(
            EntryLog.branch_id == branch_id,
            EntryLog.entry_time >= datetime.combine(month_start.date(), datetime.min.time()),
            EntryLog.entry_time <= datetime.combine(month_end.date(), datetime.max.time())
        )
    ).count()
    
    # Complaints
    complaints_count = Complaint.query.filter_by(branch_id=branch_id).count()
    open_complaints = Complaint.query.filter_by(branch_id=branch_id, status=ComplaintStatus.OPEN).count()

    # Staff performance
    from app.models import User
    staff = User.query.filter_by(branch_id=branch_id).all()
    
    staff_performance = []
    for staff_member in staff:
        staff_transactions = Transaction.query.filter(
            and_(
                Transaction.created_by == staff_member.id,
                Transaction.created_at >= datetime.combine(month_start.date(), datetime.min.time()),
                Transaction.created_at <= datetime.combine(month_end.date(), datetime.max.time())
            )
        ).all()
        
        staff_revenue = float(sum(float(t.amount) - float(t.discount or 0) for t in staff_transactions)) if staff_transactions else 0.0
        staff_performance.append({
            'staff_id': staff_member.id,
            'staff_name': staff_member.username,
            'full_name': staff_member.full_name,
            'role': staff_member.role.value,
            'is_active': staff_member.is_active,
            'transactions_count': len(staff_transactions),
            'total_revenue': staff_revenue
        })

    # Capacity: active subscriptions as proxy, could be overridden per branch
    capacity = active_subscriptions

    return success_response({
        'branch_id': branch_id,
        'branch_name': branch.name,
        'month': month_start.strftime('%Y-%m'),
        'total_customers': total_customers,
        'new_customers': new_customers,
        'active_subscriptions': active_subscriptions,
        'expired_subscriptions': expired_subscriptions,
        'frozen_subscriptions': frozen_subscriptions,
        'total_revenue': total_revenue,
        'capacity': capacity,
        'revenue_by_service': dict(revenue_by_service),
        'average_subscription_value': avg_subscription_value,
        'check_ins_count': check_ins_count,
        'complaints_count': complaints_count,
        'open_complaints': open_complaints,
        'staff_performance': staff_performance
    })
