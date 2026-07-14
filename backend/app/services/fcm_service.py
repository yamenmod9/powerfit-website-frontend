"""
FCM Push Notification Service — sends push notifications via Firebase Admin SDK.

SETUP:
  1. pip install firebase-admin
  2. Place your Firebase service account JSON at the path configured in
     FIREBASE_SERVICE_ACCOUNT_PATH (default: 'service_account.json' in
     the backend directory, or set the env var).
"""
import os
import logging
from typing import Optional, List, Dict

logger = logging.getLogger(__name__)

# Lazy-init; Firebase Admin is optional at import time.
_firebase_app = None


def _init_firebase():
    """Initialise Firebase Admin SDK once."""
    global _firebase_app
    if _firebase_app is not None:
        return True

    try:
        import firebase_admin
        from firebase_admin import credentials
    except ImportError:
        logger.warning('firebase-admin package not installed — push disabled')
        return False

    # Resolve path to service account key
    sa_path = os.environ.get(
        'FIREBASE_SERVICE_ACCOUNT_PATH',
        os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
                     'service_account.json'),
    )

    if not os.path.isfile(sa_path):
        logger.warning(f'Firebase service account not found at {sa_path} — push disabled')
        return False

    try:
        cred = credentials.Certificate(sa_path)
        _firebase_app = firebase_admin.initialize_app(cred)
        logger.info('Firebase Admin SDK initialised')
        return True
    except Exception as e:
        logger.error(f'Firebase init error: {e}')
        return False


# ──────────────────────────────────────────────
#  Public helpers — import these from elsewhere
# ──────────────────────────────────────────────

def send_push_to_token(
    fcm_token: str,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
) -> bool:
    """Send a push notification to a single FCM token."""
    if not _init_firebase():
        return False

    from firebase_admin import messaging

    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data=data or {},
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='default_channel',
                sound='default',
            ),
        ),
        token=fcm_token,
    )
    try:
        resp = messaging.send(message)
        logger.info(f'Push sent: {resp}')
        return True
    except messaging.UnregisteredError:
        logger.warning(f'Push token unregistered: {fcm_token[:20]}…')
        _deactivate_token(fcm_token)
        return False
    except Exception as e:
        logger.error(f'Push send error: {e}')
        return False


def send_push_to_tokens(
    fcm_tokens: List[str],
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
) -> int:
    """Send a push notification to multiple tokens. Returns count of successes."""
    if not _init_firebase() or not fcm_tokens:
        return 0

    from firebase_admin import messaging

    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        data=data or {},
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='default_channel',
                sound='default',
            ),
        ),
        tokens=fcm_tokens,
    )
    try:
        response = messaging.send_each_for_multicast(message)
        # Deactivate failed tokens
        for i, send_response in enumerate(response.responses):
            if send_response.exception and isinstance(
                send_response.exception, messaging.UnregisteredError
            ):
                _deactivate_token(fcm_tokens[i])
        logger.info(f'Push multicast: {response.success_count} ok, {response.failure_count} failed')
        return response.success_count
    except Exception as e:
        logger.error(f'Push multicast error: {e}')
        return 0


# ──────────────────────────────────────────────
#  High-level helpers scoped to user roles
# ──────────────────────────────────────────────

def notify_user(user_id: int, title: str, body: str, data: Optional[Dict[str, str]] = None) -> int:
    """Send a push notification to all active devices of a staff/admin user."""
    from app.models.device_token import DeviceToken
    tokens = DeviceToken.query.filter_by(user_id=user_id, is_active=True).all()
    sent = 0
    for dt in tokens:
        if send_push_to_token(dt.fcm_token, title, body, data):
            sent += 1
    return sent


def notify_customer(customer_id: int, title: str, body: str, data: Optional[Dict[str, str]] = None) -> int:
    """Send a push notification to all active devices of a customer/client."""
    from app.models.device_token import DeviceToken
    tokens = DeviceToken.query.filter_by(customer_id=customer_id, is_active=True).all()
    sent = 0
    for dt in tokens:
        if send_push_to_token(dt.fcm_token, title, body, data):
            sent += 1
    return sent


def notify_role(role_value: str, title: str, body: str, data: Optional[Dict[str, str]] = None) -> int:
    """
    Send a push notification to ALL users with a given role.
    role_value: 'owner', 'branch_manager', 'front_desk', 'super_admin', etc.
    """
    from app.models.device_token import DeviceToken
    from app.models.user import User, UserRole

    try:
        role_enum = UserRole(role_value)
    except ValueError:
        logger.warning(f'Unknown role: {role_value}')
        return 0

    user_ids = [u.id for u in User.query.filter_by(role=role_enum, is_active=True).all()]
    if not user_ids:
        return 0

    tokens = DeviceToken.query.filter(
        DeviceToken.user_id.in_(user_ids),
        DeviceToken.is_active == True,
    ).all()

    fcm_list = [dt.fcm_token for dt in tokens]
    if not fcm_list:
        return 0

    return send_push_to_tokens(fcm_list, title, body, data)


def notify_all_customers(title: str, body: str, data: Optional[Dict[str, str]] = None) -> int:
    """Send a push notification to ALL registered client devices."""
    from app.models.device_token import DeviceToken
    tokens = DeviceToken.query.filter_by(
        app_type='client', is_active=True,
    ).all()
    fcm_list = [dt.fcm_token for dt in tokens]
    if not fcm_list:
        return 0
    return send_push_to_tokens(fcm_list, title, body, data)


# ──────────────────────────────────────────────
#  Internal helper
# ──────────────────────────────────────────────

def _deactivate_token(fcm_token: str):
    """Mark a token as inactive in the DB."""
    try:
        from app.models.device_token import DeviceToken
        from app.extensions import db
        DeviceToken.query.filter_by(fcm_token=fcm_token).update({'is_active': False})
        db.session.commit()
    except Exception:
        pass
