"""
Database seeding script - Creates comprehensive, realistic test data
PRODUCTION-QUALITY DATASET for Flutter frontend testing

Features:
- Logical data consistency
- Realistic date distributions  
- Multi-branch performance variance
- Complete user coverage (all roles)
- Supports dashboards, analytics, alerts, leaderboards
- No empty states - all features have data
"""
from datetime import datetime, date, timedelta
import os
import random
from app import create_app
from app.extensions import db
from app.models import (
    User, UserRole, Branch, Customer, Gender,
    Service, ServiceType, Subscription, SubscriptionStatus,
    Transaction, PaymentMethod, TransactionType,
    Expense, ExpenseStatus, Complaint, ComplaintType, ComplaintStatus,
    Fingerprint, FreezeHistory, DailyClosing, EntryLog
)
from app.models.gym import Gym

# Set seed for reproducible results (can be commented out for true randomness)
random.seed(42)

# Single source of truth for the platform-level super admin account, used
# both to create the user and to print its credentials after seeding —
# keeping these in one place avoids the printed credentials drifting out
# of sync with what's actually created (as happened when this account was
# renamed from 'Zyad' to 'powerfit').
SUPER_ADMIN = {
    'username': 'powerfit',
    'password': 'PowerFit2026!',
    'email': 'admin@powerfit.com',
    'full_name': 'PowerFit Admin',
    'phone': '0200000000',
}

# Dedicated, stable account for Google Play review/testing.
GOOGLE_PLAY_TEST_CLIENT = {
    'full_name': 'Google Play Test Client',
    'phone': '01099990000',
    'password': 'GP12TEST',
    'email': 'google.play.tester@example.com',
    'national_id': '2909999000001',
    'branch_index': 0,
}


def generate_temp_password():
    """Generate a random 6-character temporary password (e.g., AB12CD)"""
    import string
    # Format: 2 uppercase + 2 digits + 2 uppercase
    part1 = ''.join(random.choices(string.ascii_uppercase, k=2))
    part2 = ''.join(random.choices(string.digits, k=2))
    part3 = ''.join(random.choices(string.ascii_uppercase, k=2))
    return f"{part1}{part2}{part3}"


def seed_database():
    """Seed the database with production-quality test data"""
    # Check environment - use production on PythonAnywhere, development locally
    import sys
    env = 'production' if any('pythonanywhere' in path.lower() for path in sys.path) else os.getenv('FLASK_ENV', 'development')
    
    print(f"[+] Using environment: {env}")
    app = create_app(env)
    
    with app.app_context():
        print("\n" + "="*70)
        print("[*] SEEDING DATABASE - PRODUCTION-QUALITY TEST DATA")
        print("="*70 + "\n")
        
        # Clear existing data
        print("  ↳ Clearing existing data...")
        db.drop_all()
        db.create_all()
        
        # Create users (super admin + default owner)
        print("  ↳ Creating users...")
        users = create_users([])  # branches not created yet

        # Create gym for the DEFAULT owner only
        print("  ↳ Creating gym for the default owner...")
        default_owner = next(u for u in users if u.role == UserRole.OWNER)
        default_gym = Gym(
            name="Abu Faisal's Gym",
            owner_id=default_owner.id,
            primary_color='#DC2626',
            secondary_color='#EF4444',
            is_setup_complete=True,  # seed data fills it
        )
        db.session.add(default_gym)
        db.session.flush()
        gym_id = default_gym.id

        # Create branches (scoped to default owner's gym)
        print("  ↳ Creating branches...")
        branches = create_branches(gym_id)

        # Back-fill gym_id + branch_id on staff users
        print("  ↳ Assigning staff to gym & branches...")
        assign_staff_to_branches(users, branches, gym_id)
        
        # Create services
        print("  ↳ Creating services...")
        services = create_services()
        
        # Create customers
        print("  ↳ Creating customers...")
        customers = create_customers(branches)
        
        # Create subscriptions
        print("  ↳ Creating subscriptions...")
        subscriptions = create_subscriptions(customers, services, branches, users)
        
        # Create fingerprints (UPDATED: now requires subscriptions)
        print("  ↳ Creating fingerprints...")
        create_fingerprints(customers, subscriptions)
        
        # Create transactions
        print("  ↳ Creating transactions...")
        create_transactions(subscriptions, branches, users)
        
        # Create expenses
        print("  ↳ Creating expenses...")
        create_expenses(branches, users)
        
        # Create complaints
        print("  ↳ Creating complaints...")
        create_complaints(branches, customers)
        
        # Create daily closings
        print("  ↳ Creating daily closings...")
        create_daily_closings(branches, users)
        
        # Create entry logs (attendance records)
        print("  ↳ Creating entry logs...")
        create_entry_logs(customers, subscriptions, branches)
        
        db.session.commit()
        
        # Print comprehensive statistics
        print("\n" + "="*70)
        print("[*] DATABASE STATISTICS - FINAL COUNTS")
        print("="*70)
        print(f"  Branches: {len(branches)}")
        print(f"  Users: {len(users)} (14 total: Owner, 3 Managers, 6 Reception, 2 Central Accountants, 2 Branch Accountants)")
        print(f"  Services: {len(services)}")
        print(f"  Customers: {len(customers)} (150 total: weighted across branches)")
        print(f"  Subscriptions: {len(subscriptions)}")
        print(f"  Transactions: {Transaction.query.count()} (HUNDREDS for comprehensive testing)")
        print(f"  Expenses: {Expense.query.count()}")
        print(f"  Complaints: {Complaint.query.count()} (weighted by branch performance)")
        print(f"  Fingerprints: {Fingerprint.query.count()}")
        print(f"  Freeze History: {FreezeHistory.query.count()}")
        print(f"  Daily Closings: {DailyClosing.query.count()}")
        print(f"  Entry Logs: {EntryLog.query.count()} (2000 attendance records - last 30 days)")
        print("="*70)
        
        print("\n" + "="*70)
        print("[*] TEST ACCOUNTS - ALL ROLES (15 USERS TOTAL)")
        print("="*70)
        print("\n[SUPER ADMIN] SUPER ADMIN ROLE (1):")
        print(f"  Username: {SUPER_ADMIN['username']} | Password: {SUPER_ADMIN['password']}")
        print(f"  Full Name: {SUPER_ADMIN['full_name']}")
        print("  Access: Platform-level - creates and manages gym owners")
        print("\n[OWNER] OWNER ROLE (1):")
        print("  Username: owner | Password: owner123")
        print("  Full Name: Abu Faisal - System Owner")
        print("  Access: Complete system control")
        
        print("\n[MANAGER] BRANCH MANAGER ROLES (3 - one per branch):")
        print("  Username: manager1 | Password: manager123")
        print("  Branch: Dragon Club | Name: Ahmed Khalil")
        print("  ")
        print("  Username: manager2 | Password: manager123")
        print("  Branch: Phoenix Club | Name: Mohamed Rashad")
        print("  ")
        print("  Username: manager3 | Password: manager123")
        print("  Branch: Tiger Club | Name: Khaled Mansour")
        
        print("\n[RECEPTION] FRONT DESK / RECEPTION ROLES (6 - two per branch):")
        print("  Username: reception1 | Password: reception123")
        print("  Branch: Dragon Club | Name: Sara Mohamed")
        print("  ")
        print("  Username: reception2 | Password: reception123")
        print("  Branch: Dragon Club | Name: Fatma Hassan")
        print("  ")
        print("  Username: reception3 | Password: reception123")
        print("  Branch: Phoenix Club | Name: Noha Ibrahim")
        print("  ")
        print("  Username: reception4 | Password: reception123")
        print("  Branch: Phoenix Club | Name: Heba Youssef")
        print("  ")
        print("  Username: reception5 | Password: reception123")
        print("  Branch: Tiger Club | Name: Mariam Ali")
        print("  ")
        print("  Username: reception6 | Password: reception123")
        print("  Branch: Tiger Club | Name: Yasmin Samir")
        
        print("\n[ACCOUNTANT] CENTRAL ACCOUNTANT ROLES (2):")
        print("  Username: accountant1 | Password: accountant123")
        print("  Name: Hassan El-Masry | Access: All branches financial oversight")
        print("  ")
        print("  Username: accountant2 | Password: accountant123")
        print("  Name: Amira Zaki | Access: All branches financial oversight")
        
        print("\n[ACCOUNTANT] BRANCH ACCOUNTANT ROLES (2):")
        print("  Username: baccountant1 | Password: accountant123")
        print("  Branch: Dragon Club | Name: Mona Farid")
        print("  ")
        print("  Username: baccountant2 | Password: accountant123")
        print("  Branch: Phoenix Club | Name: Rania Nabil")

        print("\n[CLIENT] DEDICATED GOOGLE PLAY TEST ACCOUNT:")
        print(f"  Phone: {GOOGLE_PLAY_TEST_CLIENT['phone']} | Password: {GOOGLE_PLAY_TEST_CLIENT['password']}")
        print(f"  Name: {GOOGLE_PLAY_TEST_CLIENT['full_name']} | Branch: {branches[GOOGLE_PLAY_TEST_CLIENT['branch_index']].name}")
        print("  Note: Use this stable account in Google Play Console for reviewer testing")
        
        # Print sample customer credentials
        print("\n[CLIENT] CLIENT APP TEST ACCOUNTS (Sample from 150 customers):")
        sample_customers = Customer.query.limit(5).all()
        for customer in sample_customers:
            print(f"  Phone: {customer.phone} | Password: {customer.temp_password}")
            print(f"  Name: {customer.full_name} | Branch: {customer.branch.name}")
            print(f"  Note: Password must be changed on first login")
            print("  ")
        
        print("\n" + "="*70)
        print("[SUCCESS] DATABASE SEEDED SUCCESSFULLY - READY FOR FLUTTER TESTING")
        print("="*70)
        print("\n[*] Key Features:")
        print("  [+] Hundreds of transactions for leaderboard testing")
        print("  [+] Varied subscription statuses (active, frozen, stopped, expired)")
        print("  [+] Expiring subscriptions for alert testing (48h, 7 days)")
        print("  [+] Freeze history tracking")
        print("  [+] Expense approval workflows with pending items")
        print("  [+] Weighted branch performance (Dragon high, Tiger lower)")
        print("  [+] Daily closing surplus/shortage scenarios")
        print("  [+] Complaint resolution tracking")
        print("  [+] All 150 customers have temporary passwords for first-time login")
        print("  ✓ Complete data for all dashboard analytics")
        print("="*70 + "\n")


