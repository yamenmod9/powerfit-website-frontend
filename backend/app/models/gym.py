"""
Gym model - Represents a gym owned by an OWNER user.
Created automatically when a super admin creates an owner.
"""
from datetime import datetime
from app.extensions import db


class Gym(db.Model):
    """Gym entity – one per owner."""
    __tablename__ = 'gyms'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), nullable=False, default='My Gym')
    owner_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, unique=True, index=True)
    logo_url = db.Column(db.String(500), nullable=True)
    primary_color = db.Column(db.String(10), nullable=False, default='#DC2626')
    secondary_color = db.Column(db.String(10), nullable=False, default='#EF4444')
    is_setup_complete = db.Column(db.Boolean, default=False, nullable=False)
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationship back to the owner User (explicit FK to avoid ambiguity with User.gym_id)
    owner = db.relationship('User', foreign_keys=[owner_id], backref=db.backref('gym', uselist=False, lazy='joined'))

    def __repr__(self):
        return f'<Gym {self.name} (owner={self.owner_id})>'

    def to_dict(self):
        """Serialize to dictionary matching Flutter GymModel.fromJson expectations."""
        from flask import request as flask_request
        owner = self.owner

        # Build full logo URL so Flutter can use Image.network() directly
        logo = self.logo_url
        if logo and logo.startswith('/'):
            try:
                logo = flask_request.url_root.rstrip('/') + logo
            except RuntimeError:
                pass  # Outside request context — keep relative

        return {
            'id': self.id,
            'name': self.name,
            'owner_id': self.owner_id,
            'owner_name': owner.full_name if owner else None,
            'owner_username': owner.username if owner else None,
            'logo_url': logo,
            'primary_color': self.primary_color,
            'secondary_color': self.secondary_color,
            'is_setup_complete': self.is_setup_complete,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
