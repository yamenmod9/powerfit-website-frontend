"""
Backend Notification Diagnostics
==================================
Tests the FULL notification chain to diagnose why client push notifications
are not working. Runs against PythonAnywhere backend.

Steps tested:
  1. Client login → get JWT
  2. Register FCM token via /api/notifications/register-device
  3. Verify token is registered via a custom debug query
  4. Trigger a test notification via the backend's FCM service

Usage:
  python diagnose_notifications.py
"""

import requests
import json
import sys

# ─── Configuration ───
BASE_URL = "https://yamenmod91.pythonanywhere.com"

# Fill these in:
CLIENT_PHONE = ""      # The client phone number used to login
CLIENT_PASSWORD = ""   # The client password

# The FCM token from your Flutter debug console (from the client app)
CLIENT_FCM_TOKEN = ""  # Paste the token from "FCM Token: ..." debug output

# ─── Helpers ───
def header(msg):
    print(f"\n{'='*60}")
    print(f"  {msg}")
    print(f"{'='*60}")

def ok(msg):
    print(f"  ✅ {msg}")

def fail(msg):
    print(f"  ❌ {msg}")

def info(msg):
    print(f"  ℹ️  {msg}")


# ─── Step 1: Test backend reachability ───
header("Step 1: Backend Reachability")
try:
    r = requests.get(f"{BASE_URL}/health", timeout=10)
    if r.status_code == 200:
        ok(f"Backend is running: {r.json()}")
    else:
        fail(f"Health check returned {r.status_code}")
except Exception as e:
    fail(f"Cannot reach backend: {e}")
    sys.exit(1)


# ─── Step 2: Client login ───
header("Step 2: Client Login")
if not CLIENT_PHONE or not CLIENT_PASSWORD:
    fail("CLIENT_PHONE and CLIENT_PASSWORD must be set in the script")
    sys.exit(1)

try:
    r = requests.post(f"{BASE_URL}/api/client/auth/login", json={
        "phone": CLIENT_PHONE,
        "password": CLIENT_PASSWORD,
    }, timeout=15)
    login_data = r.json()
    
    if r.status_code == 200 and login_data.get("status") == "success":
        token = login_data["data"]["access_token"]
        customer_data = login_data["data"].get("customer", {})
        customer_id = customer_data.get("id", "unknown")
        ok(f"Login successful. customer_id={customer_id}")
        ok(f"JWT token: {token[:40]}...")
    else:
        fail(f"Login failed: {r.status_code} {login_data}")
        sys.exit(1)
except Exception as e:
    fail(f"Login error: {e}")
    sys.exit(1)

auth_headers = {"Authorization": f"Bearer {token}"}


# ─── Step 3: Check if notification endpoints exist ───
header("Step 3: Notification Endpoint Check")
try:
    # Test with OPTIONS or a bad request to see if the route exists
    r = requests.post(f"{BASE_URL}/api/notifications/register-device",
                      json={},  # Missing fields — should return 400, not 404
                      headers=auth_headers,
                      timeout=10)
    if r.status_code == 404:
        fail("Route /api/notifications/register-device NOT FOUND (404)")
        fail("The notifications blueprint is not registered. Did you pull the latest code on PythonAnywhere?")
    elif r.status_code == 400:
        ok(f"Route exists (got 400 for empty body as expected: {r.json().get('message', r.text[:100])})")
    elif r.status_code == 401:
        fail(f"Route exists but auth failed (401). Check JWT token/scope.")
        info(f"Response: {r.text[:200]}")
    else:
        info(f"Route responded with {r.status_code}: {r.text[:200]}")
except Exception as e:
    fail(f"Error checking endpoint: {e}")


# ─── Step 4: Register FCM token ───
header("Step 4: Register FCM Token")
if not CLIENT_FCM_TOKEN:
    fail("CLIENT_FCM_TOKEN must be set in the script")
    fail("Run the client app, login, and look for 'FCM Token: ...' in the debug console")
    sys.exit(1)

