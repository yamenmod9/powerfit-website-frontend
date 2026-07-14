"""
Routes initialization - Register all blueprints
"""
from .auth_routes import auth_bp
from .users_routes import users_bp
from .branches_routes import branches_bp
from .customers_routes import customers_bp
from .services_routes import services_bp
from .subscriptions_routes import subscriptions_bp
from .transactions_routes import transactions_bp
from .expenses_routes import expenses_bp
from .complaints_routes import complaints_bp
from .fingerprints_routes import fingerprints_bp
from .dashboards_routes import dashboards_bp
from .daily_closing_routes import daily_closing_bp
from .test_routes import test_bp
from .debug_routes import debug_bp
from .client_auth_routes import client_auth_bp, client_compat_bp
from .client_routes import client_bp
from .validation_routes import validation_bp

# New Flutter-compatible routes
from .qr_routes import qr_bp
from .payments_routes import payments_bp
from .reports_routes import reports_bp
from .alerts_routes import alerts_bp
from .finance_routes import finance_bp
from .entry_logs_routes import entry_logs_bp
from .attendance_routes import attendance_bp
from .gyms_routes import gyms_bp
from .seed_trigger import seed_trigger_bp
from .notifications_routes import notifications_bp
from .privacy_routes import privacy_bp
from .pricing_routes import pricing_bp


def register_blueprints(app):
    """Register all application blueprints"""
    app.register_blueprint(auth_bp)
    app.register_blueprint(users_bp)
    app.register_blueprint(branches_bp)
    app.register_blueprint(customers_bp)
    app.register_blueprint(services_bp)
    app.register_blueprint(subscriptions_bp)
    app.register_blueprint(transactions_bp)
    app.register_blueprint(expenses_bp)
    app.register_blueprint(complaints_bp)
    app.register_blueprint(fingerprints_bp)
    app.register_blueprint(dashboards_bp)
    app.register_blueprint(daily_closing_bp)
    app.register_blueprint(test_bp)
    app.register_blueprint(debug_bp)
    
    # Client-facing routes
    app.register_blueprint(client_auth_bp)
    app.register_blueprint(client_compat_bp)
    app.register_blueprint(client_bp)
    app.register_blueprint(validation_bp)
    
    # Flutter-compatible alias routes
    app.register_blueprint(qr_bp)
    app.register_blueprint(payments_bp)
    app.register_blueprint(reports_bp)
    app.register_blueprint(alerts_bp)
    app.register_blueprint(finance_bp)
    app.register_blueprint(entry_logs_bp)
    app.register_blueprint(attendance_bp)
    app.register_blueprint(gyms_bp)
    app.register_blueprint(seed_trigger_bp)
    app.register_blueprint(notifications_bp)
    app.register_blueprint(privacy_bp)
    app.register_blueprint(pricing_bp)
