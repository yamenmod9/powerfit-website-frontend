"""
Temporary seed trigger - creates gyms table and records for existing owners.
Also runs lightweight schema migrations (add missing columns).
Remove after initial setup is complete.
"""
from flask import Blueprint
from app.extensions import db
from app.models.gym import Gym
from app.models.user import User, UserRole

seed_trigger_bp = Blueprint('seed_trigger', __name__)


def _add_column_if_missing(table, column, col_type='VARCHAR(255)'):
    """Add a column to an existing table if it doesn't exist (SQLite)."""
    try:
        db.session.execute(db.text(f"SELECT {column} FROM {table} LIMIT 1"))
    except Exception:
        db.session.rollback()
        db.session.execute(db.text(f"ALTER TABLE {table} ADD COLUMN {column} {col_type}"))
        db.session.commit()
        return True
    return False


@seed_trigger_bp.route('/api/admin/run-seed', methods=['POST'])
def run_seed():
    """Create gyms table and add gym records for existing owners.
    Also runs lightweight migrations for new columns."""
    try:
        # Create any new tables
        db.create_all()

        # ── Schema migrations ──────────────────────────────
        migrations = []
        if _add_column_if_missing('fingerprints', 'template_hash'):
            migrations.append('fingerprints.template_hash')

        # ── Seed gym records ──────────────────────────────
        owners = User.query.filter_by(role=UserRole.OWNER).all()
        created = 0
        for owner in owners:
            existing = Gym.query.filter_by(owner_id=owner.id).first()
            if not existing:
                gym = Gym(
                    name=f"{owner.full_name}'s Gym",
                    owner_id=owner.id,
                    is_setup_complete=False,
                )
                db.session.add(gym)
                created += 1

        db.session.commit()
        return {
            'success': True,
            'message': f'Created {created} gym records for owners',
            'total_owners': len(owners),
            'migrations': migrations,
        }
    except Exception as e:
        db.session.rollback()
        return {'success': False, 'error': str(e)}, 500
