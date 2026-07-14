"""
Daily Closing routes - End of shift cash reconciliation
"""
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from datetime import datetime, date
from sqlalchemy import func, and_
from app.models.daily_closing import DailyClosing
from app.models.transaction import Transaction, PaymentMethod
from app.utils import (
    success_response, error_response, role_required,
    paginate, format_pagination_response, get_current_user
)
from app.models.user import UserRole
from app.extensions import db

daily_closing_bp = Blueprint('daily_closing', __name__, url_prefix='/api/daily-closings')


@daily_closing_bp.route('', methods=['GET'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT, UserRole.BRANCH_ACCOUNTANT, UserRole.BRANCH_MANAGER)
def get_daily_closings():
    """Get all daily closings (paginated)"""
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    branch_id = request.args.get('branch_id', type=int)
    start_date = request.args.get('start_date', type=str)
    end_date = request.args.get('end_date', type=str)
    
    user = get_current_user()
    
    query = DailyClosing.query
    
    # Branch filtering based on role
    if user.role in [UserRole.BRANCH_ACCOUNTANT, UserRole.BRANCH_MANAGER]:
        if user.branch_id:
            query = query.filter_by(branch_id=user.branch_id)
    elif branch_id:
        query = query.filter_by(branch_id=branch_id)
    
    # Date filtering
    if start_date:
        query = query.filter(DailyClosing.closing_date >= start_date)
    if end_date:
        query = query.filter(DailyClosing.closing_date <= end_date)
    
    query = query.order_by(DailyClosing.closing_date.desc())
    
    items, total, pages, current_page = paginate(query, page, per_page)
    
    return success_response({
        'items': [item.to_dict() for item in items],
        'pagination': {
            'total': total,
            'pages': pages,
            'current_page': current_page,
            'per_page': per_page
        }
    })


@daily_closing_bp.route('/<int:closing_id>', methods=['GET'])
@jwt_required()
def get_daily_closing(closing_id):
    """Get daily closing by ID"""
    closing = db.session.get(DailyClosing, closing_id)
    
    if not closing:
        return error_response("Daily closing not found", 404)
    
    # Check branch access
    user = get_current_user()
    if user.role in [UserRole.BRANCH_ACCOUNTANT, UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK]:
        if user.branch_id and closing.branch_id != user.branch_id:
            return error_response("Access denied", 403)
    
    return success_response(closing.to_dict())


@daily_closing_bp.route('/calculate', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK)
def calculate_expected_cash():
    """Calculate expected cash for a given date and branch"""
    data = request.json
    
    if not data or 'branch_id' not in data:
        return error_response("branch_id is required", 400)
    
    branch_id = data['branch_id']
    closing_date_str = data.get('date', date.today().isoformat())
    
    try:
        closing_date = datetime.strptime(closing_date_str, '%Y-%m-%d').date()
    except ValueError:
        return error_response("Invalid date format. Use YYYY-MM-DD", 400)
    
    user = get_current_user()
    
    # Check branch access
    if user.role in [UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK]:
        if user.branch_id != branch_id:
            return error_response("Access denied to this branch", 403)
    
    # Calculate totals from transactions
    transactions = Transaction.query.filter(
        and_(
            Transaction.branch_id == branch_id,
            func.date(Transaction.transaction_date) == closing_date
        )
    ).all()
    
    cash_total = 0
    network_total = 0
    transfer_total = 0
    
    for txn in transactions:
        amount = float(txn.amount)
        if txn.payment_method == PaymentMethod.CASH:
            cash_total += amount
        elif txn.payment_method == PaymentMethod.NETWORK:
            network_total += amount
        elif txn.payment_method == PaymentMethod.TRANSFER:
            transfer_total += amount
    
    total_revenue = cash_total + network_total + transfer_total
    
    return success_response({
        'branch_id': branch_id,
        'closing_date': closing_date.isoformat(),
        'expected_cash': cash_total,
        'network_total': network_total,
        'transfer_total': transfer_total,
        'total_revenue': total_revenue,
        'transaction_count': len(transactions)
    })


@daily_closing_bp.route('', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK)
def create_daily_closing():
    """Create daily closing (end of shift)"""
    data = request.json
    
    if not data:
        return error_response("Request body is required", 400)
    
    required_fields = ['branch_id', 'actual_cash']
    for field in required_fields:
        if field not in data:
            return error_response(f"{field} is required", 400)
    
    branch_id = data['branch_id']
    actual_cash = data['actual_cash']
    closing_date_str = data.get('date', date.today().isoformat())
    notes = data.get('notes', '')
    
    try:
        closing_date = datetime.strptime(closing_date_str, '%Y-%m-%d').date()
    except ValueError:
        return error_response("Invalid date format. Use YYYY-MM-DD", 400)
    
    user = get_current_user()
    
    # Check branch access
    if user.role in [UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK]:
        if user.branch_id != branch_id:
            return error_response("Access denied to this branch", 403)
    
    # Check if closing already exists for this date and branch
    existing = DailyClosing.query.filter(
        and_(
            DailyClosing.branch_id == branch_id,
            DailyClosing.closing_date == closing_date
        )
    ).first()
    
    if existing:
        return error_response("Daily closing already exists for this date", 400)
    
    # Calculate expected values
    transactions = Transaction.query.filter(
        and_(
            Transaction.branch_id == branch_id,
            func.date(Transaction.transaction_date) == closing_date
        )
    ).all()
    
    expected_cash = 0
    network_total = 0
    transfer_total = 0
    
    for txn in transactions:
        amount = float(txn.amount)
        if txn.payment_method == PaymentMethod.CASH:
            expected_cash += amount
        elif txn.payment_method == PaymentMethod.NETWORK:
            network_total += amount
        elif txn.payment_method == PaymentMethod.TRANSFER:
            transfer_total += amount
    
    total_revenue = expected_cash + network_total + transfer_total
    cash_difference = float(actual_cash) - expected_cash
    
    # Create closing
    closing = DailyClosing(
        branch_id=branch_id,
        closing_date=closing_date,
        expected_cash=expected_cash,
        actual_cash=actual_cash,
        cash_difference=cash_difference,
        network_total=network_total,
        transfer_total=transfer_total,
        total_revenue=total_revenue,
        closed_by=user.id,
        notes=notes
    )
    
    db.session.add(closing)
    db.session.commit()
    
    return success_response(
        closing.to_dict(),
        "Daily closing created successfully",
        201
    )


@daily_closing_bp.route('/today', methods=['GET'])
@jwt_required()
def get_today_status():
    """Check if today's closing has been done for user's branch"""
    user = get_current_user()
    
    if not user.branch_id:
        return error_response("User not assigned to a branch", 403)
    
    today = date.today()
    
    # Check if closing exists for today
    closing = DailyClosing.query.filter(
        and_(
            DailyClosing.branch_id == user.branch_id,
            DailyClosing.closing_date == today
        )
    ).first()
    
    # Get today's transactions
    transactions = Transaction.query.filter(
        and_(
            Transaction.branch_id == user.branch_id,
            func.date(Transaction.transaction_date) == today
        )
    ).all()
    
    cash_total = sum(float(t.amount) for t in transactions if t.payment_method == PaymentMethod.CASH)
    
    return success_response({
        'branch_id': user.branch_id,
        'date': today.isoformat(),
        'is_closed': closing is not None,
        'closing': closing.to_dict() if closing else None,
        'expected_cash': cash_total,
        'transaction_count': len(transactions)
    })
