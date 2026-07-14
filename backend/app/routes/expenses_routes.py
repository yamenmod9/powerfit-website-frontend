"""
Expense management routes
"""
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from marshmallow import ValidationError
from app.schemas import ExpenseSchema, ExpenseReviewSchema
from app.models.expense import Expense, ExpenseStatus
from app.utils import (
    success_response, error_response, role_required,
    paginate, format_pagination_response, get_current_user
)
from app.models.user import UserRole
from app.extensions import db

expenses_bp = Blueprint('expenses', __name__, url_prefix='/api/expenses')


@expenses_bp.route('', methods=['GET'])
@jwt_required()
def get_expenses():
    """Get all expenses (paginated)"""
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    branch_id = request.args.get('branch_id', type=int)
    status = request.args.get('status', type=str)
    
    user = get_current_user()
    
    query = Expense.query
    
    # Branch filtering based on role
    if user.role not in [UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id:
            query = query.filter_by(branch_id=user.branch_id)
    elif branch_id:
        query = query.filter_by(branch_id=branch_id)
    
    # Status filter
    if status:
        try:
            query = query.filter_by(status=ExpenseStatus(status))
        except ValueError:
            return error_response("Invalid status", 400)
    
    query = query.order_by(Expense.created_at.desc())
    
    items, total, pages, current_page = paginate(query, page, per_page)
    
    schema = ExpenseSchema()
    return success_response(
        format_pagination_response(items, total, pages, current_page, schema)
    )


@expenses_bp.route('/<int:expense_id>', methods=['GET'])
@jwt_required()
def get_expense(expense_id):
    """Get expense by ID"""
    expense = db.session.get(Expense, expense_id)
    
    if not expense:
        return error_response("Expense not found", 404)
    
    # Check branch access
    user = get_current_user()
    if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id and expense.branch_id != user.branch_id:
            return error_response("Access denied", 403)
    
    return success_response(expense.to_dict())


@expenses_bp.route('', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.ACCOUNTANT, UserRole.BRANCH_ACCOUNTANT)
def create_expense():
    """Create new expense"""
    try:
        schema = ExpenseSchema()
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    user = get_current_user()
    
    # Validate branch access
    if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id and data['branch_id'] != user.branch_id:
            return error_response("Cannot create expense for another branch", 403)
    
    expense = Expense(
        title=data['title'],
        description=data.get('description'),
        amount=data['amount'],
        category=data.get('category'),
        branch_id=data['branch_id'],
        expense_date=data['expense_date'],
        created_by_id=user.id,
        status=ExpenseStatus.PENDING
    )
    
    db.session.add(expense)
    db.session.commit()
    
    return success_response(expense.to_dict(), "Expense created successfully", 201)


@expenses_bp.route('/<int:expense_id>/review', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT, UserRole.ACCOUNTANT)
def review_expense(expense_id):
    """Approve or reject expense"""
    expense = db.session.get(Expense, expense_id)
    
    if not expense:
        return error_response("Expense not found", 404)
    
    if expense.status != ExpenseStatus.PENDING:
        return error_response("Expense is not pending review", 400)
    
    try:
        schema = ExpenseReviewSchema()
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    user = get_current_user()
    
    if data['action'] == 'approve':
        expense.approve(user.id, data.get('notes'))
    else:
        if not data.get('notes'):
            return error_response("Notes are required for rejection", 400)
        expense.reject(user.id, data['notes'])
    
    db.session.commit()
    
    return success_response(expense.to_dict(), f"Expense {data['action']}d successfully")


@expenses_bp.route('/<int:expense_id>', methods=['DELETE'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.ACCOUNTANT)
def delete_expense(expense_id):
    """Delete expense (only if pending)"""
    expense = db.session.get(Expense, expense_id)
    
    if not expense:
        return error_response("Expense not found", 404)
    
    if expense.status != ExpenseStatus.PENDING:
        return error_response("Can only delete pending expenses", 400)
    
    # Check branch access
    user = get_current_user()
    if user.role not in [UserRole.OWNER]:
        if user.branch_id and expense.branch_id != user.branch_id:
            return error_response("Access denied", 403)
    
    db.session.delete(expense)
    db.session.commit()
    
    return success_response(message="Expense deleted successfully")
