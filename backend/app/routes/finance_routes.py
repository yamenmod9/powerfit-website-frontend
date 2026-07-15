"""
Finance routes - Financial management and reporting
Maps /api/finance/* for Flutter app compatibility
"""
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from app.models import Expense, DailyClosing, Transaction
from app.models.expense import ExpenseStatus
from app.utils import success_response, error_response, get_current_user, role_required, paginate, format_pagination_response
from app.models.user import UserRole
from app.extensions import db
from app.schemas import ExpenseSchema, DailyClosingSchema
from datetime import datetime
from sqlalchemy import and_, func

finance_bp = Blueprint('finance', __name__, url_prefix='/api/finance')


@finance_bp.route('/expenses', methods=['GET'])
@jwt_required()
def get_expenses():
    """
    Get expenses with filtering
    
    Query params:
        - branch_id: Filter by branch
        - status: pending, approved, rejected
        - date_from: Start date (YYYY-MM-DD)
        - date_to: End date (YYYY-MM-DD)
        - page: Page number
        - limit: Items per page
    """
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('limit', request.args.get('per_page', 20), type=int)
    branch_id = request.args.get('branch_id', type=int)
    status = request.args.get('status')
    date_from = request.args.get('date_from')
    date_to = request.args.get('date_to')
    
    current_user = get_current_user()
    
    # Build query
    query = Expense.query
    
    # Role-based filtering
    if current_user.role not in [UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT, UserRole.ACCOUNTANT]:
        query = query.filter(Expense.branch_id == current_user.branch_id)
    elif branch_id:
        query = query.filter(Expense.branch_id == branch_id)
    
    # Status filter
    if status:
        try:
            expense_status = ExpenseStatus(status)
            query = query.filter(Expense.status == expense_status)
        except ValueError:
            pass

    # Date range filter
    if date_from:
        try:
            start_date = datetime.strptime(date_from, '%Y-%m-%d')
            query = query.filter(Expense.created_at >= start_date)
        except ValueError:
            pass
    
    if date_to:
        try:
            end_date = datetime.strptime(date_to, '%Y-%m-%d')
            query = query.filter(Expense.created_at <= end_date)
        except ValueError:
            pass
    
    # Order by most recent
    query = query.order_by(Expense.created_at.desc())
    
    # Paginate
    items, total, pages, current_page = paginate(query, page, per_page)
    
    # Calculate totals
    pending_total = float(sum(float(e.amount) for e in items if e.status == ExpenseStatus.PENDING))
    approved_total = float(sum(float(e.amount) for e in items if e.status == ExpenseStatus.APPROVED))

    # Format response
    schema = ExpenseSchema()
    response_data = format_pagination_response(items, total, pages, current_page, schema)
    response_data['total_pending'] = pending_total
    response_data['total_approved'] = approved_total
    
    return success_response(response_data)


@finance_bp.route('/cash-differences', methods=['GET'])
@jwt_required()
@role_required([UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT, UserRole.BRANCH_ACCOUNTANT, UserRole.ACCOUNTANT])
def get_cash_differences():
    """
    Get cash difference records from daily closings
    
    Query params:
        - branch_id: Filter by branch
        - date_from: Start date (YYYY-MM-DD)
        - date_to: End date (YYYY-MM-DD)
    """
    branch_id = request.args.get('branch_id', type=int)
    date_from = request.args.get('date_from')
    date_to = request.args.get('date_to')
    
    current_user = get_current_user()
    
    # Build query for daily closings
    query = DailyClosing.query
    
    # Role-based filtering
    if current_user.role in [UserRole.BRANCH_ACCOUNTANT]:
        query = query.filter(DailyClosing.branch_id == current_user.branch_id)
    elif current_user.role in [UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT, UserRole.ACCOUNTANT]:
        if branch_id:
            query = query.filter(DailyClosing.branch_id == branch_id)
    else:
        query = query.filter(DailyClosing.branch_id == current_user.branch_id)
    
    # Date range filter
    if date_from:
        try:
            start_date = datetime.strptime(date_from, '%Y-%m-%d').date()
            query = query.filter(DailyClosing.closing_date >= start_date)
        except ValueError:
            pass
    
    if date_to:
        try:
            end_date = datetime.strptime(date_to, '%Y-%m-%d').date()
            query = query.filter(DailyClosing.closing_date <= end_date)
        except ValueError:
            pass
    
    # Order by most recent
    query = query.order_by(DailyClosing.closing_date.desc())
    
    closings = query.all()
    
    # Format as cash differences
    cash_differences = []
    total_difference = 0.0
    
    for closing in closings:
        cash_differences.append({
            'id': closing.id,
            'branch_id': closing.branch_id,
            'branch_name': closing.branch.name if closing.branch else 'N/A',
            'date': closing.closing_date.isoformat(),
            'expected_cash': float(closing.expected_cash) if closing.expected_cash else 0.0,
            'actual_cash': float(closing.actual_cash) if closing.actual_cash else 0.0,
            'difference': float(closing.cash_difference) if closing.cash_difference else 0.0,
            'notes': closing.notes,
            'recorded_by': closing.closed_by_user.username if closing.closed_by_user else 'N/A'
        })
        
        total_difference += float(closing.cash_difference) if closing.cash_difference else 0.0

    return success_response({
        'data': cash_differences,
        'total_difference': total_difference
    })


@finance_bp.route('/daily-sales', methods=['GET'])
@jwt_required()
def get_daily_sales():
    """
    Get daily sales summary
    
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
    if current_user.role not in [UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT, UserRole.ACCOUNTANT]:
        query = query.filter(Transaction.branch_id == current_user.branch_id)
    elif branch_id:
        query = query.filter(Transaction.branch_id == branch_id)
    
    transactions = query.all()
    
    # Calculate totals by payment method
    cash_total = 0.0
    network_total = 0.0
    transfer_total = 0.0

    for t in transactions:
        net_amount = float(t.amount) - float(t.discount or 0)
        if t.payment_method.value == 'cash':
            cash_total += net_amount
        elif t.payment_method.value == 'network':
            network_total += net_amount
        elif t.payment_method.value == 'transfer':
            transfer_total += net_amount

    total_sales = cash_total + network_total + transfer_total

    return success_response({
        'date': report_date.isoformat(),
        'total_sales': total_sales,
        'cash_sales': cash_total,
        'network_sales': network_total,
        'transfer_sales': transfer_total,
        'card_sales': network_total,
        'online_sales': transfer_total,
        'transaction_count': len(transactions)
    })
