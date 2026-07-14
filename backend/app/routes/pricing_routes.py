"""
Public, unauthenticated region-aware pricing lookup for the marketing site.
"""
from flask import Blueprint, jsonify, request

from app.services.geoip_service import get_client_ip, is_private_or_local_ip, lookup_country
from app.services.pricing_service import build_pricing_response

pricing_bp = Blueprint('pricing', __name__, url_prefix='/api/pricing')


def _resolve_country():
    """Decide which country's pricing to show, in priority order:

    1. Explicit ?country=XX query param — manual override always wins
       (this is also how the frontend re-requests after a user picks a
       region from the switcher, and how you test locally without
       spoofing headers).
    2. Private/local IP (localhost, LAN, Docker) — assume local
       development and default to Egypt/EGP rather than an anonymous
       USD placeholder or an error.
    3. GeoIP lookup on the resolved client IP.
    4. Unresolvable public IP (database missing/stale, lookup failure) —
       leave country as None; pricing_service falls back to the generic
       USD default region for this.

    Returns (country_code_or_None, resolved_by) where resolved_by is one
    of 'override' | 'local_dev_default' | 'geoip' | 'unresolved'.
    """
    override = request.args.get('country', '').strip().upper()
    if override:
        return override, 'override'

    client_ip = get_client_ip(request)

    if is_private_or_local_ip(client_ip):
        return 'EG', 'local_dev_default'

    country = lookup_country(client_ip)
    if country:
        return country, 'geoip'

    return None, 'unresolved'


@pricing_bp.route('', methods=['GET'])
def get_pricing():
    """GET /api/pricing[?country=XX]

    Returns the currency + tier prices for the visitor's detected (or
    explicitly overridden) region. Never errors on a bad/unknown country
    code or a failed geolocation — always returns a usable USD or EGP
    payload.
    """
    country_code, resolved_by = _resolve_country()
    payload = build_pricing_response(country_code, resolved_by)
    return jsonify(payload), 200
