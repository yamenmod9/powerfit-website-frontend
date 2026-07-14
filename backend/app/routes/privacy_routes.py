"""
Public Privacy Policy page for app-store compliance.
"""
from flask import Blueprint, Response

privacy_bp = Blueprint('privacy', __name__)


def _privacy_policy_html() -> str:
    """Return a simple static HTML privacy policy page."""
    return """<!doctype html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\" />
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
  <title>Gym Management System - Privacy Policy</title>
  <style>
    body {
      font-family: Arial, Helvetica, sans-serif;
      max-width: 880px;
      margin: 0 auto;
      padding: 24px 16px 40px;
      line-height: 1.6;
      color: #1f2937;
      background: #f9fafb;
    }
    .card {
      background: #ffffff;
      border: 1px solid #e5e7eb;
      border-radius: 12px;
      padding: 24px;
    }
    h1, h2 {
      color: #111827;
      margin-top: 0;
    }
    h2 {
      margin-top: 22px;
      font-size: 1.15rem;
    }
    p, li { font-size: 0.97rem; }
    .muted { color: #6b7280; }
    code {
      background: #f3f4f6;
      border: 1px solid #e5e7eb;
      border-radius: 6px;
      padding: 2px 6px;
    }
  </style>
</head>
<body>
  <div class=\"card\">
    <h1>Privacy Policy</h1>
    <p class=\"muted\">Effective date: 2026-03-16</p>
    <p>
      This Privacy Policy explains how Gym Management System (\"we\", \"us\", \"our\")
      collects, uses, and protects your information when you use our mobile application and services.
    </p>

    <h2>1) Information We Collect</h2>
    <ul>
      <li>Account data such as full name, phone number, and email address.</li>
      <li>Profile and fitness-related data such as age, weight, height, and subscription details.</li>
      <li>Operational data such as branch, attendance/check-ins, and transaction records.</li>
      <li>Device/session data necessary for secure login and notifications.</li>
    </ul>

    <h2>2) How We Use Information</h2>
    <ul>
      <li>To provide gym services, subscriptions, attendance, and support.</li>
      <li>To authenticate users and protect account security.</li>
      <li>To generate analytics, reports, and operational dashboards.</li>
      <li>To communicate service updates and account notifications.</li>
    </ul>

    <h2>3) Data Sharing</h2>
    <p>
      We do not sell personal data. Information may be shared only with authorized staff
      and service providers required to operate the service, or when required by law.
    </p>

    <h2>4) Data Retention</h2>
    <p>
      We retain data for as long as your account is active and as needed for legal,
      accounting, and operational requirements.
    </p>

    <h2>5) Security</h2>
    <p>
      We apply reasonable technical and organizational measures to protect data.
      No method of transmission or storage is completely secure.
    </p>

    <h2>6) Your Rights</h2>
    <p>
      You may request to access, update, or delete your personal information,
      subject to legal obligations and legitimate business requirements.
    </p>

    <h2>7) Children's Privacy</h2>
    <p>
      Our services are not intentionally directed to children without guardian supervision.
    </p>

    <h2>8) Contact Us</h2>
    <p>
      For privacy-related requests, contact the gym administration through the official support channels
      configured for your branch.
    </p>

    <h2>9) Policy Updates</h2>
    <p>
      We may update this policy from time to time. Updates will be reflected on this page.
    </p>

    <p class=\"muted\">
      Public link for Google Play Console: <code>/privacy-policy</code>
    </p>
  </div>
</body>
</html>
"""


@privacy_bp.get('/privacy-policy')
def privacy_policy_page():
    """Public HTML page for Google Play policy URL."""
    return Response(_privacy_policy_html(), mimetype='text/html; charset=utf-8')


@privacy_bp.get('/privacy')
def privacy_policy_short_alias():
    """Short alias for convenience."""
    return Response(_privacy_policy_html(), mimetype='text/html; charset=utf-8')

