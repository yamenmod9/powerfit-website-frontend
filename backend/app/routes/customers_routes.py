"""
Customer management routes
"""
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from marshmallow import ValidationError
from sqlalchemy import or_
from datetime import datetime
from app.schemas import CustomerSchema
from app.models.customer import Customer, Gender
from app.models.subscription import Subscription
from app.utils import (
    success_response, error_response, role_required,
    paginate, format_pagination_response, get_current_user
)
from app.models.user import UserRole
from app.extensions import db

customers_bp = Blueprint('customers', __name__, url_prefix='/api/customers')


@customers_bp.route('', methods=['GET'])
@jwt_required()
def get_customers():
    """Get all customers (paginated)"""
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    branch_id = request.args.get('branch_id', type=int)
    search = request.args.get('search', type=str)
    
    user = get_current_user()
    
    query = Customer.query
    
    # Branch filtering based on role
    if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id:
            query = query.filter_by(branch_id=user.branch_id)
    elif branch_id:
        query = query.filter_by(branch_id=branch_id)
    
    # Search
    if search:
        query = query.filter(
            db.or_(
                Customer.full_name.ilike(f'%{search}%'),
                Customer.phone.ilike(f'%{search}%')
            )
        )
    
    query = query.order_by(Customer.created_at.desc())
    
    # Get paginated customers
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)
    
    # has_active_subscription is already computed inside customer.to_dict()
    # using the correct SubscriptionStatus.ACTIVE enum comparison.
    customers_data = []
    for customer in pagination.items:
        customer_dict = customer.to_dict(include_temp_password=True)
        customers_data.append(customer_dict)
    
    return success_response({
        'items': customers_data,
        'pagination': {
            'total': pagination.total,
            'pages': pagination.pages,
            'current_page': page,
            'per_page': per_page
        }
    })



@customers_bp.route('/<int:customer_id>', methods=['GET'])
@jwt_required()
def get_customer(customer_id):
    """Get customer by ID"""
    customer = db.session.get(Customer, customer_id)
    
    if not customer:
        return error_response("Customer not found", 404)
    
    # Check branch access
    user = get_current_user()
    if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id and customer.branch_id != user.branch_id:
            return error_response("Access denied", 403)
    
    return success_response(customer.to_dict(include_temp_password=True))


@customers_bp.route('/phone/<string:phone>', methods=['GET'])
@jwt_required()
def get_customer_by_phone(phone):
    """Get customer by phone number"""
    customer = Customer.query.filter_by(phone=phone).first()
    
    if not customer:
        return error_response("Customer not found", 404)
    
    # Check branch access
    user = get_current_user()
    if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id and customer.branch_id != user.branch_id:
            return error_response("Access denied", 403)
    
    return success_response(customer.to_dict(include_temp_password=True))


@customers_bp.route('', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK)
def create_customer():
    """Create new customer"""
    try:
        schema = CustomerSchema()
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    # Check if phone already exists
    if Customer.query.filter_by(phone=data['phone']).first():
        return error_response("Phone number already registered", 400)
    
    # Validate branch access
    user = get_current_user()
    if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id and data['branch_id'] != user.branch_id:
            return error_response("Cannot create customer for another branch", 403)
    
    customer = Customer(**data)
    
    # Calculate health metrics
    if customer.height and customer.weight:
        customer.calculate_health_metrics()
    
    db.session.add(customer)
    db.session.flush()  # Get the ID before commit
    
    # Generate QR code
    customer.qr_code = f"GYM-{customer.id}"
    
    db.session.commit()
    
    return success_response(customer.to_dict(), "Customer created successfully", 201)


