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
