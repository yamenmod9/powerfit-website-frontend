"""
Gym routes - Setup and management of gym branding/settings
"""
import os
import uuid
from flask import Blueprint, request, send_from_directory, current_app
from flask_jwt_extended import jwt_required
from werkzeug.utils import secure_filename
from app.extensions import db
from app.models.gym import Gym
from app.models.user import UserRole
from app.utils import success_response, error_response, get_current_user, role_required

gyms_bp = Blueprint('gyms', __name__, url_prefix='/api/gyms')

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}


def _allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def _upload_dir():
    """Return (and create) the upload directory path."""
    base = os.path.join(current_app.root_path, 'static', 'uploads')
    os.makedirs(base, exist_ok=True)
    return base


@gyms_bp.route('/my-gym', methods=['GET'])
@jwt_required()
def get_my_gym():
    """Return the gym associated with the current owner.
    For non-owner roles, return the gym owned by their branch owner (future).
    """
    user = get_current_user()
    if not user:
        return error_response("Session expired. Please log in again.", 401)

    gym = None
    if user.role == UserRole.OWNER:
        gym = Gym.query.filter_by(owner_id=user.id).first()
    # For other roles, try to find the gym through the branch owner
    # (not yet implemented — they share the owner's gym)

    if not gym:
        return error_response("No gym found for this user", 404)

    return success_response(gym.to_dict())


@gyms_bp.route('/setup', methods=['PUT'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER)
def setup_gym():
    """Complete (or update) the gym setup wizard.
    
    Expected JSON body:
    {
        "name": "Body Art Fitness",
        "primary_color": "#3B82F6",
        "secondary_color": "#6366F1",
        "logo_url": "https://...",           (optional)
        "is_setup_complete": true
    }
    """
    user = get_current_user()
    if not user:
        return error_response("Session expired. Please log in again.", 401)

    gym = Gym.query.filter_by(owner_id=user.id).first()
    if not gym:
        # Auto-create if somehow missing
        gym = Gym(owner_id=user.id)
        db.session.add(gym)

    data = request.json or {}

    if 'name' in data:
        gym.name = data['name']
    if 'primary_color' in data:
        gym.primary_color = data['primary_color']
    if 'secondary_color' in data:
        gym.secondary_color = data['secondary_color']
    if 'logo_url' in data:
        gym.logo_url = data['logo_url']
    if data.get('is_setup_complete') is not None:
        gym.is_setup_complete = bool(data['is_setup_complete'])

    db.session.commit()

    return success_response(gym.to_dict(), "Gym setup saved successfully")


@gyms_bp.route('/upload-logo', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.OWNER)
def upload_logo():
    """Upload a gym logo image.

    Expects a multipart/form-data request with a 'logo' file field.
    Returns the public URL of the uploaded image.
    """
    user = get_current_user()
    if not user:
        return error_response("Session expired. Please log in again.", 401)

    if 'logo' not in request.files:
        return error_response("No file uploaded. Send a 'logo' field.", 400)

    file = request.files['logo']
    if file.filename == '':
        return error_response("Empty filename", 400)

    if not _allowed_file(file.filename):
        return error_response(
            f"File type not allowed. Use: {', '.join(ALLOWED_EXTENSIONS)}", 400
        )

    # Generate a unique filename to avoid collisions
    ext = file.filename.rsplit('.', 1)[1].lower()
    unique_name = f"gym_{user.id}_{uuid.uuid4().hex[:8]}.{ext}"
    safe_name = secure_filename(unique_name)

    upload_path = os.path.join(_upload_dir(), safe_name)
    file.save(upload_path)

    # Build public URL — works for both local dev and PythonAnywhere
    logo_url = f"/api/gyms/logos/{safe_name}"

    # Also update the gym record
    gym = Gym.query.filter_by(owner_id=user.id).first()
    if gym:
        # Delete old logo file if it exists
        if gym.logo_url and gym.logo_url.startswith('/api/gyms/logos/'):
            old_name = gym.logo_url.split('/')[-1]
            old_path = os.path.join(_upload_dir(), old_name)
            if os.path.exists(old_path):
                os.remove(old_path)

        gym.logo_url = logo_url
        db.session.commit()

    return success_response({
        'logo_url': logo_url,
        'filename': safe_name,
    }, "Logo uploaded successfully")


@gyms_bp.route('/logos/<filename>', methods=['GET'])
def serve_logo(filename):
    """Serve uploaded logo images (no auth required so images load everywhere)."""
    safe = secure_filename(filename)
    return send_from_directory(_upload_dir(), safe)


@gyms_bp.route('', methods=['GET'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN)
def list_gyms():
    """List all gyms (super admin only)."""
    gyms = Gym.query.all()
    return success_response([g.to_dict() for g in gyms])
