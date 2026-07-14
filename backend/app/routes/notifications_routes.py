"""
Push notification routes — register/unregister device tokens and send notifications
"""
from flask import Blueprint, request
from flask_jwt_extended import decode_token, jwt_required
from app.extensions import db
from app.models.device_token import DeviceToken
from app.models.user import User
from app.utils import success_response, error_response

notifications_bp = Blueprint('notifications', __name__, url_prefix='/api/notifications')


@notifications_bp.route('/register-device', methods=['POST'])
def register_device():
    """
    Register an FCM device token.
    Works for both staff (JWT) and client (client JWT) tokens.

    Body:
      {
        "fcm_token": "...",
        "app_type": "staff" | "client" | "super_admin",
        "platform": "android" | "ios"   (optional, default android)
      }
    """
    data = request.get_json()
    if not data or not data.get('fcm_token') or not data.get('app_type'):
        return error_response('fcm_token and app_type are required', 400)

    fcm_token = data['fcm_token']
    app_type = data['app_type']
    platform = data.get('platform', 'android')

    user_id = None
    customer_id = None

    # Decode the JWT from Authorization header
    auth_header = request.headers.get('Authorization', '')
    if auth_header.startswith('Bearer '):
        token_str = auth_header.split(' ', 1)[1]
        try:
            decoded = decode_token(token_str)
            scope = decoded.get('scope')
            identity = decoded.get('sub')

            if scope == 'client':
                # Client token — customer_id is in claims
                cid = decoded.get('customer_id')
                if cid:
                    customer_id = int(cid)
            elif identity:
                # Staff/admin token — identity is user id
                user = db.session.get(User, int(identity))
                if user:
                    user_id = user.id
        except Exception:
            pass

    if user_id is None and customer_id is None:
        return error_response('Unable to identify user from token', 401)

    # Deactivate any existing token with the same fcm_token (token reuse across accounts)
    DeviceToken.query.filter_by(fcm_token=fcm_token).update({'is_active': False})

    # Check for an existing active entry for this user/customer + app_type
    existing = DeviceToken.query.filter_by(
        user_id=user_id,
        customer_id=customer_id,
        app_type=app_type,
        is_active=True,
    ).first()

    if existing:
        existing.fcm_token = fcm_token
        existing.platform = platform
    else:
        new_token = DeviceToken(
            user_id=user_id,
            customer_id=customer_id,
            fcm_token=fcm_token,
            app_type=app_type,
            platform=platform,
            is_active=True,
        )
        db.session.add(new_token)

    db.session.commit()

    return success_response({'registered': True}, 'Device registered for notifications')


@notifications_bp.route('/unregister-device', methods=['POST'])
def unregister_device():
    """
    Unregister an FCM device token (on logout).
    Body: { "fcm_token": "..." }
    """
    data = request.get_json()
    if not data or not data.get('fcm_token'):
        return error_response('fcm_token is required', 400)

    count = DeviceToken.query.filter_by(
        fcm_token=data['fcm_token'],
    ).update({'is_active': False})
    db.session.commit()

    return success_response({'unregistered': count}, 'Device unregistered')


@notifications_bp.route('/debug-tokens', methods=['GET'])
@jwt_required()
def debug_tokens():
    """
    Debug endpoint: list all registered device tokens.
    Only accessible to authenticated staff/admin users.
    """
    from app.models.user import User
    from flask_jwt_extended import get_jwt_identity

    identity = get_jwt_identity()
    user = db.session.get(User, int(identity)) if identity else None
    if not user:
        return error_response('Staff access required', 403)

    tokens = DeviceToken.query.order_by(DeviceToken.id.desc()).limit(50).all()
    return success_response({
        'total': DeviceToken.query.count(),
        'active': DeviceToken.query.filter_by(is_active=True).count(),
        'client_active': DeviceToken.query.filter_by(app_type='client', is_active=True).count(),
        'staff_active': DeviceToken.query.filter_by(app_type='staff', is_active=True).count(),
        'tokens': [t.to_dict() for t in tokens],
    })
