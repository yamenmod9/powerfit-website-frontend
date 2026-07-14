"""
Utility functions initialization
"""
from .decorators import (
    role_required,
    branch_access_required,
    get_current_user,
    get_current_gym_id,
    paginate,
    format_pagination_response,
    success_response,
    error_response
)

from .helpers import (
    calculate_branch_revenue,
    get_expiring_subscriptions,
    get_daily_transactions_summary,
    get_pending_expenses,
    get_open_complaints,
    get_active_customers_count,
    compare_branches_performance,
    get_staff_performance,
    validate_subscription_dates,
    auto_expire_subscriptions
)

from .client_auth import (
    client_token_required,
    get_current_client,
    create_client_token,
    staff_token_required
)

__all__ = [
    'role_required',
    'branch_access_required',
    'get_current_user',
    'get_current_gym_id',
    'paginate',
    'format_pagination_response',
    'success_response',
    'error_response',
    'calculate_branch_revenue',
    'get_expiring_subscriptions',
    'get_daily_transactions_summary',
    'get_pending_expenses',
    'get_open_complaints',
    'get_active_customers_count',
    'compare_branches_performance',
    'get_staff_performance',
    'validate_subscription_dates',
    'auto_expire_subscriptions',
    'client_token_required',
    'get_current_client',
    'create_client_token',
    'staff_token_required'
]