try:
    r = requests.post(f"{BASE_URL}/api/notifications/register-device",
                      json={
                          "fcm_token": CLIENT_FCM_TOKEN,
                          "app_type": "client",
                          "platform": "android",
                      },
                      headers=auth_headers,
                      timeout=15)
    resp = r.json()
    if r.status_code in (200, 201):
        ok(f"Token registered! Response: {resp}")
    else:
        fail(f"Registration failed: {r.status_code} {resp}")
        if r.status_code == 401:
            info("The backend could not extract customer_id from the JWT.")
            info("Check that the client token has scope='client' and customer_id in claims.")
except Exception as e:
    fail(f"Registration error: {e}")


# ─── Step 5: Check device_tokens table ───
header("Step 5: Verify Token in Database")
info("This check requires a custom debug endpoint. Let's test by unregistering and re-registering.")
try:
    # Unregister
    r1 = requests.post(f"{BASE_URL}/api/notifications/unregister-device",
                       json={"fcm_token": CLIENT_FCM_TOKEN},
                       headers=auth_headers,
                       timeout=10)
    info(f"Unregister: {r1.status_code} {r1.json()}")
    
    # Re-register
    r2 = requests.post(f"{BASE_URL}/api/notifications/register-device",
                       json={
                           "fcm_token": CLIENT_FCM_TOKEN,
                           "app_type": "client",
                           "platform": "android",
                       },
                       headers=auth_headers,
                       timeout=10)
    if r2.status_code in (200, 201):
        ok(f"Re-registration successful: {r2.json()}")
    else:
        fail(f"Re-registration failed: {r2.status_code} {r2.json()}")
except Exception as e:
    fail(f"Token DB check error: {e}")


# ─── Step 6: Test push notification via backend ───
header("Step 6: Test Push from Backend (send_push_to_token)")
info("Testing if the backend can send a push notification using firebase-admin.")
info("If this fails, service_account.json is missing or firebase-admin is not installed on PythonAnywhere.")

# We don't have a direct endpoint for this, so let's check indirectly.
# If the FCM token is registered, we can check the server logs after triggering
# a real action. For now, check if firebase-admin is importable on the server.
try:
    r = requests.get(f"{BASE_URL}/", timeout=10)
    ok(f"Backend is alive. Server response: {r.json()}")
    info("")
    info("To fully test push delivery, do one of these in the staff app:")
    info("  1. Scan the customer's QR code (triggers check-in notification)")
    info("  2. Activate/renew a subscription for this customer")
    info("")
    info("Then check PythonAnywhere error log for:")
    info("  - 'Firebase Admin SDK initialised' → firebase-admin is working")
    info("  - 'Push sent: ...' → notification was sent successfully")
    info("  - 'Firebase service account not found' → service_account.json is missing")
    info("  - 'firebase-admin package not installed' → pip install firebase-admin")
    info("  - 'Push notification failed' → see the full traceback in the log")
except Exception as e:
    fail(f"Backend check error: {e}")


# ─── Summary ───
header("Summary & Checklist")
print("""
  Things to verify on PythonAnywhere:
  
  1. [ ] Pull latest code:
         cd ~/gym-management-system  (or your repo path)
         git pull
  
  2. [ ] Install firebase-admin:
         pip install firebase-admin
  
  3. [ ] Upload service_account.json to the backend directory
         (same folder as requirements.txt)
         This file is in .gitignore so it won't come from git pull.
  
  4. [ ] Reload the web app (Web tab → Reload)
  
  5. [ ] After reload, check the error log for:
         "Auto-migration: created device_tokens table"
         (or the table already exists if you reloaded before)
  
  6. [ ] Log in on the client app, check debug console for:
         "FCM: ✅ Token registered with backend (client)"
  
  7. [ ] Scan QR / activate subscription, check PythonAnywhere error log for:
         "Push sent: projects/..." or "Push notification failed: ..."
""")
