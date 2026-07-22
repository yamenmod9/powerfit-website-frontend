"""
Flask application factory
"""
from flask import Flask, jsonify
from app.config import config
from app.extensions import init_extensions
from app.routes import register_blueprints
from flask_jwt_extended.exceptions import JWTExtendedException
from werkzeug.exceptions import HTTPException


def create_app(config_name='default'):
    """
    Application factory pattern
    
    Args:
        config_name: Configuration name (development, production, testing)
    
    Returns:
        Flask application instance
    """
    app = Flask(__name__)
    
    # Load configuration
    app.config.from_object(config[config_name])
    
    # Initialize extensions
    init_extensions(app)
    
    # Register blueprints
    register_blueprints(app)
    
    # Register error handlers
    register_error_handlers(app)
    
    # Register CLI commands
    register_cli_commands(app)
    
    # Run database schema migrations
    _ensure_db_schema(app)
    
    # Health check endpoint
    @app.route('/')
    def index():
        return jsonify({
            'message': 'Gym Management System API',
            'version': '1.0.0',
            'status': 'running',
            'docs': '/test',
            'privacy_policy': '/privacy-policy'
        })
    
    @app.route('/health')
    def health():
        return jsonify({'status': 'healthy'})
    
    return app


def _ensure_db_schema(app):
    """Ensure database schema matches model definitions (auto-migration)"""
    with app.app_context():
        from sqlalchemy import text, inspect as sa_inspect
        from app.extensions import db

        try:
            inspector = sa_inspect(db.engine)
            existing_tables = inspector.get_table_names()

            # Create gyms table if it doesn't exist (needed for gym scoping)
            if 'gyms' not in existing_tables:
                from app.models.gym import Gym
                Gym.__table__.create(db.engine)
                app.logger.info('Auto-migration: created gyms table')

            # Create device_tokens table if it doesn't exist
            if 'device_tokens' not in existing_tables:
                from app.models.device_token import DeviceToken
                DeviceToken.__table__.create(db.engine)
                app.logger.info('Auto-migration: created device_tokens table')

            # Create the regional manager's branch group table if it doesn't exist.
            #
            # This one is load-bearing for every request, not just the new role:
            # User.managed_branches loads eagerly (selectin), so a missing table
            # fails *any* query that touches a user — including login. Without
            # this the deploy is a full outage rather than one broken feature.
            if 'regional_manager_branches' not in existing_tables:
                from app.models.user import regional_manager_branches
                regional_manager_branches.create(db.engine)
                app.logger.info('Auto-migration: created regional_manager_branches table')

            # Staff-to-staff issues (distinct from member complaints).
            if 'issues' not in existing_tables:
                from app.models.issue import Issue
                Issue.__table__.create(db.engine)
                app.logger.info('Auto-migration: created issues table')

            # Add gym_id column to users table if missing
            if 'users' in existing_tables:
                columns = [col['name'] for col in inspector.get_columns('users')]
                if 'gym_id' not in columns:
                    db.session.execute(text(
                        'ALTER TABLE users ADD COLUMN gym_id INTEGER REFERENCES gyms(id)'
                    ))
                    db.session.commit()
                    app.logger.info('Auto-migration: added gym_id column to users table')

            # Add gym_id column to branches table if missing
            if 'branches' in existing_tables:
                columns = [col['name'] for col in inspector.get_columns('branches')]
                if 'gym_id' not in columns:
                    db.session.execute(text(
                        'ALTER TABLE branches ADD COLUMN gym_id INTEGER REFERENCES gyms(id)'
                    ))
                    db.session.commit()
                    app.logger.info('Auto-migration: added gym_id column to branches table')

            if 'transactions' in existing_tables:
                columns = [col['name'] for col in inspector.get_columns('transactions')]
                if 'discount' not in columns:
                    db.session.execute(text(
                        'ALTER TABLE transactions ADD COLUMN discount NUMERIC(10, 2) NOT NULL DEFAULT 0'
                    ))
                    db.session.commit()
                    app.logger.info('Auto-migration: added discount column to transactions table')

            # Add preferred_language column to users table if missing
            if 'users' in existing_tables:
                columns = [col['name'] for col in inspector.get_columns('users')]
                if 'preferred_language' not in columns:
                    db.session.execute(text(
                        'ALTER TABLE users ADD COLUMN preferred_language VARCHAR(5)'
                    ))
                    db.session.commit()
                    app.logger.info('Auto-migration: added preferred_language column to users table')

            # Add preferred_language column to customers table if missing
            if 'customers' in existing_tables:
                columns = [col['name'] for col in inspector.get_columns('customers')]
                if 'preferred_language' not in columns:
                    db.session.execute(text(
                        'ALTER TABLE customers ADD COLUMN preferred_language VARCHAR(5)'
                    ))
                    db.session.commit()
                    app.logger.info('Auto-migration: added preferred_language column to customers table')

            # Add created_by to subscriptions if missing.
            #
            # The model has declared it for a while but no migration ever added
            # it, so databases older than that commit raise
            # "no such column: subscriptions.created_by" on every Subscription
            # read. Backfill attributes each subscription to whoever created its
            # earliest transaction — the signup that opened it — which is what
            # lets /reports/employee-performance report a retention rate.
            if 'subscriptions' in existing_tables:
                columns = [col['name'] for col in inspector.get_columns('subscriptions')]
                if 'created_by' not in columns:
                    db.session.execute(text(
                        'ALTER TABLE subscriptions ADD COLUMN created_by INTEGER REFERENCES users(id)'
                    ))
                    db.session.commit()
                    app.logger.info('Auto-migration: added created_by column to subscriptions table')

                    if 'transactions' in existing_tables:
                        db.session.execute(text('''
                            UPDATE subscriptions
                            SET created_by = (
                                SELECT t.created_by FROM transactions t
                                WHERE t.subscription_id = subscriptions.id
                                  AND t.created_by IS NOT NULL
                                ORDER BY t.created_at ASC, t.id ASC
                                LIMIT 1
                            )
                            WHERE created_by IS NULL
                        '''))
                        db.session.commit()
                        app.logger.info('Auto-migration: backfilled subscriptions.created_by from transactions')

            # Normalise expenses.category to the ExpenseCategory value form.
            #
            # It used to be free text. SQLAlchemy only validates enum strings on
            # read, so any stray value already on disk would raise LookupError
            # and take the money page down — for a column whose whole job is to
            # be grouped and filtered. Anything unrecognised is parked in OTHER:
            # the money is real and still has to land somewhere in the P&L.
            if 'expenses' in existing_tables:
                from app.models.expense import ExpenseCategory
                valid = {c.value for c in ExpenseCategory}
                by_name = {c.name: c.value for c in ExpenseCategory}

                stray = [
                    row[0] for row in db.session.execute(text(
                        'SELECT DISTINCT category FROM expenses WHERE category IS NOT NULL'
                    )).fetchall()
                    if row[0] not in valid
                ]

                for value in stray:
                    text_value = str(value).strip()
                    target = (
                        text_value.lower() if text_value.lower() in valid
                        else by_name.get(text_value.upper(), ExpenseCategory.OTHER.value)
                    )
                    db.session.execute(
                        text('UPDATE expenses SET category = :target WHERE category = :old'),
                        {'target': target, 'old': value},
                    )

                if stray:
                    db.session.commit()
                    app.logger.info(
                        f'Auto-migration: normalised {len(stray)} expense category value(s): {stray}'
                    )

            # Backfill indexes the models declare but that existing (already
            # created) tables predate — complaints.customer_id gets scanned
            # by every "this customer's complaints" lookup, and
            # daily_closings.closed_by by every "this staffer's closings" one.
            if 'complaints' in existing_tables:
                indexed_columns = {
                    col for idx in inspector.get_indexes('complaints') for col in idx['column_names']
                }
                if 'customer_id' not in indexed_columns:
                    db.session.execute(text(
                        'CREATE INDEX ix_complaints_customer_id ON complaints (customer_id)'
                    ))
                    db.session.commit()
                    app.logger.info('Auto-migration: added index on complaints.customer_id')

            if 'daily_closings' in existing_tables:
                indexed_columns = {
                    col for idx in inspector.get_indexes('daily_closings') for col in idx['column_names']
                }
                if 'closed_by' not in indexed_columns:
                    db.session.execute(text(
                        'CREATE INDEX ix_daily_closings_closed_by ON daily_closings (closed_by)'
                    ))
                    db.session.commit()
                    app.logger.info('Auto-migration: added index on daily_closings.closed_by')
        except Exception as e:
            app.logger.warning(f'Schema migration check: {e}')


