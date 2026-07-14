"""
Firebase Push Notification Tester
===================================
Tests FCM notifications for all 3 app flavors:
  - superAdmin  (com.example.gym_frontend.superadmin)
  - client      (com.example.gym_frontend.client)
  - staff       (com.example.gym_frontend.staff)   [if used in future]

SETUP:
  1. Install dependency:
       pip install firebase-admin

  2. Download your Firebase service account key:
       Firebase Console → Project Settings → Service Accounts
       → Generate new private key → save as 'service_account.json'
       in the same folder as this script.

  3. Paste the FCM token(s) printed in your Flutter debug console
     into the TOKEN section below.

  4. Run:
       python test_notifications.py
"""

import firebase_admin
from firebase_admin import credentials, messaging
import json
from datetime import datetime

# ─────────────────────────────────────────────
#  CONFIGURE TOKENS HERE
#  Copy tokens from Flutter debug console output:
#  "SuperAdmin FCM Token: ..."  /  "Client FCM Token: ..."
# ─────────────────────────────────────────────
TOKENS = {
    "superAdmin": "efZ7EyrpRPuEMov7Fp0-7U:APA91bEBPd32Y9l_M-ZUyPEBh7NPwlddyktTDXpz5_36scLrdGkJxH0mOYuX4dQLATjFeaK6KJF0JnNLxjqttOspRzZMD0RUvOM4CB6F49DhOETGA8BMZY0",
    "client":     "dFd4JYzFTt6pZ3nLkjwHms:APA91bE-w422qKtW3e9tRHXunz-estAHVH1o_ksS2tdHBFSabbofl3xbe9QquXo7EA1ByU0VFmd3E-DzjnyYWgEXzW8vmO1PWyIOITCom9X15ilq551aOqE",
    "staff":      "e_csv5ciQDGSBmR1Jn8XZz:APA91bH0FHFtHCZGLN-Qq2GaViOU7OqK_esqZQxmBgXIc8KZVcbMGULMiNsejjQbBmwrJl6lbkHn9gGbMV6_sxZtbKkJmiSGqboNvwXLBEiQCW8BcKxIdkU",
}

# Path to your downloaded service account JSON key
SERVICE_ACCOUNT_FILE = "service_account.json"


# ─────────────────────────────────────────────
#  Test notification payloads per app
# ─────────────────────────────────────────────
NOTIFICATIONS = {
    "superAdmin": {
        "title": "🏋️ Platform Admin Test",
        "body":  "Super admin notification is working correctly!",
        "data": {
            "type":   "test",
            "app":    "superAdmin",
            "sentAt": datetime.now().isoformat(),
        },
    },
    "client": {
        "title": "💪 Gym App Test",
        "body":  "Client notification is working correctly!",
        "data": {
            "type":   "test",
            "app":    "client",
            "sentAt": datetime.now().isoformat(),
        },
    },
    "staff": {
        "title": "📋 Staff App Test",
        "body":  "Staff notification is working correctly!",
        "data": {
            "type":   "test",
            "app":    "staff",
            "sentAt": datetime.now().isoformat(),
        },
    },
}


def init_firebase():
    """Initialize Firebase Admin SDK."""
    try:
        cred = credentials.Certificate(SERVICE_ACCOUNT_FILE)
        firebase_admin.initialize_app(cred)
        print(f"✅ Firebase initialized from '{SERVICE_ACCOUNT_FILE}'\n")
    except FileNotFoundError:
        print(f"❌ Service account file not found: '{SERVICE_ACCOUNT_FILE}'")
        print("   Download it from: Firebase Console → Project Settings → Service Accounts")
        raise SystemExit(1)
    except Exception as e:
        print(f"❌ Firebase init error: {e}")
        raise SystemExit(1)


def send_notification(app_name: str, token: str, payload: dict) -> bool:
    """Send a single test notification and return success status."""
    if token.startswith("PASTE_"):
        print(f"⚠️  [{app_name}] Skipped — token not configured.")
        return False

    message = messaging.Message(
        notification=messaging.Notification(
            title=payload["title"],
            body=payload["body"],
        ),
        data=payload["data"],
        android=messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(
                channel_id="default_channel",
                sound="default",
            ),
        ),
        token=token,
    )

    try:
        response = messaging.send(message)
        print(f"✅ [{app_name}] Sent successfully!")
        print(f"   Message ID : {response}")
        print(f"   Title      : {payload['title']}")
        print(f"   Body       : {payload['body']}")
        return True
    except messaging.UnregisteredError:
        print(f"❌ [{app_name}] Token is invalid or app was uninstalled.")
    except messaging.SenderIdMismatchError:
        print(f"❌ [{app_name}] Token belongs to a different Firebase project.")
    except Exception as e:
        print(f"❌ [{app_name}] Failed: {e}")
    return False


def main():
    print("=" * 55)
    print("  Firebase Push Notification Tester")
    print("=" * 55)
    print()

    init_firebase()

    results = {}
    for app_name, token in TOKENS.items():
        print(f"─── Sending to: {app_name} ───")
        payload = NOTIFICATIONS.get(app_name, NOTIFICATIONS["client"])
        results[app_name] = send_notification(app_name, token, payload)
        print()

    # Summary
    print("=" * 55)
    print("  Summary")
    print("=" * 55)
    for app_name, success in results.items():
        status = "✅ Success" if success else "❌ Failed / Skipped"
        print(f"  {app_name:<15} {status}")
    print()


if __name__ == "__main__":
    main()
