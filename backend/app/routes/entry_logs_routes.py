"""
Entry logs routes - Customer check-in/scanning
"""
import logging
from flask import Blueprint, request
from flask_jwt_extended import jwt_required
from datetime import datetime
from app.models import Customer, Subscription, EntryLog, Branch
from app.models.subscription import SubscriptionStatus
from app.models.entry_log import EntryType
from app.utils import success_response, error_response, role_required, get_current_user
from app.models.user import UserRole
from app.extensions import db

logger = logging.getLogger(__name__)

entry_logs_bp = Blueprint('entry_logs', __name__, url_prefix='/api/entry-logs')


@entry_logs_bp.route('/scan', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.FRONT_DESK, UserRole.BRANCH_MANAGER, UserRole.OWNER)
def scan_qr_code():
    """
    Record customer check-in via QR scan or customer ID
    
    Request Body (Option 1 - QR Code):
    {
        "qr_code": "GYM-000001"
    }
    
    Request Body (Option 2 - Customer ID):
    {
        "customer_id": 115,
        "qr_code": "customer_id:115",  # Optional
        "check_in_time": "2026-02-16T14:30:00Z",  # Optional
        "action": "check_in_only"  # Optional
    }
    
    Note: branch_id is automatically populated from the staff member's branch
    """
    data = request.get_json()
    
    if not data:
        return error_response("Request body is required", 400)
    
    # ✅ FIX: Auto-populate branch_id from current user
    current_user = get_current_user()
    branch_id = current_user.branch_id
    
    if not branch_id:
        return error_response("Staff member has no branch assigned", 400)
    
    # Accept either qr_code or customer_id
    qr_code = data.get('qr_code')
    customer_id = data.get('customer_id')
    
    # Extract customer_id from QR code if present
    if qr_code and not customer_id:
        if 'customer_id:' in qr_code:
            try:
                customer_id = int(qr_code.split('customer_id:')[1])
            except (ValueError, IndexError):
                pass  # Will try to find by qr_code string
    
    # Require either qr_code or customer_id
    if not qr_code and not customer_id:
        return error_response("Either qr_code or customer_id is required", 400)
    
    # Verify branch exists
    branch = db.session.get(Branch, branch_id)
    if not branch:
        return error_response("Branch not found", 404)
    
    # Find customer by customer_id first, then by QR code
    customer = None
    if customer_id:
        customer = db.session.get(Customer, customer_id)
    
    # If not found by ID, try by QR code string match
    if not customer and qr_code:
        customer = Customer.query.filter_by(qr_code=qr_code).first()
    
    if not customer:
        return error_response("Customer not found", 404)
    
    # Find active subscription
    subscription = Subscription.query.filter_by(
        customer_id=customer.id,
        status=SubscriptionStatus.ACTIVE
    ).first()
    
    # Check if no active subscription
    if not subscription:
        # Check for expired subscription
        expired_sub = Subscription.query.filter_by(
            customer_id=customer.id,
            status=SubscriptionStatus.EXPIRED
        ).order_by(Subscription.end_date.desc()).first()
        
        return error_response(
            "No active subscription found",
            403,
            {
                "code": "NO_SUBSCRIPTION",
                "customer_name": customer.full_name,
                "customer_id": customer.id,
                "has_expired_subscription": expired_sub is not None,
                "last_subscription_end_date": expired_sub.end_date.isoformat() if expired_sub else None
            }
        )
    
    # Check if subscription is frozen
    if subscription.status == SubscriptionStatus.FROZEN:
        # Get freeze history to find reason
        freeze_reason = "Subscription is currently frozen"
        frozen_date = subscription.updated_at
        
        from app.models.freeze_history import FreezeHistory
        latest_freeze = FreezeHistory.query.filter_by(
            subscription_id=subscription.id
        ).order_by(FreezeHistory.freeze_start.desc()).first()
        
        if latest_freeze:
            freeze_reason = latest_freeze.reason or "Subscription is frozen"
            frozen_date = latest_freeze.freeze_start
        
        return error_response(
            "Subscription is frozen",
            403,
            {
                "code": "FROZEN",
                "customer_name": customer.full_name,
                "customer_id": customer.id,
                "frozen_date": frozen_date.isoformat() if frozen_date else None,
                "freeze_reason": freeze_reason
            }
        )
    
    # Check remaining coins/sessions based on subscription type
    coins_deducted = 0
    sessions_deducted = 0
    
    if subscription.subscription_type == 'coins':
        # Coin-based subscription
        if subscription.remaining_coins is not None and subscription.remaining_coins <= 0:
            return error_response(
                "No coins remaining",
                403,
                {
                    "code": "NO_COINS",
                    "customer_name": customer.full_name,
                    "customer_id": customer.id,
                    "remaining_coins": 0,
                    "subscription_type": subscription.service.name
                }
            )
        coins_deducted = 1
    elif subscription.subscription_type in ['sessions', 'training']:
        # Session-based subscription
        if subscription.remaining_sessions is not None and subscription.remaining_sessions <= 0:
            return error_response(
                "No sessions remaining",
                403,
                {
                    "code": "NO_SESSIONS",
                    "customer_name": customer.full_name,
                    "customer_id": customer.id,
                    "remaining_sessions": 0,
                    "subscription_type": subscription.service.name
                }
            )
        sessions_deducted = 1
    # For time_based, no deduction needed
    
    # All checks passed - record entry and deduct coin/session
    entry_log = EntryLog(
        customer_id=customer.id,
        subscription_id=subscription.id,
        branch_id=branch_id,
        entry_time=datetime.utcnow(),
        entry_type=EntryType.QR_SCAN,
        coins_deducted=coins_deducted
    )
    
    # Deduct coin or session
    if coins_deducted > 0 and subscription.remaining_coins is not None:
        subscription.remaining_coins -= coins_deducted
    
    if sessions_deducted > 0 and subscription.remaining_sessions is not None:
        subscription.remaining_sessions -= sessions_deducted
    
    db.session.add(entry_log)
    db.session.commit()
    
    # Notify the customer about their check-in
    try:
        from app.services.fcm_service import notify_customer
        remaining_msg = ''
        if subscription.subscription_type == 'coins' and subscription.remaining_coins is not None:
            remaining_msg = f' | المتبقي: {subscription.remaining_coins} عملة'
        elif subscription.subscription_type in ['sessions', 'training'] and subscription.remaining_sessions is not None:
            remaining_msg = f' | المتبقي: {subscription.remaining_sessions} حصة'
        
        notify_customer(
            customer.id,
            '🏋️ تم تسجيل الدخول',
            f'مرحباً {customer.full_name}! تم تسجيل دخولك بنجاح.{remaining_msg}',
            {'type': 'check_in', 'entry_id': str(entry_log.id)},
        )
    except Exception as e:
        logger.exception('Push notification failed: %s', e)

    # Notify staff if coins/sessions are running low
    try:
        from app.services.fcm_service import notify_role
        low_threshold = 3
        if subscription.subscription_type == 'coins' and subscription.remaining_coins is not None and subscription.remaining_coins <= low_threshold:
            notify_role(
                'front_desk',
                '⚠️ رصيد منخفض',
                f'{customer.full_name} لديه {subscription.remaining_coins} عملة متبقية فقط.',
                {'type': 'low_balance', 'customer_id': str(customer.id)},
            )
        elif subscription.subscription_type in ['sessions', 'training'] and subscription.remaining_sessions is not None and subscription.remaining_sessions <= low_threshold:
            notify_role(
                'front_desk',
                '⚠️ حصص منخفضة',
                f'{customer.full_name} لديه {subscription.remaining_sessions} حصة متبقية فقط.',
                {'type': 'low_sessions', 'customer_id': str(customer.id)},
            )
    except Exception as e:
        logger.exception('Push notification failed: %s', e)

    return success_response({
        "attendance_id": entry_log.id,
        "entry_id": entry_log.id,  # Alias for compatibility
        "customer_name": customer.full_name,
        "customer_id": customer.id,
        "check_in_time": entry_log.entry_time.isoformat(),
        "coins_deducted": coins_deducted,
        "sessions_deducted": sessions_deducted,
        "remaining_coins": subscription.remaining_coins if subscription.subscription_type == 'coins' else None,
        "remaining_sessions": subscription.remaining_sessions if subscription.subscription_type in ['sessions', 'training'] else None,
        "subscription_end_date": subscription.end_date.isoformat(),
        "subscription_type": subscription.subscription_type
    }, "Check-in recorded successfully")
