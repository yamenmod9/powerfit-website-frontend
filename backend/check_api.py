import requests
import json

BASE = "http://localhost:5000"

# Login
r = requests.post(f"{BASE}/api/auth/login", json={"username": "owner1", "password": "Password123!"})
print("Login status:", r.status_code)
print("Login response:", r.text[:200])

if r.status_code == 200:
    data = r.json()
    token = data.get("access_token")
    print("Token:", token[:30] if token else "NONE")

    if token:
        headers = {"Authorization": f"Bearer {token}"}

        # Check branches
        r2 = requests.get(f"{BASE}/api/branches", headers=headers)
        print("\n/api/branches status:", r2.status_code)
        print("/api/branches response:", json.dumps(r2.json(), indent=2)[:500])

        # Check reports
        r3 = requests.get(f"{BASE}/api/reports/branch-comparison", headers=headers)
        print("\n/api/reports/branch-comparison status:", r3.status_code)
        print("Response:", json.dumps(r3.json(), indent=2)[:500])

        # Check employees
        r4 = requests.get(f"{BASE}/api/reports/employee-performance", headers=headers)
        print("\n/api/reports/employee-performance status:", r4.status_code)
        print("Response:", json.dumps(r4.json(), indent=2)[:500])

        # Check /api/users
        r5 = requests.get(f"{BASE}/api/users", headers=headers)
        print("\n/api/users status:", r5.status_code)
        print("Response:", r5.text[:300])

        # Check finance
        r6 = requests.get(f"{BASE}/api/finance/expenses", headers=headers)
        print("\n/api/finance/expenses status:", r6.status_code)
        print("Response:", r6.text[:300])