def create_branches(gym_id):
    """Create test branches scoped to the default owner's gym"""
    branches = [
        Branch(
            name='Dragon Club',  # High performance
            code='DRG001',
            address='123 Premium Street, Zamalek, Cairo',
            phone='0227350001',
            city='Cairo',
            gym_id=gym_id,
            is_active=True
        ),
        Branch(
            name='Phoenix Club',  # Medium performance
            code='PHX001',
            address='456 Central Avenue, Mohandessin, Giza',
            phone='0233450002',
            city='Giza',
            gym_id=gym_id,
            is_active=True
        ),
        Branch(
            name='Tiger Club',  # Lower performance but growing
            code='TGR001',
            address='789 Beach Road, Alexandria',
            phone='0345670003',
            city='Alexandria',
            gym_id=gym_id,
            is_active=True
        )
    ]
    
    for branch in branches:
        db.session.add(branch)
    
    db.session.flush()
    print(f"  ✓ Created {len(branches)} branches")
    return branches


def create_users(branches):
    """Create test users — branches are assigned later via assign_staff_to_branches."""
    users = []
    
    # ========== SUPER ADMIN (platform-level) ==========
    super_admin = User(
        username=SUPER_ADMIN['username'],
        email=SUPER_ADMIN['email'],
        full_name=SUPER_ADMIN['full_name'],
        phone=SUPER_ADMIN['phone'],
        role=UserRole.SUPER_ADMIN,
        is_active=True
    )
    super_admin.set_password(SUPER_ADMIN['password'])
    users.append(super_admin)

    # ========== OWNER (exactly 1 — the default/test owner) ==========
    owner = User(
        username='owner',
        email='owner@gymchain.com',
        full_name='Abu Faisal - System Owner',
        phone='0201000000',
        role=UserRole.OWNER,
        is_active=True
    )
    owner.set_password('owner123')
    users.append(owner)
    
    # ========== Staff users (branch_id + gym_id set later) ==========
    # BRANCH MANAGERS (1 per branch minimum)
    manager_names = [
        ('Ahmed Khalil', '0201111001'),
        ('Mohamed Rashad', '0201111002'),
        ('Khaled Mansour', '0201111003')
    ]
    for i, (name, phone) in enumerate(manager_names):
        manager = User(
            username=f'manager{i+1}',
            email=f'manager{i+1}@gymchain.com',
            full_name=name,
            phone=phone,
            role=UserRole.BRANCH_MANAGER,
            is_active=True
        )
        manager.set_password('manager123')
        users.append(manager)
    
    # FRONT DESK / RECEPTION (6 total — 2 per branch)
    reception_names = [
        ('Sara Mohamed', '0202220001'),
        ('Fatma Hassan', '0202220002'),
        ('Noha Ibrahim', '0202220003'),
        ('Heba Youssef', '0202220004'),
        ('Mariam Ali', '0202220005'),
        ('Yasmin Samir', '0202220006')
    ]
    for i, (name, phone) in enumerate(reception_names):
        reception = User(
            username=f'reception{i+1}',
            email=f'reception{i+1}@gymchain.com',
            full_name=name,
            phone=phone,
            role=UserRole.FRONT_DESK,
            is_active=True
        )
        reception.set_password('reception123')
        users.append(reception)
    
    # CENTRAL ACCOUNTANTS (2)
    central_accountants = [
        ('Omar Farid', '0203330001', 'accountant1'),
        ('Hassan Nasser', '0203330002', 'accountant2')
    ]
    for name, phone, username in central_accountants:
        accountant = User(
            username=username,
            email=f'{username}@gymchain.com',
            full_name=name,
            phone=phone,
            role=UserRole.CENTRAL_ACCOUNTANT,
            is_active=True
        )
        accountant.set_password('accountant123')
        users.append(accountant)
    
    # BRANCH ACCOUNTANTS (2 — branch assigned later)
    branch_accountant_names = [
        ('Amr Saleh', '0204440001', 'baccountant1'),
        ('Tarek Hamdy', '0204440002', 'baccountant2')
    ]
    for name, phone, username in branch_accountant_names:
        accountant = User(
            username=username,
            email=f'{username}@gymchain.com',
            full_name=name,
            phone=phone,
            role=UserRole.BRANCH_ACCOUNTANT,
            is_active=True
        )
        accountant.set_password('accountant123')
        users.append(accountant)
    
    for user in users:
        db.session.add(user)
    
    db.session.flush()
    print(f"  ✓ Created {len(users)} users")
    print(f"    - Super Admin: 1")
    print(f"    - Owners: 1 (default)")
    print(f"    - Branch Managers: 3")
    print(f"    - Front Desk: 6")
    print(f"    - Central Accountants: 2")
    print(f"    - Branch Accountants: 2")
    return users


