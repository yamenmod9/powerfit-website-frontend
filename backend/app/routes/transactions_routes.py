"""
Transaction routes
"""
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from marshmallow import ValidationError
from app.schemas import TransactionSchema
from app.models.transaction import Transaction
from app.utils import (
    success_response, error_response, role_required,
    paginate, format_pagination_response, get_current_user
)
from app.models.user import UserRole
from app.extensions import db

transactions_bp = Blueprint('transactions', __name__, url_prefix='/api/transactions')


@transactions_bp.route('', methods=['GET'])
@jwt_required()
def get_transactions():
    """Get all transactions (paginated)"""
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    branch_id = request.args.get('branch_id', type=int)
    start_date = request.args.get('start_date', type=str)
    end_date = request.args.get('end_date', type=str)
    
    user = get_current_user()
    
    query = Transaction.query
    
    # Branch filtering based on role
    if user.role not in [UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id:
            query = query.filter_by(branch_id=user.branch_id)
    elif branch_id:
        query = query.filter_by(branch_id=branch_id)
    
    # Date filtering
    if start_date:
        query = query.filter(Transaction.transaction_date >= start_date)
    if end_date:
        query = query.filter(Transaction.transaction_date <= end_date)
    
    query = query.order_by(Transaction.transaction_date.desc())
    
    items, total, pages, current_page = paginate(query, page, per_page)
    
    schema = TransactionSchema()
    return success_response(
        format_pagination_response(items, total, pages, current_page, schema)
    )


@transactions_bp.route('/<int:transaction_id>', methods=['GET'])
@jwt_required()
def get_transaction(transaction_id):
    """Get transaction by ID"""
    transaction = db.session.get(Transaction, transaction_id)
    
    if not transaction:
        return error_response("Transaction not found", 404)
    
    # Check branch access
    user = get_current_user()
    if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id and transaction.branch_id != user.branch_id:
            return error_response("Access denied", 403)
    
    return success_response(transaction.to_dict())


@transactions_bp.route('', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK, UserRole.ACCOUNTANT, UserRole.BRANCH_ACCOUNTANT)
def create_transaction():
    """Create new transaction (for misc payments)"""
    try:
        schema = TransactionSchema()
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    user = get_current_user()
    
    # Validate branch access
    if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id and data['branch_id'] != user.branch_id:
            return error_response("Cannot create transaction for another branch", 403)
    
    transaction = Transaction(
        amount=data['amount'],
        payment_method=data['payment_method'],
        transaction_type=data['transaction_type'],
        branch_id=data['branch_id'],
        customer_id=data.get('customer_id'),
        subscription_id=data.get('subscription_id'),
        created_by=user.id,
        description=data.get('description'),
        notes=data.get('notes'),
        reference_number=data.get('reference_number')
    )
    
    db.session.add(transaction)
    db.session.commit()
    
    return success_response(transaction.to_dict(), "Transaction created successfully", 201)
