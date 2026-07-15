"""
Marshmallow schemas for serialization/deserialization
"""
from marshmallow import Schema, fields, validate, validates, ValidationError
from app.models.user import UserRole
from app.models.customer import Gender
from app.models.service import ServiceType
from app.models.subscription import SubscriptionStatus
from app.models.transaction import PaymentMethod, TransactionType
from app.models.expense import ExpenseStatus
from app.models.complaint import ComplaintType, ComplaintStatus


# User Schemas
class UserSchema(Schema):
    id = fields.Int(dump_only=True)
    username = fields.Str(required=True, validate=validate.Length(min=3, max=80))
    email = fields.Email(required=True)
    password = fields.Str(load_only=True, required=True, validate=validate.Length(min=6))
    full_name = fields.Str(required=True, validate=validate.Length(min=2, max=150))
    phone = fields.Str(allow_none=True)
    role = fields.Str(required=True, validate=validate.OneOf([r.value for r in UserRole]))
    branch_id = fields.Int(allow_none=True)
    branch_name = fields.Str(dump_only=True)
    is_active = fields.Bool()
    created_at = fields.DateTime(dump_only=True)
    last_login = fields.DateTime(dump_only=True)


class LoginSchema(Schema):
    username = fields.Str(required=True)
    password = fields.Str(required=True, load_only=True)


# Branch Schemas
class BranchSchema(Schema):
    id = fields.Int(dump_only=True)
    name = fields.Str(required=True, validate=validate.Length(min=2, max=150))
    code = fields.Str(required=True, validate=validate.Length(min=2, max=20))
    address = fields.Str(allow_none=True)
    phone = fields.Str(allow_none=True)
    city = fields.Str(allow_none=True)
    is_active = fields.Bool()
    created_at = fields.DateTime(dump_only=True)
    staff_count = fields.Int(dump_only=True)
    customers_count = fields.Int(dump_only=True)


# Customer Schemas
class CustomerSchema(Schema):
    id = fields.Int(dump_only=True)
    full_name = fields.Str(required=True, validate=validate.Length(min=2, max=150))
    phone = fields.Str(required=True, validate=validate.Length(min=10, max=20))
    email = fields.Email(allow_none=True)
    national_id = fields.Str(allow_none=True)
    date_of_birth = fields.Date(allow_none=True)
    gender = fields.Str(allow_none=True, validate=validate.OneOf([g.value for g in Gender]))
    address = fields.Str(allow_none=True)
    height = fields.Float(allow_none=True, validate=validate.Range(min=50, max=300))
    weight = fields.Float(allow_none=True, validate=validate.Range(min=20, max=500))
    bmi = fields.Float(dump_only=True)
    bmi_category = fields.Str(dump_only=True)
    bmr = fields.Float(dump_only=True)
    ideal_weight = fields.Float(dump_only=True)
    daily_calories = fields.Int(dump_only=True)
    health_notes = fields.Str(allow_none=True)
    qr_code = fields.Str(dump_only=True)
    branch_id = fields.Int(required=True)
    branch_name = fields.Str(dump_only=True)
    is_active = fields.Bool()
    password_changed = fields.Bool(dump_only=True)
    temp_password = fields.Str(dump_only=True, allow_none=True)
    has_active_subscription = fields.Bool(dump_only=True)  # ✅ CRITICAL FIX
    created_at = fields.DateTime(dump_only=True)
    updated_at = fields.DateTime(dump_only=True)


# Service Schemas
class ServiceSchema(Schema):
    id = fields.Int(dump_only=True)
    name = fields.Str(required=True, validate=validate.Length(min=2, max=150))
    service_type = fields.Str(required=True, validate=validate.OneOf([s.value for s in ServiceType]))
    description = fields.Str(allow_none=True)
    price = fields.Decimal(required=True, as_string=True, validate=validate.Range(min=0))
    duration_days = fields.Int(required=True, validate=validate.Range(min=1))
    allowed_days_per_week = fields.Int(validate=validate.Range(min=1, max=7))
    class_limit = fields.Int(allow_none=True, validate=validate.Range(min=1))
    freeze_count_limit = fields.Int(validate=validate.Range(min=0))
    freeze_max_days = fields.Int(validate=validate.Range(min=0))
    freeze_is_paid = fields.Bool()
    freeze_cost = fields.Decimal(as_string=True, validate=validate.Range(min=0))
    is_active = fields.Bool()
    created_at = fields.DateTime(dump_only=True)


# Subscription Schemas
class SubscriptionSchema(Schema):
    id = fields.Int(dump_only=True)
    customer_id = fields.Int(required=True)
    customer_name = fields.Str(dump_only=True)
    customer_phone = fields.Str(dump_only=True)
    service_id = fields.Int(required=True)
    service_name = fields.Str(dump_only=True)
    service_type = fields.Str(dump_only=True)
    branch_id = fields.Int(required=True)
    branch_name = fields.Str(dump_only=True)
    start_date = fields.Date(required=True)
    end_date = fields.Date(required=True)
    status = fields.Str(validate=validate.OneOf([s.value for s in SubscriptionStatus]))
    freeze_count = fields.Int(dump_only=True)
    total_frozen_days = fields.Int(dump_only=True)
    stop_reason = fields.Str(allow_none=True)
    stopped_at = fields.DateTime(dump_only=True)
    classes_attended = fields.Int()
    created_at = fields.DateTime(dump_only=True)
    is_expired = fields.Bool(dump_only=True)
    can_access = fields.Bool(dump_only=True)