def assign_staff_to_branches(users, branches, gym_id):
    """Assign gym_id and branch_id to staff users after branches are created."""
    # Map roles to branches
    managers = [u for u in users if u.role == UserRole.BRANCH_MANAGER]
    receptionists = [u for u in users if u.role == UserRole.FRONT_DESK]
    central_accountants = [u for u in users if u.role == UserRole.CENTRAL_ACCOUNTANT]
    branch_accountants = [u for u in users if u.role == UserRole.BRANCH_ACCOUNTANT]

    # Assign managers: 1 per branch
    for i, mgr in enumerate(managers):
        mgr.branch_id = branches[i % len(branches)].id
        mgr.gym_id = gym_id

    # Assign receptionists: 2 per branch
    for i, rec in enumerate(receptionists):
        rec.branch_id = branches[i // 2 % len(branches)].id
        rec.gym_id = gym_id

    # Central accountants: no branch but belong to the gym
    for acc in central_accountants:
        acc.gym_id = gym_id

    # Branch accountants: assign to first 2 branches
    for i, acc in enumerate(branch_accountants):
        acc.branch_id = branches[i % len(branches)].id
        acc.gym_id = gym_id

    db.session.flush()
    print(f"  ✓ Staff assigned to branches & gym")


def create_services():
    """Create services with varied pricing and types"""
    services = [
        # Gym services
        Service(
            name='Monthly Gym Membership',
            service_type=ServiceType.GYM,
            description='Full gym access for 30 days',
            price=500,
            duration_days=30,
            allowed_days_per_week=7,
            freeze_count_limit=2,
            freeze_max_days=15,
            freeze_is_paid=False,
            is_active=True
        ),
        Service(
            name='Quarterly Gym Membership',
            service_type=ServiceType.GYM,
            description='Full gym access for 90 days',
            price=1350,
            duration_days=90,
            allowed_days_per_week=7,
            freeze_count_limit=3,
            freeze_max_days=30,
            freeze_is_paid=False,
            is_active=True
        ),
        
        # Swimming services
        Service(
            name='Swimming Education - Monthly',
            service_type=ServiceType.SWIMMING_EDUCATION,
            description='Learn to swim - 8 classes per month',
            price=600,
            duration_days=30,
            allowed_days_per_week=2,
            class_limit=8,
            freeze_count_limit=1,
            freeze_max_days=7,
            freeze_is_paid=True,
            freeze_cost=50,
            is_active=True
        ),
        Service(
            name='Swimming Recreation - Monthly',
            service_type=ServiceType.SWIMMING_RECREATION,
            description='Recreational swimming access',
            price=400,
            duration_days=30,
            allowed_days_per_week=7,
            freeze_count_limit=2,
            freeze_max_days=10,
            freeze_is_paid=False,
            is_active=True
        ),
        
        # Karate
        Service(
            name='Karate Classes - Monthly',
            service_type=ServiceType.KARATE,
            description='Karate training - 12 classes per month',
            price=550,
            duration_days=30,
            allowed_days_per_week=3,
            class_limit=12,
            freeze_count_limit=1,
            freeze_max_days=7,
            freeze_is_paid=True,
            freeze_cost=50,
            is_active=True
        ),
        
        # Bundle
        Service(
            name='Gym + Swimming Bundle',
            service_type=ServiceType.BUNDLE,
            description='Full gym and swimming pool access',
            price=800,
            duration_days=30,
            allowed_days_per_week=7,
            freeze_count_limit=2,
            freeze_max_days=15,
            freeze_is_paid=False,
            is_active=True
        )
    ]
    
    for service in services:
        db.session.add(service)
    
    db.session.flush()
    print(f"  ✓ Created {len(services)} services (varied pricing: 400-1350 EGP)")
    return services


def create_customers(branches):
    """Create test customers - WEIGHTED distribution for realistic branch performance"""
    from passlib.hash import pbkdf2_sha256

    customers = []
    
    # Egyptian first names
    male_names = [
        'Ahmed', 'Mohamed', 'Mahmoud', 'Ali', 'Omar', 'Khaled', 'Youssef', 'Amr',
        'Hassan', 'Karim', 'Tarek', 'Sherif', 'Tamer', 'Hossam', 'Essam', 'Walid',
        'Adel', 'Sami', 'Nader', 'Ramy', 'Hany', 'Fady', 'Magdy', 'Samir',
        'Ibrahim', 'Mostafa', 'Osama', 'Wael', 'Hatem', 'Mazen', 'Basel', 'Ziad'
    ]
    
    female_names = [
        'Sara', 'Fatma', 'Mona', 'Noha', 'Heba', 'Mariam', 'Yasmin', 'Nour',
        'Aya', 'Dina', 'Rania', 'Mai', 'Salma', 'Hana', 'Layla', 'Amira',
        'Rana', 'Somaya', 'Nada', 'Hala', 'Iman', 'Reham', 'Nourhan', 'Hadeer',
        'Doaa', 'Eman', 'Maha', 'Reem', 'Shaimaa', 'Nagwa', 'Amal', 'Zeinab'
    ]
    
    last_names = [
        'Mohamed', 'Ali', 'Hassan', 'Ibrahim', 'Mahmoud', 'Youssef', 'Ahmed',
        'Sayed', 'Abdel Rahman', 'El-Sayed', 'Khalil', 'Mostafa', 'Saad',
        'Farid', 'Rashad', 'Nasser', 'Mansour', 'Saleh', 'Gaber', 'Zaki',
        'Ismail', 'Hamdy', 'Fathy', 'Salem', 'Morsy', 'Kamel', 'Shafik'
    ]
    
    # Branch distribution for realistic performance variance
    # Dragon Club (high): 60 customers (40%)
    # Phoenix Club (medium): 55 customers (36.7%)
    # Tiger Club (lower): 35 customers (23.3%)
    branch_distribution = [60, 55, 35]

    # Add one fixed account specifically for Google Play reviewer testing.
    test_branch_idx = GOOGLE_PLAY_TEST_CLIENT['branch_index']
    if 0 <= test_branch_idx < len(branches):
        test_branch = branches[test_branch_idx]
        test_password = GOOGLE_PLAY_TEST_CLIENT['password']
        test_customer = Customer(
            full_name=GOOGLE_PLAY_TEST_CLIENT['full_name'],
            phone=GOOGLE_PLAY_TEST_CLIENT['phone'],
            email=GOOGLE_PLAY_TEST_CLIENT['email'],
            national_id=GOOGLE_PLAY_TEST_CLIENT['national_id'],
            date_of_birth=date(1998, 6, 15),
            gender=Gender.MALE,
            address=f'100 Review Street, {test_branch.city}',
            height=178,
            weight=78,
            health_notes='Google Play reviewer test account',
            branch_id=test_branch.id,
            is_active=True,
            temp_password=test_password,
            password_changed=False
        )
        test_customer.password_hash = pbkdf2_sha256.hash(test_password)
        test_customer.calculate_health_metrics()
        customers.append(test_customer)
        db.session.add(test_customer)

        # Keep total customers at 150 by reducing generated count in that branch.
        branch_distribution[test_branch_idx] = max(0, branch_distribution[test_branch_idx] - 1)
    
    customer_id = 1
    for branch_idx, branch in enumerate(branches):
        customer_count = branch_distribution[branch_idx]
        
        for i in range(customer_count):
            gender = random.choice(['male', 'female'])
            
            if gender == 'male':
                first_name = random.choice(male_names)
            else:
                first_name = random.choice(female_names)
            
            last_name = random.choice(last_names)
            full_name = f'{first_name} {last_name}'
            
            # Generate realistic birth dates (ages 18-55)
            age = random.randint(18, 55)
            birth_year = date.today().year - age
            birth_month = random.randint(1, 12)
            birth_day = random.randint(1, 28)
            dob = date(birth_year, birth_month, birth_day)
            
            # Height: 155-195 cm, Weight: 50-120 kg
            height = random.randint(155, 195)
            weight = random.randint(50, 120)
            
            # Generate temporary password for first login
            temp_password = generate_temp_password()
            
            customer = Customer(
                full_name=full_name,
                phone=f'010{random.randint(10000000, 99999999)}',
                email=f'customer{customer_id}@example.com',
                national_id=f'290{random.randint(1000000000, 9999999999)}',
                date_of_birth=dob,
                gender=Gender(gender),
                address=f'{random.randint(1, 200)} Street, {branch.city}',
                height=height,
                weight=weight,
                health_notes=random.choice([
                    'No health issues',
                    'Previous knee injury',
                    'Back pain - needs special attention',
                    'Asthma - no heavy cardio',
                    'Diabetes - monitor blood sugar',
                    None
                ]),
                branch_id=branch.id,
                is_active=True,
                temp_password=temp_password,
                password_changed=False
            )
            
            # Hash the temp password (don't use set_password() as it clears temp_password)
            customer.password_hash = pbkdf2_sha256.hash(temp_password)
            
            # Calculate health metrics
            customer.calculate_health_metrics()
            
            customers.append(customer)
            db.session.add(customer)
            customer_id += 1
    
    db.session.flush()
    print(f"  ✓ Created {len(customers)} customers")
    print(f"    - Dragon Club: {branch_distribution[0]}")
    print(f"    - Phoenix Club: {branch_distribution[1]}")
    print(f"    - Tiger Club: {branch_distribution[2]}")
    print(f"    - Dedicated Google Play test account: {GOOGLE_PLAY_TEST_CLIENT['phone']}")
    return customers


def create_subscriptions(customers, services, branches, users):
    """Create subscriptions and ensure every seeded client has active access."""
    subscriptions = []
    reception_users = [u for u in users if u.role == UserRole.FRONT_DESK]
    
    # Get customers by branch for weighted performance
    branch_customers = {branch.id: [] for branch in branches}
    for customer in customers:
        branch_customers[customer.branch_id].append(customer)
    
    # Subscription rate per branch (Dragon high, Phoenix medium, Tiger lower)
    subscription_rates = [0.90, 0.82, 0.70]  # 90%, 82%, 70%
    
    renewal_reasons_rejected = [
        'Too expensive',
        'Moving to another city',
        'Not satisfied with service',
        'Joining competitor gym',
        'Financial difficulties',
        'Medical reasons',
        'Taking a break from training'
    ]
    
    stop_reasons = [
        'Customer requested - medical reasons',
        'Customer requested - relocation',
        'Non-payment',
        'Violation of gym rules',
        'Customer dissatisfaction'
    ]
    
    for branch_idx, branch in enumerate(branches):
        branch_cust = branch_customers[branch.id]
        subscription_count = int(len(branch_cust) * subscription_rates[branch_idx])
        
        # Select customers for subscriptions
        subscribed_customers = random.sample(branch_cust, subscription_count)

        # Ensure the Google Play test customer always has an active subscription.
        test_customer = next((c for c in branch_cust if c.phone == GOOGLE_PLAY_TEST_CLIENT['phone']), None)
        if test_customer and test_customer not in subscribed_customers:
            if subscribed_customers:
                subscribed_customers[-1] = test_customer
            else:
                subscribed_customers.append(test_customer)
        
        for customer in subscribed_customers:
            # Get reception user from same branch
            reception = next((u for u in reception_users if u.branch_id == branch.id), reception_users[0])
            
            # Choose service (Dragon prefers premium, Tiger prefers basic)
            if branch_idx == 0:  # Dragon - Premium preferences
                service = random.choice(services) if random.random() > 0.3 else services[-1]  # 70% bundle
            elif branch_idx == 1:  # Phoenix - Mixed
                service = random.choice(services)
            else:  # Tiger - More basic
                service = random.choice(services[:3])
            
            # Subscription age (days since start) - realistic distribution
            days_old = random.choices(
                [random.randint(0, 10), random.randint(11, 25), random.randint(26, 60), random.randint(61, 90)],
                weights=[30, 40, 20, 10],  # More recent subscriptions
                k=1
            )[0]
            
            start_date = date.today() - timedelta(days=days_old)
            end_date = start_date + timedelta(days=service.duration_days)
            
            # Determine realistic status
            days_until_expiry = (end_date - date.today()).days
            
            if days_until_expiry < 0:
                # Expired
                status = SubscriptionStatus.EXPIRED
                freeze_count = 0
                total_frozen = 0
            elif days_until_expiry <= 2:
                # Expiring in 48h - HIGH PRIORITY ALERT
                status = SubscriptionStatus.ACTIVE
                freeze_count = random.randint(0, 1)
                total_frozen = random.randint(0, 5) if freeze_count > 0 else 0
            elif days_until_expiry <= 7:
                # Expiring in week - MEDIUM PRIORITY
                status = SubscriptionStatus.ACTIVE
                freeze_count = random.randint(0, 2)
                total_frozen = random.randint(0, 10) if freeze_count > 0 else 0
            elif random.random() < 0.06:
                # 6% frozen
                status = SubscriptionStatus.FROZEN
                freeze_count = random.randint(1, 2)
                total_frozen = random.randint(3, 14)
            elif random.random() < 0.04:
                # 4% stopped
                status = SubscriptionStatus.STOPPED
                freeze_count = 0
                total_frozen = 0
            else:
                # Active
                status = SubscriptionStatus.ACTIVE
                freeze_count = random.randint(0, 2)
                total_frozen = random.randint(0, 7) if freeze_count > 0 else 0

            if customer.phone == GOOGLE_PLAY_TEST_CLIENT['phone']:
                service = services[0]  # Monthly gym membership for predictable review flow
                days_old = 5
                start_date = date.today() - timedelta(days=days_old)
                end_date = start_date + timedelta(days=service.duration_days)
                status = SubscriptionStatus.ACTIVE
                freeze_count = 0
                total_frozen = 0
            
            subscription = Subscription(
                customer_id=customer.id,
                service_id=service.id,
                branch_id=customer.branch_id,
                start_date=start_date,
                end_date=end_date,
                status=status,
                freeze_count=freeze_count,
                total_frozen_days=total_frozen,
                classes_attended=random.randint(0, service.class_limit) if service.class_limit else 0,
                stop_reason=random.choice(stop_reasons) if status == SubscriptionStatus.STOPPED else None,
                stopped_at=datetime.now() - timedelta(days=random.randint(1, 10)) if status == SubscriptionStatus.STOPPED else None,
                created_by=reception.id
            )
            
            # Assign subscription type and remaining values based on service type
            if service.service_type == ServiceType.GYM:
                # Gym services are coin-based
                subscription.subscription_type = 'coins'
                subscription.total_coins = random.choice([20, 25, 30])  # Random coin package
                # Calculate remaining coins based on subscription age and status
                if status == SubscriptionStatus.EXPIRED:
                    subscription.remaining_coins = 0
                elif status == SubscriptionStatus.STOPPED:
                    subscription.remaining_coins = random.randint(0, subscription.total_coins // 2)
                else:
                    # Active/Frozen: use some coins but not all
                    coins_used = int((days_old / service.duration_days) * subscription.total_coins * random.uniform(0.6, 1.0))
                    subscription.remaining_coins = max(0, subscription.total_coins - coins_used)
            
            elif service.class_limit and service.class_limit > 0:
                # Services with class limits are session-based
                if service.service_type == ServiceType.KARATE:
                    subscription.subscription_type = 'training'
                else:
                    subscription.subscription_type = 'sessions'
                
                subscription.total_sessions = service.class_limit
                # Calculate remaining sessions based on classes_attended
                subscription.remaining_sessions = max(0, service.class_limit - subscription.classes_attended)
                
                if status == SubscriptionStatus.EXPIRED:
                    subscription.remaining_sessions = 0
                elif status == SubscriptionStatus.STOPPED:
                    subscription.remaining_sessions = random.randint(0, service.class_limit // 2)
            
            else:
                # Time-based subscriptions (swimming recreation, bundles)
                subscription.subscription_type = 'time_based'
                subscription.remaining_coins = None
                subscription.total_coins = None
                subscription.remaining_sessions = None
                subscription.total_sessions = None
            
            subscriptions.append(subscription)
            db.session.add(subscription)

    # Ensure every seeded customer has at least one active subscription for client app testing.
    ensured_active_count = 0
    customers_with_active = {
        s.customer_id
        for s in subscriptions
        if s.status == SubscriptionStatus.ACTIVE and (
            s.subscription_type == 'coins' or s.end_date >= date.today()
        )
    }

    default_client_service = services[0]  # Monthly Gym Membership (coin-based)
    for customer in customers:
        if customer.id in customers_with_active:
            continue

        reception = next((u for u in reception_users if u.branch_id == customer.branch_id), None)
        start_date = date.today() - timedelta(days=random.randint(0, 5))
        end_date = start_date + timedelta(days=default_client_service.duration_days)

        fallback_subscription = Subscription(
            customer_id=customer.id,
            service_id=default_client_service.id,
            branch_id=customer.branch_id,
            start_date=start_date,
            end_date=end_date,
            status=SubscriptionStatus.ACTIVE,
            freeze_count=0,
            total_frozen_days=0,
            classes_attended=0,
            created_by=reception.id if reception else None,
        )
        fallback_subscription.subscription_type = 'coins'
        fallback_subscription.total_coins = 30
        fallback_subscription.remaining_coins = random.randint(18, 30)

        subscriptions.append(fallback_subscription)
        db.session.add(fallback_subscription)
        customers_with_active.add(customer.id)
        ensured_active_count += 1
    
    db.session.flush()
    
    # Create freeze history for frozen/previously frozen subscriptions
    freeze_history_count = 0
    for subscription in subscriptions:
        if subscription.freeze_count > 0 and subscription.total_frozen_days > 0:
            for i in range(subscription.freeze_count):
                freeze_start = subscription.start_date + timedelta(days=random.randint(5, 20))
                # Ensure freeze_days is valid
                max_freeze_days = max(1, min(10, subscription.total_frozen_days))
                freeze_days = random.randint(1, max_freeze_days)
                
                freeze = FreezeHistory(
                    subscription_id=subscription.id,
                    freeze_start=freeze_start,
                    freeze_end=freeze_start + timedelta(days=freeze_days),
                    freeze_days=freeze_days,
                    reason=random.choice(['Travel', 'Medical', 'Personal', 'Work commitment']),
                    cost=subscription.service.freeze_cost if subscription.service.freeze_is_paid else 0
                )
                db.session.add(freeze)
                freeze_history_count += 1
    
    db.session.flush()
    
    # Count by status
    active_count = sum(1 for s in subscriptions if s.status == SubscriptionStatus.ACTIVE)
    frozen_count = sum(1 for s in subscriptions if s.status == SubscriptionStatus.FROZEN)
    stopped_count = sum(1 for s in subscriptions if s.status == SubscriptionStatus.STOPPED)
    expired_count = sum(1 for s in subscriptions if s.status == SubscriptionStatus.EXPIRED)
    expiring_48h = sum(1 for s in subscriptions if s.status == SubscriptionStatus.ACTIVE and (s.end_date - date.today()).days <= 2)
    expiring_7d = sum(1 for s in subscriptions if s.status == SubscriptionStatus.ACTIVE and (s.end_date - date.today()).days <= 7)
    
    print(f"  ✓ Created {len(subscriptions)} subscriptions")
    print(f"    - Active: {active_count} (including {expiring_48h} expiring in 48h, {expiring_7d} in 7days)")
    print(f"    - Frozen: {frozen_count}")
    print(f"    - Stopped: {stopped_count}")
    print(f"    - Expired: {expired_count}")
    print(f"    - Added fallback active subscriptions: {ensured_active_count}")
    print(f"    - Freeze history records: {freeze_history_count}")
    
    return subscriptions


def create_fingerprints(customers, subscriptions):
    """Create fingerprints - LINKED to subscription status (active/disabled)"""
    fingerprints = []
    
    # Map customers to their subscriptions
    customer_subscriptions = {}
    for subscription in subscriptions:
        customer_subscriptions[subscription.customer_id] = subscription
    
    # Create fingerprints for 92% of customers
    eligible_customers = random.sample(customers, int(len(customers) * 0.92))
    
    for customer in eligible_customers:
        subscription = customer_subscriptions.get(customer.id)
        
        # Determine if fingerprint should be active based on subscription
        if subscription:
            if subscription.status == SubscriptionStatus.ACTIVE:
                is_active = True  # Active subscription = active fingerprint
            elif subscription.status == SubscriptionStatus.FROZEN:
                is_active = random.random() < 0.3  # 30% still active during freeze
            elif subscription.status == SubscriptionStatus.STOPPED:
                is_active = False  # Stopped subscription = disabled fingerprint
            elif subscription.status == SubscriptionStatus.EXPIRED:
                is_active = random.random() < 0.1  # 10% remain active (grace period)
            else:
                is_active = True
        else:
            # No subscription - 40% have active fingerprints (new registrations)
            is_active = random.random() < 0.4
        
        fingerprint = Fingerprint(
            customer_id=customer.id,
            fingerprint_hash=Fingerprint.generate_fingerprint_hash(
                customer.id,
                f'fingerprint_data_{customer.id}_{random.randint(1000, 9999)}'
            ),
            is_active=is_active
        )
        fingerprints.append(fingerprint)
        db.session.add(fingerprint)
    
    db.session.flush()
    
    active_count = sum(1 for f in fingerprints if f.is_active)
    disabled_count = len(fingerprints) - active_count
    
    print(f"  ✓ Created {len(fingerprints)} fingerprints")
    print(f"    - Active: {active_count}")
    print(f"    - Disabled: {disabled_count}")
    
    return fingerprints


def create_transactions(subscriptions, branches, users):
    """Create transactions - HUNDREDS of realistic transactions for leaderboards"""
    reception_users = [u for u in users if u.role == UserRole.FRONT_DESK]
    transactions = []
    
    def get_payment_method():
        """Realistic payment distribution: 40% cash, 40% network, 20% transfer"""
        rand = random.random()
        if rand < 0.4:
            return PaymentMethod.CASH
        elif rand < 0.8:
            return PaymentMethod.NETWORK
        else:
            return PaymentMethod.TRANSFER
    
    def get_ref_number(payment_method):
        """Generate reference number for non-cash payments"""
        if payment_method == PaymentMethod.CASH:
            return None
        return f'TXN{random.randint(100000, 999999)}'
    
    # === 1. INITIAL SUBSCRIPTION PAYMENTS (one per subscription) ===
    for subscription in subscriptions:
        reception = next((u for u in reception_users if u.branch_id == subscription.branch_id), reception_users[0])
        payment_method = get_payment_method()
        
        transaction = Transaction(
            amount=subscription.service.price,
            payment_method=payment_method,
            transaction_type=TransactionType.SUBSCRIPTION,
            branch_id=subscription.branch_id,
            customer_id=subscription.customer_id,
            subscription_id=subscription.id,
            created_by=reception.id,
            description=f'New subscription: {subscription.service.name}',
            transaction_date=subscription.start_date,
            created_at=datetime.combine(subscription.start_date, datetime.min.time()) + timedelta(hours=random.randint(8, 20), minutes=random.randint(0, 59)),
            reference_number=get_ref_number(payment_method)
        )
        transactions.append(transaction)
        db.session.add(transaction)
    
    # === 2. RENEWAL TRANSACTIONS (35% of subscriptions have renewals) ===
    renewal_count = int(len(subscriptions) * 0.35)
    renewals_created = 0
    for subscription in random.sample(subscriptions, renewal_count):
        reception = next((u for u in reception_users if u.branch_id == subscription.branch_id), reception_users[0])
        
        # Some subscriptions have multiple renewals (history)
        renewal_history = random.choices([1, 2, 3], weights=[60, 30, 10], k=1)[0]
        
        for renewal_num in range(renewal_history):
            payment_method = get_payment_method()
            # Each renewal goes back further in time
            renewal_date = subscription.start_date - timedelta(days=random.randint(30, 90) * (renewal_num + 1))
            
            transaction = Transaction(
                amount=subscription.service.price,
                payment_method=payment_method,
                transaction_type=TransactionType.RENEWAL,
                branch_id=subscription.branch_id,
                customer_id=subscription.customer_id,
                subscription_id=subscription.id,
                created_by=reception.id,
                description=f'Renewal #{renewal_num + 1}: {subscription.service.name}',
                transaction_date=renewal_date,
                created_at=datetime.combine(renewal_date, datetime.min.time()) + timedelta(hours=random.randint(8, 20), minutes=random.randint(0, 59)),
                reference_number=get_ref_number(payment_method)
            )
            transactions.append(transaction)
            db.session.add(transaction)
            renewals_created += 1
    
    # === 3. RENEWAL REJECTIONS (10-15% of customers rejected renewal offers) ===
    # These don't create transactions but help test renewal workflows
    # We simulate by NOT creating renewals for some expired/stopped subscriptions
    
    # === 4. FREEZE PAYMENT TRANSACTIONS ===
    freeze_payments = 0
    for subscription in subscriptions:
        if subscription.freeze_count > 0 and subscription.service.freeze_is_paid:
            reception = next((u for u in reception_users if u.branch_id == subscription.branch_id), reception_users[0])
            
            # Create transaction for each freeze
            for i in range(subscription.freeze_count):
                payment_method = get_payment_method()
                freeze_date = subscription.start_date + timedelta(days=random.randint(5, 25))
                
                transaction = Transaction(
                    amount=subscription.service.freeze_cost,
                    payment_method=payment_method,
                    transaction_type=TransactionType.FREEZE,
                    branch_id=subscription.branch_id,
                    customer_id=subscription.customer_id,
                    subscription_id=subscription.id,
                    created_by=reception.id,
                    description=f'Freeze fee #{i+1}: {subscription.service.name}',
                    transaction_date=freeze_date,
                    created_at=datetime.combine(freeze_date, datetime.min.time()) + timedelta(hours=random.randint(8, 20), minutes=random.randint(0, 59)),
                    reference_number=get_ref_number(payment_method)
                )
                transactions.append(transaction)
                db.session.add(transaction)
                freeze_payments += 1
    
    # === 5. MISCELLANEOUS / OTHER TRANSACTIONS (large volume for revenue) ===
    misc_types = [
        ('Personal training session', 150, 200),
        ('Protein shake', 30, 50),
        ('Gym merchandise - T-shirt', 100, 150),
        ('Gym merchandise - Bottle', 40, 70),
        ('Locker rental - Monthly', 50, 80),
        ('Towel service', 15, 30),
        ('Private class', 180, 250),
        ('Nutritionist consultation', 250, 400),
        ('Fitness assessment', 100, 150),
        ('Body composition analysis', 80, 120),
        ('Sports massage', 200, 300),
        ('Supplement purchase', 150, 350),
        ('Yoga mat purchase', 80, 150),
        ('Resistance bands', 60, 100),
        ('Swimming goggles', 50, 100),
        ('Gym gloves', 70, 120),
        ('Lock purchase', 30, 60)
    ]
    
    # Create 60-90 misc transactions per branch (180-270 total)
    misc_created = 0
    for branch in branches:
        reception = next((u for u in reception_users if u.branch_id == branch.id), reception_users[0])
        
        # Variable count per branch based on performance
        if branch.name == 'Dragon Club':
            misc_count = random.randint(80, 100)  # High performer
        elif branch.name == 'Phoenix Club':
            misc_count = random.randint(65, 85)   # Medium
        else:
            misc_count = random.randint(50, 70)   # Lower
        
        for _ in range(misc_count):
            desc, min_amt, max_amt = random.choice(misc_types)
            amount = random.randint(min_amt, max_amt)
            
            # Spread transactions over last 90 days
            trans_date = date.today() - timedelta(days=random.randint(0, 90))
            
            payment_method = get_payment_method()
            
            # 70% linked to existing customers, 30% walk-ins
            customer_id = None
            if random.random() < 0.7 and subscriptions:
                customer_id = random.choice(subscriptions).customer_id
            
            transaction = Transaction(
                amount=amount,
                payment_method=payment_method,
                transaction_type=TransactionType.OTHER,
                branch_id=branch.id,
                customer_id=customer_id,
                created_by=reception.id,
                description=desc,
                transaction_date=trans_date,
                created_at=datetime.combine(trans_date, datetime.min.time()) + timedelta(hours=random.randint(8, 20), minutes=random.randint(0, 59)),
                reference_number=get_ref_number(payment_method)
            )
            transactions.append(transaction)
            db.session.add(transaction)
            misc_created += 1
    
    db.session.flush()
    
    # === STATISTICS FOR CONSOLE ===
    total = len(transactions)
    by_type = {
        'Subscriptions': sum(1 for t in transactions if t.transaction_type == TransactionType.SUBSCRIPTION),
        'Renewals': sum(1 for t in transactions if t.transaction_type == TransactionType.RENEWAL),
        'Freeze Payments': sum(1 for t in transactions if t.transaction_type == TransactionType.FREEZE),
        'Other/Misc': sum(1 for t in transactions if t.transaction_type == TransactionType.OTHER)
    }
    
    by_payment = {
        'Cash': sum(1 for t in transactions if t.payment_method == PaymentMethod.CASH),
        'Network': sum(1 for t in transactions if t.payment_method == PaymentMethod.NETWORK),
        'Transfer': sum(1 for t in transactions if t.payment_method == PaymentMethod.TRANSFER)
    }
    
    total_revenue = sum(t.amount for t in transactions)
    
    print(f"  ✓ Created {total} transactions (TOTAL REVENUE: {total_revenue:,.0f} EGP)")
    print(f"    By Type: {by_type}")
    print(f"    By Payment: {by_payment}")
    print(f"    - Revenue supports leaderboards & analytics")
    
    return transactions


def create_expenses(branches, users):
    """Create expenses - REALISTIC approval workflows & accountant alerts"""
    managers = [u for u in users if u.role == UserRole.BRANCH_MANAGER]
    central_accountants = [u for u in users if u.role == UserRole.CENTRAL_ACCOUNTANT]
    branch_accountants = [u for u in users if u.role == UserRole.BRANCH_ACCOUNTANT]
    accountants = central_accountants + branch_accountants
    
    expense_templates = [
        ('Equipment Maintenance', 'Treadmill repair and maintenance', 500, 800, 'maintenance'),
        ('Cleaning Supplies', 'Monthly cleaning and sanitation supplies', 150, 300, 'supplies'),
        ('Electricity Bill', 'Monthly electricity consumption', 1200, 2000, 'utilities'),
        ('Water Bill', 'Monthly water usage', 250, 500, 'utilities'),
        ('Equipment Purchase', 'New gym equipment', 1500, 5000, 'equipment'),
        ('Pool Chemicals', 'Chlorine and pool maintenance chemicals', 300, 600, 'supplies'),
        ('Staff Training', 'Professional development and certifications', 800, 1500, 'training'),
        ('Marketing Materials', 'Flyers, banners, and promotional items', 200, 800, 'marketing'),
        ('Internet & Phone', 'Monthly communication bills', 400, 700, 'utilities'),
        ('Security Service', 'Monthly security guard service', 2000, 3000, 'services'),
        ('Insurance Payment', 'Monthly insurance premium', 1500, 2500, 'insurance'),
        ('Repair Work', 'General facility repairs', 300, 1200, 'maintenance'),
        ('AC Maintenance', 'Air conditioning service and repair', 800, 1500, 'maintenance'),
        ('Locker Replacement', 'New lockers for changing room', 2000, 4000, 'equipment'),
        ('Music System', 'Sound system upgrade', 1000, 2000, 'equipment'),
        ('Painting Work', 'Interior painting and decoration', 1500, 3000, 'maintenance'),
        ('Uniform Purchase', 'Staff uniforms', 500, 1000, 'supplies'),
        ('First Aid Supplies', 'Medical supplies and first aid kit', 200, 400, 'supplies'),
        ('Software License', 'Management software annual fee', 1000, 2000, 'software'),
        ('Pest Control', 'Monthly pest control service', 300, 500, 'services'),
        ('Fire Extinguisher Service', 'Annual fire safety inspection', 800, 1200, 'safety'),
        ('Emergency Exit Signs', 'Replace emergency lighting', 600, 1000, 'safety'),
        ('Plumbing Repair', 'Shower and sink repairs', 400, 900, 'maintenance'),
        ('Mirror Replacement', 'Large wall mirrors for training area', 1200, 2000, 'equipment'),
        ('Floor Resurfacing', 'Gym floor maintenance', 2500, 4000, 'maintenance'),
        ('Sound Insulation', 'Noise reduction treatment', 1800, 3000, 'maintenance'),
        ('LED Lighting Upgrade', 'Energy efficient lighting', 1500, 2500, 'equipment'),
        ('Parking Lot Repair', 'Asphalt and marking', 2000, 3500, 'maintenance'),
        ('Sauna Heater Repair', 'Sauna maintenance', 800, 1500, 'equipment'),
        ('Weighing Scale Purchase', 'Digital body analysis scales', 1000, 1800, 'equipment')
    ]
    
    expenses = []
    
    # Create 60-90 expenses across branches over last 90 days
    expense_count = random.randint(60, 90)
    
    for _ in range(expense_count):
        branch = random.choice(branches)
        manager = next((u for u in managers if u.branch_id == branch.id), managers[0])
        
        template = random.choice(expense_templates)
        title, base_desc, min_amount, max_amount, category = template
        
        amount = random.randint(min_amount, max_amount)
        expense_date = date.today() - timedelta(days=random.randint(0, 90))
        days_old = (date.today() - expense_date).days
        
        # Realistic status distribution based on age
        if days_old < 3:
            # Very recent - mostly pending (80%), some fast-tracked approved (20%)
            status = random.choices(
                [ExpenseStatus.PENDING, ExpenseStatus.APPROVED],
                weights=[80, 20],
                k=1
            )[0]
        elif days_old < 7:
            # Recent - 50% pending, 45% approved, 5% rejected
            status = random.choices(
                [ExpenseStatus.PENDING, ExpenseStatus.APPROVED, ExpenseStatus.REJECTED],
                weights=[50, 45, 5],
                k=1
            )[0]
        elif days_old < 15:
            # Medium age - 20% pending, 70% approved, 10% rejected
            status = random.choices(
                [ExpenseStatus.PENDING, ExpenseStatus.APPROVED, ExpenseStatus.REJECTED],
                weights=[20, 70, 10],
                k=1
            )[0]
        else:
            # Old - 5% pending (require action!), 85% approved, 10% rejected
            status = random.choices(
                [ExpenseStatus.PENDING, ExpenseStatus.APPROVED, ExpenseStatus.REJECTED],
                weights=[5, 85, 10],
                k=1
            )[0]
        
        expense = Expense(
            title=title,
            description=f'{base_desc} - {branch.name}',
            amount=amount,
            category=category,
            branch_id=branch.id,
            status=status,
            expense_date=expense_date,
            created_by_id=manager.id
        )
        
        # If reviewed (approved/rejected), add review details
        if status in [ExpenseStatus.APPROVED, ExpenseStatus.REJECTED]:
            reviewer = random.choice(accountants)
            expense.reviewed_by_id = reviewer.id
            expense.reviewed_at = expense_date + timedelta(days=random.randint(1, 7))
            
            if status == ExpenseStatus.APPROVED:
                expense.review_notes = random.choice([
                    'Approved',
                    'Approved - necessary expense',
                    'Approved - within budget',
                    'Approved as per policy',
                    'Approved - urgent requirement',
                    'Approved by central office'
                ])
            else:
                expense.review_notes = random.choice([
                    'Not in budget this month',
                    'Needs more documentation',
                    'Exceeds approval limit',
                    'Duplicate expense',
                    'Requires manager escalation',
                    'Quote too high - negotiate better price',
                    'Insufficient justification'
                ])
        
        expenses.append(expense)
        db.session.add(expense)
    
    db.session.flush()
    
    # Statistics
    pending = sum(1 for e in expenses if e.status == ExpenseStatus.PENDING)
    approved = sum(1 for e in expenses if e.status == ExpenseStatus.APPROVED)
    rejected = sum(1 for e in expenses if e.status == ExpenseStatus.REJECTED)
    pending_old = sum(1 for e in expenses if e.status == ExpenseStatus.PENDING and (date.today() - e.expense_date).days > 7)
    total_amount = sum(e.amount for e in expenses if e.status == ExpenseStatus.APPROVED)
    
    print(f"  ✓ Created {len(expenses)} expenses")
    print(f"    - Pending: {pending} ({pending_old} need urgent review > 7 days old)")
    print(f"    - Approved: {approved} (Total: {total_amount:,.0f} EGP)")
    print(f"    - Rejected: {rejected}")
    
    return expenses


def create_complaints(branches, customers):
    """Create complaints - WEIGHTED by branch performance (Dragon low, Phoenix mid, Tiger high)"""
    complaint_templates = [
        ('Broken Treadmill', 'Treadmill #{} is not working properly', ComplaintType.DEVICE),
        ('Pool Temperature Issue', 'Pool water temperature is {}', ComplaintType.POOL),
        ('Locker Room Cleanliness', 'Locker room needs better cleaning', ComplaintType.CLEANLINESS),
        ('Staff Behavior', 'Staff member was {} during my visit', ComplaintType.SERVICE),
        ('AC Not Working', 'Air conditioning not functioning in {} area', ComplaintType.DEVICE),
        ('Equipment Missing', 'Some gym equipment is missing or unavailable', ComplaintType.DEVICE),
        ('Pool Cleanliness', 'Pool water appears dirty and needs cleaning', ComplaintType.POOL),
        ('Bathroom Condition', 'Bathroom facilities need maintenance', ComplaintType.CLEANLINESS),
        ('Rude Reception', 'Reception staff was unprofessional', ComplaintType.SERVICE),
        ('Shower Issues', 'Shower water pressure is very low', ComplaintType.DEVICE),
        ('Wet Floor', 'Floor is wet and slippery - safety hazard', ComplaintType.CLEANLINESS),
        ('Music Too Loud', 'Music volume is disturbing', ComplaintType.OTHER),
        ('Class Overcrowded', 'Too many people in swimming class', ComplaintType.POOL),
        ('Trainer Absent', 'Scheduled trainer did not show up', ComplaintType.SERVICE),
        ('Parking Problem', 'Not enough parking spaces available', ComplaintType.OTHER),
        ('WiFi Not Working', 'Internet connection is not working', ComplaintType.DEVICE),
        ('Smell in Gym', 'Unpleasant smell in the gym area', ComplaintType.CLEANLINESS),
        ('Wrong Charge', 'I was charged incorrect amount', ComplaintType.SERVICE),
        ('Towel Service', 'No clean towels available', ComplaintType.CLEANLINESS),
        ('Lock Broken', 'My locker lock is broken', ComplaintType.DEVICE),
        ('Sauna Too Hot', 'Sauna temperature dangerously high', ComplaintType.DEVICE),
        ('Mirror Cracked', 'Large mirror in training area is cracked', ComplaintType.DEVICE),
        ('Floor Damage', 'Gym floor has holes and cracks', ComplaintType.OTHER),
        ('Lighting Dim', 'Insufficient lighting in certain areas', ComplaintType.OTHER),
        ('Noise Complaints', 'Weight dropping noise excessive', ComplaintType.OTHER)
    ]
    
    descriptive_words = {
        'temperature': ['too cold', 'too hot', 'not comfortable'],
        'area': ['main gym', 'cardio section', 'weight area', 'group class room'],
        'staff': ['rude', 'unhelpful', 'not attentive', 'unprofessional'],
        'number': ['1', '2', '3', '5', '7', '12']
    }
    
    # Group customers by branch
    branch_customers = {branch.id: [] for branch in branches}
    for customer in customers:
        branch_customers[customer.branch_id].append(customer)
    
    complaints = []
    
    # Weighted complaint counts: Dragon (low quality issues) = 8-12, Phoenix = 15-20, Tiger = 22-28
    complaint_counts_by_branch = [
        (branches[0], random.randint(8, 12)),   # Dragon Club - Best managed
        (branches[1], random.randint(15, 20)),  # Phoenix Club - Medium
        (branches[2], random.randint(22, 28))   # Tiger Club - More issues
    ]
    
    for branch, complaint_count in complaint_counts_by_branch:
        branch_custs = branch_customers[branch.id]
        
        for _ in range(complaint_count):
            template = random.choice(complaint_templates)
            title, desc_template, comp_type = template
            
            # Fill in template with random details
            if '{}' in desc_template:
                if 'temperature' in desc_template.lower():
                    detail = random.choice(descriptive_words['temperature'])
                elif 'area' in desc_template.lower():
                    detail = random.choice(descriptive_words['area'])
                elif 'was {}' in desc_template:
                    detail = random.choice(descriptive_words['staff'])
                elif '#{}'  in desc_template:
                    detail = random.choice(descriptive_words['number'])
                else:
                    detail = 'not satisfactory'
                
                description = desc_template.format(detail)
            else:
                description = desc_template
            
            # Random date within last 60 days
            complaint_date = datetime.now() - timedelta(days=random.randint(0, 60))
            days_old = (datetime.now() - complaint_date).days
            
            # Determine status based on age and branch quality
            # Dragon resolves faster, Tiger slower
            if branch.name == 'Dragon Club':
                # Best performance - fast resolution
                if days_old < 2:
                    status = ComplaintStatus.OPEN if random.random() < 0.5 else ComplaintStatus.IN_PROGRESS
                elif days_old < 5:
                    status = random.choices(
                        [ComplaintStatus.OPEN, ComplaintStatus.IN_PROGRESS, ComplaintStatus.CLOSED],
                        weights=[10, 30, 60],
                        k=1
                    )[0]
                else:
                    status = ComplaintStatus.CLOSED if random.random() < 0.9 else ComplaintStatus.IN_PROGRESS
            elif branch.name == 'Phoenix Club':
                # Medium performance
                if days_old < 3:
                    status = ComplaintStatus.OPEN if random.random() < 0.6 else ComplaintStatus.IN_PROGRESS
                elif days_old < 10:
                    status = random.choices(
                        [ComplaintStatus.OPEN, ComplaintStatus.IN_PROGRESS, ComplaintStatus.CLOSED],
                        weights=[20, 40, 40],
                        k=1
                    )[0]
                else:
                    status = ComplaintStatus.CLOSED if random.random() < 0.75 else ComplaintStatus.IN_PROGRESS
            else:
                # Tiger - slower resolution
                if days_old < 5:
                    status = ComplaintStatus.OPEN if random.random() < 0.7 else ComplaintStatus.IN_PROGRESS
                elif days_old < 15:
                    status = random.choices(
                        [ComplaintStatus.OPEN, ComplaintStatus.IN_PROGRESS, ComplaintStatus.CLOSED],
                        weights=[30, 40, 30],
                        k=1
                    )[0]
                else:
                    status = ComplaintStatus.CLOSED if random.random() < 0.65 else ComplaintStatus.OPEN
            
            # 75% have customer info, 25% anonymous
            customer = random.choice(branch_custs) if branch_custs and random.random() < 0.75 else None
            
            complaint = Complaint(
                title=title,
                description=description,
                complaint_type=comp_type,
                status=status,
                branch_id=branch.id,
                customer_id=customer.id if customer else None,
                customer_name=customer.full_name if customer else f'Anonymous Customer',
                customer_phone=customer.phone if customer else None,
                created_at=complaint_date,
                resolution_notes=random.choice([
                    'Issue resolved',
                    'Equipment repaired',
                    'Staff member trained',
                    'Cleaning schedule updated',
                    'Policy explained to customer',
                    'Compensation provided',
                    'Maintenance completed',
                    'Replacement ordered',
                    'Apology issued'
                ]) if status == ComplaintStatus.CLOSED else None,
                resolved_at=complaint_date + timedelta(days=random.randint(1, 7)) if status == ComplaintStatus.CLOSED else None
            )
            complaints.append(complaint)
            db.session.add(complaint)
    
    db.session.flush()
    
    # Statistics by branch
    by_branch = {}
    for branch in branches:
        branch_comps = [c for c in complaints if c.branch_id == branch.id]
        open_count = sum(1 for c in branch_comps if c.status == ComplaintStatus.OPEN)
        by_branch[branch.name] = f"{len(branch_comps)} total ({open_count} open)"
    
    print(f"  ✓ Created {len(complaints)} complaints")
    print(f"    By Branch: {by_branch}")
    print(f"    - Dragon has fewest (best quality), Tiger has most")
    
    return complaints


def create_daily_closings(branches, users):
    """Create daily closings - SURPLUS/SHORTAGE scenarios for accountant alerts"""
    from app.models.daily_closing import DailyClosing
    from app.models.transaction import Transaction
    from sqlalchemy import func, and_
    
    reception_users = [u for u in users if u.role == UserRole.FRONT_DESK]
    closings = []
    
    # Track alert scenarios
    high_alerts = 0  # Difference > 100 EGP
    medium_alerts = 0  # Difference 50-100 EGP
    
    # Create closings for last 30 days for each branch
    for branch in branches:
        reception = next((u for u in reception_users if u.branch_id == branch.id), reception_users[0])
        
        for days_ago in range(30, 0, -1):
            closing_date = date.today() - timedelta(days=days_ago)
            
            # Calculate actual totals from transactions for that day
            day_transactions = Transaction.query.filter(
                and_(
                    Transaction.branch_id == branch.id,
                    func.date(Transaction.transaction_date) == closing_date
                )
            ).all()
            
            expected_cash = 0
            network_total = 0
            transfer_total = 0
            
            for txn in day_transactions:
                amount = float(txn.amount)
                if txn.payment_method == PaymentMethod.CASH:
                    expected_cash += amount
                elif txn.payment_method == PaymentMethod.NETWORK:
                    network_total += amount
                elif txn.payment_method == PaymentMethod.TRANSFER:
                    transfer_total += amount
            
            # Skip days with no transactions
            if expected_cash == 0 and network_total == 0 and transfer_total == 0:
                continue
            
            # Determine variance for realistic shortage/surplus scenarios
            # Most days: small variance (±0-30)
            # Some days: medium variance (±50-100) - ~15%
            # Few days: high variance (±100-200) - ~5%
            rand = random.random()
            
            if rand < 0.80:
                # 80% - Small variance (normal operations)
                variance = random.randint(-30, 30)
                notes = random.choice([
                    'Normal closing',
                    'All cash accounted',
                    'Busy day',
                    'Regular operations',
                    None
                ])
            elif rand < 0.95:
                # 15% - Medium variance (requires attention)
                variance = random.choice([
                    random.randint(50, 100),    # Surplus
                    random.randint(-100, -50)   # Shortage
                ])
                medium_alerts += 1
                if variance > 0:
                    notes = f'Cash surplus: {variance} EGP - needs verification'
                else:
                    notes = f'Cash shortage: {variance} EGP - requires investigation'
            else:
                # 5% - High variance (URGENT ALERT)
                variance = random.choice([
                    random.randint(100, 200),   # Large surplus
                    random.randint(-200, -100)  # Large shortage
                ])
                high_alerts += 1
                if variance > 0:
                    notes = f'LARGE SURPLUS: {variance} EGP - URGENT: Verify all transactions'
                else:
                    notes = f'LARGE SHORTAGE: {variance} EGP - URGENT: Manager investigation required'
            
            actual_cash = expected_cash + variance
            
            closing = DailyClosing(
                branch_id=branch.id,
                closing_date=closing_date,
                expected_cash=expected_cash,
                actual_cash=actual_cash,
                cash_difference=variance,
                network_total=network_total,
                transfer_total=transfer_total,
                total_revenue=expected_cash + network_total + transfer_total,
                closed_by=reception.id,
                notes=notes,
                created_at=datetime.combine(closing_date, datetime.min.time()) + timedelta(hours=22)
            )
            closings.append(closing)
            db.session.add(closing)
    
    db.session.flush()
    
    # Statistics
    total_closings = len(closings)
    normal_count = total_closings - high_alerts - medium_alerts
    
    print(f"  ✓ Created {total_closings} daily closing records")
    print(f"    - Normal variance: {normal_count} (±30 EGP)")
    print(f"    - Medium alerts: {medium_alerts} (±50-100 EGP)")
    print(f"    - HIGH PRIORITY alerts: {high_alerts} (±100-200 EGP)")
    print(f"    - Accountants have {high_alerts + medium_alerts} items requiring attention")
    
    return closings


def create_entry_logs(customers, subscriptions, branches):
    """Create 2000 entry logs (attendance records) for last 30 days"""
    from app.models.entry_log import EntryLog, EntryType, EntryStatus
    
    entry_logs = []
    today = date.today()
    thirty_days_ago = today - timedelta(days=30)
    
    # Get active/recently active subscriptions
    eligible_subscriptions = [
        s for s in subscriptions 
        if s.status in [SubscriptionStatus.ACTIVE, SubscriptionStatus.FROZEN] 
        or (s.status == SubscriptionStatus.EXPIRED and (today - s.end_date).days < 30)
    ]
    
    if not eligible_subscriptions:
        print("  ⚠ No eligible subscriptions for entry logs")
        return []
    
    # Create 2000 entries over last 30 days
    target_entries = 2000
    entries_created = 0
    
    # Distribution: More entries on recent days, fewer on older days
    for day_offset in range(30):
        entry_date = today - timedelta(days=day_offset)
        
        # More entries on recent days (exponential decay)
        # Recent days: 80-100 entries, older days: 40-60 entries
        if day_offset < 7:
            daily_entries = random.randint(80, 100)
        elif day_offset < 14:
            daily_entries = random.randint(65, 85)
        elif day_offset < 21:
            daily_entries = random.randint(50, 70)
        else:
            daily_entries = random.randint(40, 60)
        
        # Adjust to hit target
        remaining = target_entries - entries_created
        if day_offset == 29:  # Last day
            daily_entries = remaining
        elif remaining < daily_entries:
            daily_entries = remaining
        
        for _ in range(daily_entries):
            if entries_created >= target_entries:
                break
            
            # Pick random active subscription
            subscription = random.choice(eligible_subscriptions)
            customer = subscription.customer
            branch = subscription.branch
            
            # Random time during gym hours (6 AM - 11 PM)
            entry_hour = random.randint(6, 22)
            entry_minute = random.randint(0, 59)
            entry_time = datetime.combine(entry_date, datetime.min.time()) + timedelta(hours=entry_hour, minutes=entry_minute)
            
            # Determine coins/sessions deducted
            coins_deducted = 0
            if subscription.subscription_type == 'coins':
                coins_deducted = 1
            elif subscription.subscription_type in ['sessions', 'training']:
                # For session-based, track in classes_attended not coins_deducted
                coins_deducted = 0
            
            # Determine entry type (mostly QR scan)
            entry_type = random.choices(
                [EntryType.QR_SCAN, EntryType.FINGERPRINT, EntryType.MANUAL],
                weights=[85, 10, 5],
                k=1
            )[0]
            
            entry_log = EntryLog(
                customer_id=customer.id,
                subscription_id=subscription.id,
                branch_id=branch.id,
                entry_time=entry_time,
                entry_type=entry_type,
                entry_status=EntryStatus.APPROVED,
                coins_deducted=coins_deducted,
                validation_token=customer.qr_code if entry_type == EntryType.QR_SCAN else None,
                created_at=entry_time
            )
            
            entry_logs.append(entry_log)
            db.session.add(entry_log)
            entries_created += 1
        
        if entries_created >= target_entries:
            break
    
    db.session.flush()
    
    # Statistics by branch
    branch_stats = {}
    for branch in branches:
        count = sum(1 for e in entry_logs if e.branch_id == branch.id)
        branch_stats[branch.name] = count
    
    print(f"  ✓ Created {len(entry_logs)} entry logs (attendance records)")
    print(f"    - Last 30 days: {len(entry_logs)} check-ins")
    for branch_name, count in branch_stats.items():
        print(f"    - {branch_name}: {count} entries")
    
    return entry_logs


if __name__ == '__main__':
    seed_database()