@customers_bp.route('/register', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK)
def register_customer():
    """
    Register a new customer (Flutter-compatible endpoint)
    This is an alias for POST /api/customers with Flutter-specific response format
    """
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['full_name', 'phone', 'gender']
        for field in required_fields:
            if not data.get(field):
                return error_response(f"Missing required field: {field}", 400)
        
        # Check if phone already exists
        if Customer.query.filter_by(phone=data['phone']).first():
            return error_response("Phone number already registered", 400)
        
        # Get current user for branch assignment
        user = get_current_user()
        
        # ✅ FIX: Always use the staff member's branch_id
        # Receptionists can only register for their own branch
        # Owners/Central accountants can register for any branch (if provided)
        if user.role in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
            # Owner/accountant can specify branch_id or use their own
            branch_id = data.get('branch_id', user.branch_id)
        else:
            # Receptionist/Manager/Accountant - always use their branch
            branch_id = user.branch_id
        
        if not branch_id:
            return error_response("branch_id is required", 400)
        
        # Parse date_of_birth if provided (for age calculation)
        date_of_birth = None
        if data.get('age'):
            # Calculate approximate date_of_birth from age
            from datetime import date, timedelta
            age = int(data['age'])
            date_of_birth = date.today() - timedelta(days=age * 365)
        
        # Create customer
        customer = Customer(
            full_name=data['full_name'],
            phone=data['phone'],
            email=data.get('email'),
            gender=Gender(data['gender'].lower()),
            date_of_birth=date_of_birth,
            address=data.get('address'),
            height=data.get('height'),
            weight=data.get('weight'),
            branch_id=branch_id,
            health_notes=data.get('notes'),
            is_active=True
        )
        
        # Set pre-calculated values if provided (Flutter may send these)
        if data.get('bmi'):
            customer.bmi = data['bmi']
        if data.get('bmi_category'):
            customer.bmi_category = data['bmi_category']
        if data.get('bmr'):
            customer.bmr = data['bmr']
        if data.get('daily_calories'):
            customer.daily_calories = data['daily_calories']
        
        # Calculate health metrics if not provided
        if customer.height and customer.weight:
            customer.calculate_health_metrics()
        
        db.session.add(customer)
        db.session.flush()  # Get the ID before commit
        
        # Generate QR code in format GYM-{id}
        customer.qr_code = f"GYM-{customer.id}"
        
        # Generate temporary password for client app login
        temp_password = customer.generate_temp_password()
        
        db.session.commit()
        
        # Return Flutter-compatible response with credentials
        return success_response(
            {
                "id": customer.id,
                "full_name": customer.full_name,
                "phone": customer.phone,
                "email": customer.email,
                "gender": customer.gender.value if customer.gender else None,
                "age": customer.age,
                "weight": customer.weight,
                "height": customer.height,
                "bmi": customer.bmi,
                "bmi_category": customer.bmi_category,
                "bmr": customer.bmr,
                "daily_calories": customer.daily_calories,
                "qr_code": customer.qr_code,
                "branch_id": customer.branch_id,
                "is_active": customer.is_active,
                "created_at": customer.created_at.isoformat(),
                # Client App Credentials (Give these to the client)
                "client_credentials": {
                    "client_id": f"GYM-{customer.id}",
                    "phone": customer.phone,
                    "temporary_password": temp_password,
                    "note": "Give these credentials to the client for their mobile app login"
                }
            },
            "Customer registered successfully",
            201
        )
        
    except ValueError as e:
        db.session.rollback()
        return error_response(f"Invalid data: {str(e)}", 400)
    except Exception as e:
        db.session.rollback()
        return error_response(f"Registration failed: {str(e)}", 500)


@customers_bp.route('/<int:customer_id>', methods=['PUT'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER, UserRole.FRONT_DESK)
def update_customer(customer_id):
    """Update customer"""
    customer = db.session.get(Customer, customer_id)
    
    if not customer:
        return error_response("Customer not found", 404)
    
    # Check branch access
    user = get_current_user()
    if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id and customer.branch_id != user.branch_id:
            return error_response("Access denied", 403)
    
    try:
        schema = CustomerSchema(partial=True)
        data = schema.load(request.json)
    except ValidationError as e:
        return error_response("Validation error", 400, e.messages)
    
    # Update fields
    for field in ['full_name', 'email', 'national_id', 'date_of_birth', 'gender',
                  'address', 'height', 'weight', 'health_notes', 'is_active']:
        if field in data:
            setattr(customer, field, data[field])
    
    # Recalculate health metrics if height or weight changed
    if 'height' in data or 'weight' in data:
        customer.calculate_health_metrics()
    
    db.session.commit()
    
    return success_response(customer.to_dict(include_temp_password=True), "Customer updated successfully")


@customers_bp.route('/search', methods=['GET'])
@jwt_required()
def search_customers():
    """
    Search customers by name, phone, email, national_id, or qr_code
    
    Query params:
        - q: Search query string
        - branch_id: Filter by branch (optional)
        - limit: Max results (default: 50)
    """
    query_string = request.args.get('q', '').strip()
    branch_id = request.args.get('branch_id', type=int)
    limit = request.args.get('limit', 50, type=int)
    
    if not query_string:
        return error_response('Search query (q) is required', 400)
    
    current_user = get_current_user()
    
    # Build search query
    search_pattern = f'%{query_string}%'
    query = Customer.query.filter(
        db.or_(
            Customer.full_name.ilike(search_pattern),
            Customer.phone.ilike(search_pattern),
            Customer.email.ilike(search_pattern),
            Customer.national_id.ilike(search_pattern),
            Customer.qr_code.ilike(search_pattern)
        ),
        Customer.is_active == True
    )
    
    # Role-based filtering
    if current_user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        query = query.filter(Customer.branch_id == current_user.branch_id)
    elif branch_id:
        query = query.filter(Customer.branch_id == branch_id)
    
    # Limit results
    customers = query.limit(limit).all()
    
    return success_response({
        'items': [c.to_dict(include_temp_password=True) for c in customers],
        'total': len(customers),
        'query': query_string
    })


@customers_bp.route('/<int:customer_id>', methods=['DELETE'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.BRANCH_MANAGER)
def delete_customer(customer_id):
    """Deactivate customer (soft delete)"""
    customer = db.session.get(Customer, customer_id)
    
    if not customer:
        return error_response("Customer not found", 404)
    
    # Check branch access
    user = get_current_user()
    if user.role not in [UserRole.OWNER, UserRole.CENTRAL_ACCOUNTANT]:
        if user.branch_id and customer.branch_id != user.branch_id:
            return error_response("Access denied", 403)
    
    customer.is_active = False
    db.session.commit()
    
    return success_response(message="Customer deactivated successfully")