def register_error_handlers(app):
    """Register error handlers"""
    
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({
            'success': False,
            'error': 'Resource not found'
        }), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500
    
    @app.errorhandler(JWTExtendedException)
    def handle_jwt_exception(error):
        return jsonify({
            'success': False,
            'error': str(error)
        }), 401
    
    @app.errorhandler(HTTPException)
    def handle_http_exception(error):
        return jsonify({
            'success': False,
            'error': error.description
        }), error.code
    
    @app.errorhandler(Exception)
    def handle_exception(error):
        app.logger.error(f'Unhandled exception: {str(error)}')
        return jsonify({
            'success': False,
            'error': 'An unexpected error occurred'
        }), 500


def register_cli_commands(app):
    """Register Flask CLI commands"""
    
    @app.cli.command('init-db')
    def init_db():
        """Initialize database"""
        from app.extensions import db
        db.create_all()
        print('✅ Database initialized successfully!')
    
    @app.cli.command('seed-db')
    def seed_db():
        """Seed database with test data"""
        from seed import seed_database
        seed_database()
        print('✅ Database seeded successfully!')
    
    @app.cli.command('reset-db')
    def reset_db():
        """Reset database (drop all tables and recreate)"""
        from app.extensions import db
        
        response = input('⚠️  This will delete all data. Are you sure? (yes/no): ')
        if response.lower() == 'yes':
            db.drop_all()
            db.create_all()
            print('✅ Database reset successfully!')
        else:
            print('❌ Operation cancelled.')
