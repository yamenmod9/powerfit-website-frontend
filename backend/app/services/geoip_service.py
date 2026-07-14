"""
GeoIP country resolution for region-aware pricing.

Uses a self-hosted MaxMind GeoLite2 Country database (no per-request
external API call, no rate limits, no third-party outage risk on the
pricing path). This is deliberately NOT a live geolocation API — see
README notes in this module for the acquisition/update process.

The database file is NOT bundled with this repo (MaxMind gates it behind
a free account + license key). Until it's placed at GEOIP_DB_PATH, every
lookup returns None and callers fall back to their own default — nothing
here ever raises for a missing/stale database.
"""
import ipaddress
import logging
import os

logger = logging.getLogger(__name__)

# Where the .mmdb file is expected. Override via env var if deployed elsewhere.
GEOIP_DB_PATH = os.getenv(
    'GEOIP_DB_PATH',
    os.path.join(os.path.dirname(__file__), '..', 'static', 'geoip', 'GeoLite2-Country.mmdb'),
)

_reader = None
_reader_load_attempted = False


def _get_reader():
    """Lazily open the MaxMind reader once per process. Returns None (and
    logs a single warning) if the database file isn't present yet — this
    is the expected state until someone downloads and places it."""
    global _reader, _reader_load_attempted

    if _reader is not None:
        return _reader
    if _reader_load_attempted:
        return None

    _reader_load_attempted = True
    try:
        import geoip2.database
        _reader = geoip2.database.Reader(GEOIP_DB_PATH)
        logger.info('GeoIP: loaded GeoLite2 database from %s', GEOIP_DB_PATH)
    except Exception as e:
        logger.warning(
            'GeoIP: database unavailable (%s) — pricing will use the default '
            'region until GeoLite2-Country.mmdb is placed at %s',
            e, GEOIP_DB_PATH,
        )
        _reader = None

    return _reader


def get_client_ip(request):
    """Best-effort client IP extraction.

    Prefers X-Forwarded-For (the original client is the first hop in that
    header) over request.remote_addr, since PythonAnywhere/most hosts sit
    behind a proxy. This is intentionally permissive — a visitor could
    spoof this header to influence which *currency* they see, but that's
    a low-stakes display choice with an always-available manual override,
    not an auth or billing-execution decision.
    """
    forwarded = request.headers.get('X-Forwarded-For', '')
    if forwarded:
        first_ip = forwarded.split(',')[0].strip()
        if first_ip:
            return first_ip
    return request.remote_addr or ''


def is_private_or_local_ip(ip_str):
    """True for loopback/private/link-local addresses (localhost, LAN,
    Docker bridges, etc.) — these have no meaningful geolocation."""
    if not ip_str:
        return True
    try:
        ip = ipaddress.ip_address(ip_str)
    except ValueError:
        return True
    return ip.is_private or ip.is_loopback or ip.is_link_local or ip.is_reserved


def lookup_country(ip_str):
    """Resolve an IP to an ISO 3166-1 alpha-2 country code, or None.

    Returns None (never raises) when: the IP is private/local, the
    database isn't loaded, the IP isn't found, or any other geoip2 error
    occurs — callers are expected to fall back to a sensible default in
    every one of these cases.
    """
    if is_private_or_local_ip(ip_str):
        return None

    reader = _get_reader()
    if reader is None:
        return None

    try:
        response = reader.country(ip_str)
        return response.country.iso_code
    except Exception as e:
        logger.debug('GeoIP: lookup failed for %s (%s)', ip_str, e)
        return None
