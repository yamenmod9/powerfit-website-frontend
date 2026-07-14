"""
Payments routes - Alias for transactions routes
Maps /api/payments/* to transaction functionality for Flutter app compatibility
"""
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from app.models import Transaction, DailyClosing, Branch
from app.models.transaction import PaymentMethod
from app.utils import success_response, error_response, get_current_user, role_required, paginate, format_pagination_response
from app.models.user import UserRole
from app.extensions import db
from app.schemas import TransactionSchema, DailyClosingSchema
from datetime import datetime, date
from sqlalchemy import func

payments_bp = Blueprint('payments', __name__, url_prefix='/api/payments')


@payments_bp.route('', methods=['GET'])
@jwt_required()
def get_payments():
    """
    Get all payments/transactions with filtering
    
    Query params:
        - branch_id: Filter by branch
        - payment_method: cash, card, online
        - date_from: Start date (YYYY-MM-DD)
        - date_to: End date (YYYY-MM-DD)
        - page: Page number
        - limit: Items per page
    """
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('limit', request.args.get('per_page', 20), type=int)
    branch_id = request.args.get('branch_id', type=int)
    payment_method = request.args.get('payment_method')
    date_from = request.args.get('date_from')
    date_to = request.args.get('date_to')
    
    current_user = get_current_user()
    
    # Build query
    query = Transaction.query
    
    # Role-based filtering
    if current_user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if current_user.branch_id:
            query = query.filter(Transaction.branch_id == current_user.branch_id)
    elif branch_id:
        query = query.filter(Transaction.branch_id == branch_id)
    
    # Payment method filter
    if payment_method:
        try:
            method_enum = PaymentMethod(payment_method.lower())
            query = query.filter(Transaction.payment_method == method_enum)
        except ValueError:
            pass
    
    # Date range filter
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
    
    # Order by most recent
    query = query.order_by(Transaction.created_at.desc())
    
    # Paginate
    items, total, pages, current_page = paginate(query, page, per_page)
    
    # Calculate total amount
    total_amount = sum(t.amount for t in items)
    
    # Format response
    schema = TransactionSchema()
    response_data = format_pagination_response(items, total, pages, current_page, schema)
    response_data['total_amount'] = total_amount
    
    return success_response(response_data)


@payments_bp.route('/<int:payment_id>', methods=['GET'])
@jwt_required()
def get_payment(payment_id):
    """Get payment by ID"""
    transaction = db.session.get(Transaction, payment_id)
    
    if not transaction:
        return error_response("Payment not found", 404)
    
    # Check access
    current_user = get_current_user()
    if current_user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if current_user.branch_id and transaction.branch_id != current_user.branch_id:
            return error_response("Access denied", 403)
    
    schema = TransactionSchema()
    return success_response(schema.dump(transaction))


@payments_bp.route('/record', methods=['POST'])
@jwt_required()
@role_required([UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK])
def record_payment():
    """
    Record a new payment/transaction
    
    Request body:
        - subscription_id: Subscription ID
        - amount: Payment amount
        - discount: Discount amount (optional)
        - payment_method: cash, card, online
        - notes: Optional notes
    """
    data = request.get_json()
    
    if not data:
        return error_response('Request body is required', 400)
    
    required_fields = ['subscription_id', 'amount', 'payment_method']
    for field in required_fields:
        if field not in data:
            return error_response(f'{field} is required', 400)
    
    # Get subscription to determine branch
    from app.models import Subscription
    subscription = db.session.get(Subscription, data['subscription_id'])
    
    if not subscription:
        return error_response('Subscription not found', 404)
    
    # Verify branch access
    current_user = get_current_user()
    if current_user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if current_user.branch_id and subscription.branch_id != current_user.branch_id:
            return error_response('Access denied', 403)
    
    # Create transaction
    try:
        payment_method_enum = PaymentMethod(data['payment_method'].lower())
    except ValueError:
        return error_response('Invalid payment method. Use: cash, card, or online', 400)
    
    transaction = Transaction(
        subscription_id=subscription.id,
        customer_id=subscription.customer_id,
        branch_id=subscription.branch_id,
        amount=float(data['amount']),
        discount=float(data.get('discount', 0)),
        payment_method=payment_method_enum,
        notes=data.get('notes'),
        created_by=current_user.id
    )
    
    db.session.add(transaction)
    db.session.commit()
    
    schema = TransactionSchema()
    return success_response(schema.dump(transaction), 'Payment recorded successfully', 201)


@payments_bp.route('/daily-closing', methods=['POST'])
@jwt_required()
@role_required([UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK])
def daily_closing():
    """
    Create daily closing record
    
    Request body:
        - branch_id: Branch ID
        - date: Closing date (YYYY-MM-DD)
        - expected_cash: Expected cash amount
        - actual_cash: Actual cash amount
        - cash_difference: Difference (actual - expected)
        - notes: Optional notes
    """
    data = request.get_json()
    
    if not data:
        return error_response('Request body is required', 400)
    
    required_fields = ['branch_id', 'date', 'expected_cash', 'actual_cash']
    for field in required_fields:
        if field not in data:
            return error_response(f'{field} is required', 400)
    
    branch_id = data['branch_id']
    closing_date = data['date']
    
    # Verify branch access
    current_user = get_current_user()
    if current_user.role not in [UserRole.OWNER]:
        if current_user.branch_id and branch_id != current_user.branch_id:
            return error_response('Access denied', 403)
    
    # Check if already closed for this date
    try:
        date_obj = datetime.strptime(closing_date, '%Y-%m-%d').date()
    except ValueError:
        return error_response('Invalid date format. Use YYYY-MM-DD', 400)
    
    existing = DailyClosing.query.filter_by(
        branch_id=branch_id,
        closing_date=date_obj
    ).first()
    
    if existing:
        return error_response('Daily closing already exists for this date', 409)
    
    # Create daily closing
    expected_cash = float(data['expected_cash'])
    actual_cash = float(data['actual_cash'])
    cash_difference = data.get('cash_difference', actual_cash - expected_cash)
    
    closing = DailyClosing(
        branch_id=branch_id,
        closing_date=date_obj,
        expected_cash=expected_cash,
        actual_cash=actual_cash,
        cash_difference=float(cash_difference),
        notes=data.get('notes'),
        closed_by=current_user.id
    )
    
    db.session.add(closing)
    db.session.commit()
    
    schema = DailyClosingSchema()
    return success_response(schema.dump(closing), 'Daily closing recorded successfully', 201)
