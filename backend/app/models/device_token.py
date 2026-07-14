"""
Device Token model - Stores FCM device tokens for push notifications
"""
from datetime import datetime
from app.extensions import db


class DeviceToken(db.Model):
    """Stores FCM tokens per user/customer for push notifications"""
    __tablename__ = 'device_tokens'

    id = db.Column(db.Integer, primary_key=True)

    # One of these will be set depending on app_type
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True, index=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('customers.id'), nullable=True, index=True)

    fcm_token = db.Column(db.String(512), nullable=False, index=True)
    app_type = db.Column(db.String(20), nullable=False)  # 'staff', 'client', 'super_admin'
    platform = db.Column(db.String(10), nullable=False, default='android')  # 'android', 'ios'
    is_active = db.Column(db.Boolean, default=True, nullable=False)

    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = db.relationship('User', backref=db.backref('device_tokens', lazy='dynamic'))
    customer = db.relationship('Customer', backref=db.backref('device_tokens', lazy='dynamic'))

    def __repr__(self):
        owner = f'user={self.user_id}' if self.user_id else f'customer={self.customer_id}'
        return f'<DeviceToken {owner} app={self.app_type}>'

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'customer_id': self.customer_id,
            'fcm_token': self.fcm_token,
            'app_type': self.app_type,
            'platform': self.platform,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat(),
        }
