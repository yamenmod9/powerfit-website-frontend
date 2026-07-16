"""
Subscription service - handles subscription logic
"""
from datetime import datetime, timedelta, date
from app.extensions import db
from app.models.subscription import Subscription, SubscriptionStatus
from app.models.customer import Customer
from app.models.service import Service
from app.models.transaction import Transaction, PaymentMethod, TransactionType
from app.models.freeze_history import FreezeHistory
from app.models.fingerprint import Fingerprint


class SubscriptionService:
    """Subscription management service"""
    
    @staticmethod
    def _derive_subscription_type(service):
        """
        Derive subscription_type from a Service object.
        Handles both uppercase enum names ('GYM') and lowercase values ('gym').
        """
        from app.models.service import ServiceType

        # service_type may be an enum instance or a raw string stored by SQLAlchemy
        stype = service.service_type
        if isinstance(stype, ServiceType):
            stype_upper = stype.name.upper()   # e.g. 'GYM'
        else:
            stype_upper = str(stype).upper()   # handles 'GYM', 'gym', 'ServiceType.GYM'
            # Strip 'SERVICETYPE.' prefix if present
            if '.' in stype_upper:
                stype_upper = stype_upper.split('.')[-1]

        if stype_upper == 'GYM':
            return 'coins'
        if stype_upper == 'KARATE':
            return 'training'
        if stype_upper == 'SWIMMING_EDUCATION' or service.class_limit:
            return 'sessions'
        # SWIMMING_RECREATION, BUNDLE → time_based
        return 'time_based'

    @staticmethod
    def create_subscription(data, created_by_user_id):
        """Create a new subscription"""
        # Validate customer
        customer = db.session.get(Customer, data['customer_id'])
        if not customer:
            return None, "Customer not found"
        
        # Validate service
        service = db.session.get(Service, data['service_id'])
        if not service or not service.is_active:
            return None, "Service not found or inactive"
        
        # Calculate dates
        start_date = data.get('start_date')
        if not start_date:
            start_date = date.today()
        elif isinstance(start_date, str):
            try:
                start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
            except ValueError:
                start_date = date.today()
        
        # Allow caller to override the duration (e.g. duration_months → days from the form)
        duration_days = data.get('duration_days_override') or service.duration_days
        end_date = start_date + timedelta(days=int(duration_days))

        # ── Derive subscription type ──────────────────────────────────────
        # Allow caller to override via data['subscription_type'], otherwise derive
        sub_type = data.get('subscription_type') or SubscriptionService._derive_subscription_type(service)

        # ── Set type-specific fields ──────────────────────────────────────
        remaining_coins  = None
        total_coins      = None
        remaining_sessions = None
        total_sessions   = None
        remaining_visits = None
        remaining_classes = None

        if sub_type == 'coins':
            coin_amount = (
                data.get('coin_amount')
                or data.get('coins')
                or data.get('remaining_coins')
                or service.class_limit
                or 50
            )
            remaining_coins = int(coin_amount)
            total_coins     = int(coin_amount)

        elif sub_type in ('sessions', 'training'):
            session_count = data.get('session_count') or service.class_limit or 10
            remaining_sessions = int(session_count)
            total_sessions     = int(session_count)
            remaining_classes  = remaining_sessions   # keep legacy field in sync

        else:  # time_based
            # Keep legacy visit tracking for gym door access
            remaining_visits = None  # unlimited for time-based

        # Create subscription
        subscription = Subscription(
            customer_id=customer.id,
            service_id=service.id,
            branch_id=data['branch_id'],
            start_date=start_date,
            end_date=end_date,
            status=SubscriptionStatus.ACTIVE,
            subscription_type=sub_type,
            remaining_coins=remaining_coins,
            total_coins=total_coins,
            remaining_sessions=remaining_sessions,
            total_sessions=total_sessions,
            remaining_visits=remaining_visits,
            remaining_classes=remaining_classes,
            created_by=created_by_user_id,
        )

        db.session.add(subscription)
        db.session.flush()  # Get subscription ID
        
        # Create transaction
        transaction = Transaction(
            amount=service.price,
            payment_method=PaymentMethod(data.get('payment_method', 'cash')),
            transaction_type=TransactionType.SUBSCRIPTION,
            branch_id=data['branch_id'],
            customer_id=customer.id,
            subscription_id=subscription.id,
            created_by=created_by_user_id,
            description=f"New subscription: {service.name}",
            reference_number=data.get('reference_number')
        )
        
        db.session.add(transaction)
        
        # Activate fingerprint if exists
        fingerprints = Fingerprint.query.filter_by(
            customer_id=customer.id
        ).all()
        
        for fp in fingerprints:
            if not fp.is_active:
                fp.is_active = True
                fp.deactivation_reason = None
        
        db.session.commit()
        
        return subscription, None
    
    @staticmethod
    def renew_subscription(subscription_id, data, created_by_user_id):
        """Renew an existing subscription"""
        subscription = db.session.get(Subscription, subscription_id)
        if not subscription:
            return None, "Subscription not found"
        
        service = subscription.service

        # Calculate new dates
        if subscription.status == SubscriptionStatus.ACTIVE and subscription.end_date >= date.today():
            start_date = subscription.end_date + timedelta(days=1)
        else:
            start_date = date.today()
        
        end_date = start_date + timedelta(days=service.duration_days)

        # ── Derive / preserve subscription type ──────────────────────────
        sub_type = (
            data.get('subscription_type')
            or subscription.subscription_type
            or SubscriptionService._derive_subscription_type(service)
        )

        # ── Reset type-specific counters ─────────────────────────────────
        remaining_coins    = None
        total_coins        = None
        remaining_sessions = None
        total_sessions     = None
        remaining_visits   = None
        remaining_classes  = None

        if sub_type == 'coins':
            coin_amount = (
                data.get('coin_amount')
                or data.get('remaining_coins')
                or subscription.total_coins
                or service.class_limit
                or 50
            )
            remaining_coins = int(coin_amount)
            total_coins     = int(coin_amount)

        elif sub_type in ('sessions', 'training'):
            session_count = (
                data.get('session_count')
                or subscription.total_sessions
                or service.class_limit
                or 10
            )
            remaining_sessions = int(session_count)
            total_sessions     = int(session_count)
            remaining_classes  = remaining_sessions

        # else time_based: no counters needed

        # Update subscription
        subscription.start_date        = start_date
        subscription.end_date          = end_date
        subscription.status            = SubscriptionStatus.ACTIVE
        subscription.subscription_type = sub_type
        subscription.remaining_coins   = remaining_coins
        subscription.total_coins       = total_coins
        subscription.remaining_sessions = remaining_sessions
        subscription.total_sessions    = total_sessions
        subscription.remaining_visits  = remaining_visits
        subscription.remaining_classes = remaining_classes
        subscription.freeze_count      = 0
        subscription.total_frozen_days = 0
        subscription.classes_attended  = 0
        subscription.stop_reason       = None
        subscription.stopped_at        = None

        # Create renewal transaction
        transaction = Transaction(
            amount=service.price,
            payment_method=PaymentMethod(data.get('payment_method', 'cash')),
            transaction_type=TransactionType.RENEWAL,
            branch_id=subscription.branch_id,
            customer_id=subscription.customer_id,
            subscription_id=subscription.id,
            created_by=created_by_user_id,
            description=f"Renewal: {service.name}",
            reference_number=data.get('reference_number')
        )
        
        db.session.add(transaction)
        
        # Reactivate fingerprints
        fingerprints = Fingerprint.query.filter_by(
            customer_id=subscription.customer_id
        ).all()
        
        for fp in fingerprints:
            fp.is_active = True
            fp.deactivation_reason = None
        
        db.session.commit()
        
        return subscription, None
    
    @staticmethod
    def freeze_subscription(subscription_id, days, reason, created_by_user_id):
        """Freeze a subscription"""
        subscription = db.session.get(Subscription, subscription_id)
        if not subscription:
            return None, "Subscription not found"
        
        success, message = subscription.freeze(days, reason)
        if not success:
            return None, message
        
        # Create freeze history
        freeze_start = date.today()
        freeze_end = freeze_start + timedelta(days=days)
        
        freeze_history = FreezeHistory(
            subscription_id=subscription.id,
            freeze_start=freeze_start,
            freeze_end=freeze_end,
            freeze_days=days,
            reason=reason,
            cost=subscription.service.freeze_cost,
            is_active=True
        )
        
        db.session.add(freeze_history)
        
        # Create transaction if freeze is paid
        if subscription.service.freeze_is_paid and subscription.service.freeze_cost > 0:
            transaction = Transaction(
                amount=subscription.service.freeze_cost,
                payment_method=PaymentMethod.CASH,
                transaction_type=TransactionType.FREEZE,
                branch_id=subscription.branch_id,
                customer_id=subscription.customer_id,
                subscription_id=subscription.id,
                created_by=created_by_user_id,
                description=f"Freeze fee: {days} days"
            )
            db.session.add(transaction)
        
        # Deactivate fingerprints
        fingerprints = Fingerprint.query.filter_by(
            customer_id=subscription.customer_id,
            is_active=True
        ).all()
        
        for fp in fingerprints:
            fp.deactivate("Subscription frozen")
        
        db.session.commit()
        
        return subscription, None
    
    @staticmethod
    def unfreeze_subscription(subscription_id):
        """Unfreeze a subscription"""
        subscription = db.session.get(Subscription, subscription_id)
        if not subscription:
            return None, "Subscription not found"
        
        success, message = subscription.unfreeze()
        if not success:
            return None, message
        
        # Mark current freeze as inactive
        active_freeze = FreezeHistory.query.filter_by(
            subscription_id=subscription.id,
            is_active=True
        ).first()
        
        if active_freeze:
            active_freeze.is_active = False
            active_freeze.unfrozen_at = datetime.utcnow()
        
        # Reactivate fingerprints
        fingerprints = Fingerprint.query.filter_by(
            customer_id=subscription.customer_id
        ).all()
        
        for fp in fingerprints:
            fp.is_active = True
            fp.deactivation_reason = None
        
        db.session.commit()
        
        return subscription, None
    
    @staticmethod
    def stop_subscription(subscription_id, reason):
        """Stop a subscription"""
        subscription = db.session.get(Subscription, subscription_id)
        if not subscription:
            return None, "Subscription not found"
        
        success, message = subscription.stop(reason)
        if not success:
            return None, message
        
        # Deactivate fingerprints
        fingerprints = Fingerprint.query.filter_by(
            customer_id=subscription.customer_id,
            is_active=True
        ).all()
        
        for fp in fingerprints:
            # Check if customer has other active subscriptions
            other_active = Subscription.query.filter(
                Subscription.customer_id == subscription.customer_id,
                Subscription.id != subscription.id,
                Subscription.status == SubscriptionStatus.ACTIVE
            ).first()
            
            if not other_active:
                fp.deactivate("Subscription stopped")
        
        db.session.commit()
        
        return subscription, None
