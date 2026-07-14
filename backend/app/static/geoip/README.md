# GeoLite2 Country database

This directory should contain `GeoLite2-Country.mmdb`, used by
`app/services/geoip_service.py` to resolve a visitor's country from their
IP for region-aware pricing (`GET /api/pricing`).

**This file is intentionally not committed** — MaxMind gates it behind a
free account and license key, so it can't be fetched automatically. Until
it's placed here, `/api/pricing` still works correctly: every lookup
returns `None` and the endpoint falls back to the generic USD default
region (see `geoip_service._get_reader()` — it degrades gracefully, never
raises, for exactly this reason).

## One-time setup

1. Create a free MaxMind account: https://www.maxmind.com/en/geolite2/signup
2. Generate a license key: Account → Manage License Keys
3. Download `GeoLite2-Country.mmdb` either:
   - Manually from the MaxMind portal (Account → Download Databases), or
   - Via their `geoipupdate` CLI tool (recommended if you want a repeatable
     command instead of a manual portal download each time):
     ```
     geoipupdate -f GeoIP.conf
     ```
     with a `GeoIP.conf` containing your `AccountID` and `LicenseKey` and
     `EditionIDs GeoLite2-Country`.
4. Place the resulting `GeoLite2-Country.mmdb` file directly in this
   directory (`backend/app/static/geoip/GeoLite2-Country.mmdb`).
5. Restart the Flask app (or reload the PythonAnywhere web app) — the
   reader is opened lazily on first request, so no other code change is
   needed.

## Keeping it fresh

IP-to-country allocations shift slowly. MaxMind updates GeoLite2 weekly,
but for country-level (not city-level) accuracy, re-downloading every
1–3 months is more than enough — this is a manual, low-urgency task, not
something that needs automation. Set a recurring reminder if you want,
but don't build infrastructure around it.

## Testing without the database

You don't need the real file to develop or test this feature — use the
explicit override instead, which bypasses GeoIP entirely:

```
curl "http://localhost:5000/api/pricing?country=EG"
curl "http://localhost:5000/api/pricing?country=US"
curl "http://localhost:5000/api/pricing?country=FR"
```

See `backend/README.md` (or ask) for testing the IP-detection path itself
via a mocked `X-Forwarded-For` header once the database is in place.
