"""
Region-aware pricing config and lookup.

Data-driven by design: adding a new fully-priced region (e.g. Saudi
Arabia in SAR) means adding one entry to REGION_PRICING below — no new
branching logic anywhere else in this file or in the route that serves it.

Only Egypt (EG) is finalized right now. Every other country falls back to
DEFAULT_REGION (USD), computed from a single manually-maintained exchange
rate constant — deliberately NOT a live FX API, since EGP is volatile and
prices shown to a visitor shouldn't drift with the market between page
loads. Update USD_TO_EGP_RATE by hand as it meaningfully drifts.
"""

# ─── Manually maintained exchange rate ──────────────────────────────────
# Update this by hand periodically (e.g. quarterly, or after a large EGP
# move). It only affects the computed USD fallback for non-finalized
# regions — it never touches the EG numbers, which are fixed business
# pricing, not a currency conversion.
USD_TO_EGP_RATE = 50.0  # placeholder as of 2026-07 — verify against a live rate before go-live

TRIAL_DAYS = 14
ANNUAL_DISCOUNT_PERCENT = 15

# Tiers eligible for the free trial (Pro and Enterprise are sales-assisted
# / higher-touch, so no self-serve trial).
TRIAL_ELIGIBLE_TIERS = {'starter', 'growth'}


def _round_to_x9(value):
    """Round to the nearest whole number ending in 9 (…19, 29, 59…) — the
    classic SaaS 'clean psychological price' look, never a cents value."""
    if value <= 0:
        return 9
    return max(9, round((value + 1) / 10) * 10 - 1)


# ─── Fully-specified regions ─────────────────────────────────────────────
# Only put a region here once its pricing is a deliberate business
# decision, not a currency conversion. Everything else uses DEFAULT_REGION.
REGION_PRICING = {
    'EG': {
        'currency': 'EGP',
        'symbol': 'ج.م',
        'symbol_position': 'after',  # "749 ج.م", not "ج.م 749"
        'is_finalized': True,
        'starter': 749,
        'growth': 1499,
        'pro': 2999,
        'enterprise_per_branch': 750,
    },
}


def _build_default_region():
    """Compute the USD fallback from the EG numbers via the maintained FX
    rate, rounded to clean sticker prices. Recomputed at import time so a
    USD_TO_EGP_RATE edit takes effect on the next deploy with no other
    code changes."""
    eg = REGION_PRICING['EG']
    return {
        'currency': 'USD',
        'symbol': '$',
        'symbol_position': 'before',  # "$29", not "29 $"
        'is_finalized': False,
        'starter': _round_to_x9(eg['starter'] / USD_TO_EGP_RATE),
        'growth': _round_to_x9(eg['growth'] / USD_TO_EGP_RATE),
        'pro': _round_to_x9(eg['pro'] / USD_TO_EGP_RATE),
        'enterprise_per_branch': _round_to_x9(eg['enterprise_per_branch'] / USD_TO_EGP_RATE),
    }


DEFAULT_REGION = _build_default_region()

DISCLAIMER_NON_FINALIZED = (
    'Prices shown in USD — contact us for local currency options'
)


def get_region_pricing(country_code):
    """Look up the pricing region for a country code (or None), always
    returning a usable dict — never raises, never returns None. Unknown
    or missing country codes fall back to DEFAULT_REGION."""
    if country_code:
        region = REGION_PRICING.get(country_code.upper())
        if region:
            return dict(region)
    return dict(DEFAULT_REGION)


def build_pricing_response(country_code, resolved_by):
    """Assemble the full /api/pricing payload for a resolved country.

    `resolved_by` is one of 'override' | 'geoip' | 'default' — purely
    informational, so the frontend can show e.g. "Detected: Egypt" vs
    "Showing: Egypt (your choice)" if it wants to.
    """
    region = get_region_pricing(country_code)
    discount_factor = 1 - (ANNUAL_DISCOUNT_PERCENT / 100)

    tiers = {}
    for tier in ('starter', 'growth', 'pro'):
        monthly = region[tier]
        tiers[tier] = {
            'monthly': monthly,
            'annual_monthly_equivalent': round(monthly * discount_factor),
            'annual_total': round(monthly * 12 * discount_factor),
            'trial_eligible': tier in TRIAL_ELIGIBLE_TIERS,
        }

    return {
        'success': True,
        # None only when the visitor is on a public IP we genuinely
        # couldn't resolve (GeoIP unavailable/failed) — currency still
        # correctly falls back to DEFAULT_REGION (USD) via get_region_pricing.
        'country': country_code,
        'resolved_by': resolved_by,
        'currency': region['currency'],
        'symbol': region['symbol'],
        'symbol_position': region['symbol_position'],
        'is_finalized': region['is_finalized'],
        'trial_days': TRIAL_DAYS,
        'annual_discount_percent': ANNUAL_DISCOUNT_PERCENT,
        'tiers': tiers,
        'enterprise': {
            'contact_sales': True,
            'per_branch_from': region['enterprise_per_branch'],
        },
        'disclaimer': None if region['is_finalized'] else DISCLAIMER_NON_FINALIZED,
    }