class FreezeSubscriptionSchema(Schema):
    days = fields.Int(required=True, validate=validate.Range(min=1))
    reason = fields.Str(allow_none=True)


class StopSubscriptionSchema(Schema):
    reason = fields.Str(required=True, validate=validate.Length(min=3))


# Transaction Schemas
class TransactionSchema(Schema):
    id = fields.Int(dump_only=True)
    amount = fields.Decimal(required=True, as_string=True, validate=validate.Range(min=0))
    discount = fields.Decimal(as_string=True, load_default=0, dump_default=0)
    payment_method = fields.Str(required=True, validate=validate.OneOf([p.value for p in PaymentMethod]))
    transaction_type = fields.Str(required=True, validate=validate.OneOf([t.value for t in TransactionType]))
    branch_id = fields.Int(required=True)
    branch_name = fields.Str(dump_only=True)
    customer_id = fields.Int(allow_none=True)
    subscription_id = fields.Int(allow_none=True)
    created_by = fields.Int(dump_only=True)
    created_by_name = fields.Str(dump_only=True)
    description = fields.Str(allow_none=True)
    notes = fields.Str(allow_none=True)
    reference_number = fields.Str(allow_none=True)
    transaction_date = fields.DateTime()
    created_at = fields.DateTime(dump_only=True)


# Expense Schemas
class ExpenseSchema(Schema):
    id = fields.Int(dump_only=True)
    title = fields.Str(required=True, validate=validate.Length(min=3, max=200))
    description = fields.Str(allow_none=True)
    amount = fields.Float(required=True, validate=validate.Range(min=0))
    category = fields.Str(allow_none=True)
    branch_id = fields.Int(required=True)
    branch_name = fields.Str(dump_only=True)
    status = fields.Function(
        lambda obj: obj.status.value if hasattr(obj.status, 'value') else str(obj.status),
        deserialize=lambda v: v,
    )
    created_by_id = fields.Int(dump_only=True)
    created_by_name = fields.Str(dump_only=True)
    reviewed_by_id = fields.Int(dump_only=True)
    reviewed_by_name = fields.Str(dump_only=True, allow_none=True)
    review_notes = fields.Str(allow_none=True)
    reviewed_at = fields.DateTime(dump_only=True, allow_none=True)
    expense_date = fields.Date(required=True)
    created_at = fields.DateTime(dump_only=True)


class ExpenseReviewSchema(Schema):
    action = fields.Str(required=True, validate=validate.OneOf(['approve', 'reject']))
    notes = fields.Str(allow_none=True)


# Complaint Schemas
class ComplaintSchema(Schema):
    id = fields.Int(dump_only=True)
    title = fields.Str(required=True, validate=validate.Length(min=3, max=200))
    description = fields.Str(required=True, validate=validate.Length(min=10))
    complaint_type = fields.Str(required=True, validate=validate.OneOf([c.value for c in ComplaintType]))
    status = fields.Str(validate=validate.OneOf([s.value for s in ComplaintStatus]))
    branch_id = fields.Int(required=True)
    branch_name = fields.Str(dump_only=True)
    customer_id = fields.Int(allow_none=True)
    customer_name = fields.Str(allow_none=True)
    customer_phone = fields.Str(allow_none=True)
    resolution_notes = fields.Str(allow_none=True)
    resolved_at = fields.DateTime(dump_only=True)
    created_at = fields.DateTime(dump_only=True)
    updated_at = fields.DateTime(dump_only=True)


class ComplaintUpdateSchema(Schema):
    status = fields.Str(validate=validate.OneOf([s.value for s in ComplaintStatus]))
    resolution_notes = fields.Str(allow_none=True)


# Fingerprint Schemas
class FingerprintSchema(Schema):
    id = fields.Int(dump_only=True)
    customer_id = fields.Int(required=True)
    customer_name = fields.Str(dump_only=True)
    fingerprint_hash = fields.Str(dump_only=True)
    is_active = fields.Bool(dump_only=True)
    created_at = fields.DateTime(dump_only=True)
    last_used = fields.DateTime(dump_only=True)
    deactivated_at = fields.DateTime(dump_only=True)
    deactivation_reason = fields.Str(dump_only=True)


class FingerprintRegisterSchema(Schema):
    customer_id = fields.Int(required=True)
    unique_data = fields.Str(required=True, validate=validate.Length(min=10))


class FingerprintValidateSchema(Schema):
    fingerprint_hash = fields.Str(required=True)


# Daily Closing Schemas
class DailyClosingSchema(Schema):
    id = fields.Int(dump_only=True)
    branch_id = fields.Int(required=True)
    branch_name = fields.Str(dump_only=True)
    closing_date = fields.Date(required=True)
    expected_cash = fields.Decimal(required=True, as_string=True)
    actual_cash = fields.Decimal(required=True, as_string=True)
    cash_difference = fields.Decimal(dump_only=True, as_string=True)
    network_total = fields.Decimal(as_string=True)
    transfer_total = fields.Decimal(as_string=True)
    total_revenue = fields.Decimal(required=True, as_string=True)
    closed_by = fields.Int(dump_only=True)
    closed_by_name = fields.Str(dump_only=True)
    notes = fields.Str(allow_none=True)
    created_at = fields.DateTime(dump_only=True)
