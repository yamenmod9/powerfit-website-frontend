"""
Attendance routes - Alias for entry logs (QR check-in)
This provides the /api/attendance endpoint as specified in the Flutter app
"""
from flask import Blueprint
from flask_jwt_extended import jwt_required
from app.utils import role_required
from app.models.user import UserRole

# Import the scan handler from entry_logs_routes
from .entry_logs_routes import scan_qr_code

attendance_bp = Blueprint('attendance', __name__, url_prefix='/api/attendance')


@attendance_bp.route('', methods=['POST'])
@jwt_required()
@role_required(UserRole.SUPER_ADMIN, UserRole.FRONT_DESK, UserRole.BRANCH_MANAGER, UserRole.OWNER)
def record_attendance():
    """
    Record customer check-in/attendance (Alias for /api/entry-logs/scan)
    
    This endpoint provides backward compatibility with the Flutter app specification
    which expects POST /api/attendance for QR code check-in.
    
    Request Body:
    {
        "qr_code": "GYM-000001",
        "branch_id": 1
    }
    
    Response:
    {
        "success": true,
        "message": "Check-in recorded successfully",
        "data": {
            "attendance_id": 789,
            "customer_name": "Adel Saad",
            "check_in_time": "2026-02-16T10:30:00Z",
            "coins_deducted": 1,
            "remaining_coins": 24
        }
    }
    """
    # Call the existing scan_qr_code function
    return scan_qr_code()
