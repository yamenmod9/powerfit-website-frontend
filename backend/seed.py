"""
Database seeding script — production-quality test data.

Shaped so every feature in the product has something real to show, and so the
staff hierarchy can actually be *tested* rather than just represented:

  super_admin > owner > regional_manager > branch_manager > accountant > front_desk

Three gyms exist on purpose. One is the main test gym (6 branches split into two
regions, so a regional manager's scope is provably narrower than the owner's and
wider than a branch manager's). A second gym proves cross-gym isolation — its
data must never appear in the first gym's dashboards, and only the super admin
sees both. A third sits setup-incomplete and deactivated to exercise the owner
setup wizard and the super admin's activate/deactivate control.

Money data spans ~8 months so the daily/weekly/monthly revenue trend has points
in every bucket, and expenses carry the full category chart (salaries and rent
dominate, as they do in a real P&L) rather than only ad-hoc spending.
"""
from datetime import datetime, date, timedelta
import os
import random
import string
import sys

from app import create_app
from app.extensions import db
from app.models import (
    User, UserRole, Branch, Customer, Gender,
    Service, ServiceType, Subscription, SubscriptionStatus,
    Transaction, PaymentMethod, TransactionType,
    Expense, ExpenseStatus, Complaint, ComplaintType, ComplaintStatus,
    Fingerprint, FreezeHistory, DailyClosing, EntryLog
)
from app.models.entry_log import EntryType, EntryStatus
from app.models.expense import ExpenseCategory
from app.models.gym import Gym

# Reproducible datasets — same seed, same database, so a bug found today is
# still there tomorrow.
random.seed(42)

# How far back money data reaches. The monthly revenue trend shows 6 buckets by
# default; 8 months of history means none of them are empty.
HISTORY_DAYS = 240

# Single source of truth for the platform-level super admin account, used both
# to create the user and to print its credentials after seeding — keeping these
# in one place avoids the printed credentials drifting out of sync with what's
# actually created.
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
    'gym_key': 'powerfit',
    'branch_code': 'DRG001',
}

# ─────────────────────────────────────────────────────────────────────────────
# GYM SPECIFICATIONS
#
# 'perf' is the branch's performance multiplier — it drives customer count,
# subscription take-up, transaction volume and complaint load together, so a
# branch that looks strong on the leaderboard is strong for consistent reasons.
# ─────────────────────────────────────────────────────────────────────────────

GYM_SPECS = [
    {
        'key': 'powerfit',
        'name': 'PowerFit Elite',
        'primary_color': '#DC2626',
        'secondary_color': '#EF4444',
        'is_setup_complete': True,
        'is_active': True,
        'email_domain': 'gymchain.com',
        'owner': {
            'username': 'owner',
            'password': 'owner123',
            'full_name': 'Abu Faisal - System Owner',
            'phone': '0201000000',
            'email': 'owner@gymchain.com',
        },
        'branches': [
            {'name': 'Dragon Club', 'code': 'DRG001', 'city': 'Cairo',
             'address': '123 Premium Street, Zamalek, Cairo', 'phone': '0227350001',
             'perf': 1.00, 'customers': 45, 'region': 'cairo'},
            {'name': 'Phoenix Club', 'code': 'PHX001', 'city': 'Giza',
             'address': '456 Central Avenue, Mohandessin, Giza', 'phone': '0233450002',
             'perf': 0.80, 'customers': 38, 'region': 'cairo'},
            {'name': 'Falcon Club', 'code': 'FLC001', 'city': 'Cairo',
             'address': '78 Abbas El-Akkad, Nasr City, Cairo', 'phone': '0224010003',
             'perf': 0.62, 'customers': 28, 'region': 'cairo'},
            {'name': 'Tiger Club', 'code': 'TGR001', 'city': 'Alexandria',
             'address': '789 Beach Road, Alexandria', 'phone': '0345670004',
             'perf': 0.55, 'customers': 28, 'region': 'coastal'},
            {'name': 'Shark Club', 'code': 'SHK001', 'city': 'North Coast',
             'address': 'Km 84 Sahel Road, North Coast', 'phone': '0465120005',
             'perf': 0.45, 'customers': 22, 'region': 'coastal'},
            {'name': 'Lion Club', 'code': 'LON001', 'city': 'Port Said',
             'address': '12 El-Gomhoreya Street, Port Said', 'phone': '0663330006',
             'perf': 0.30, 'customers': 14, 'region': 'coastal'},
        ],
        # Regional managers own a *group* of branches — the whole point of the role.
        'regions': [
            {'username': 'regional1', 'password': 'regional123',
             'full_name': 'Yousef Abdel Aziz', 'phone': '0201500001',
             'label': 'Cairo & Giza Region', 'branch_codes': ['DRG001', 'PHX001', 'FLC001']},
            {'username': 'regional2', 'password': 'regional123',
             'full_name': 'Nadia Shoukry', 'phone': '0201500002',
             'label': 'Coastal Region', 'branch_codes': ['TGR001', 'SHK001', 'LON001']},
        ],
        # One branch manager per branch.
        'managers': [
            ('manager1', 'Ahmed Khalil', '0201111001', 'DRG001'),
            ('manager2', 'Mohamed Rashad', '0201111002', 'PHX001'),
            ('manager3', 'Khaled Mansour', '0201111003', 'FLC001'),
            ('manager4', 'Sherif Lotfy', '0201111004', 'TGR001'),
            ('manager5', 'Hossam Badawy', '0201111005', 'SHK001'),
            ('manager6', 'Mazen Fouad', '0201111006', 'LON001'),
        ],
        'central_accountants': [
            ('accountant1', 'Omar Farid', '0203330001'),
            ('accountant2', 'Hassan Nasser', '0203330002'),
        ],
        # Regional accountants mirror the regional managers' split: full money
        # control over a branch group, nothing outside it.
        'regional_accountants': [
            {'username': 'raccountant1', 'full_name': 'Injy Sabbour', 'phone': '0205550001',
             'label': 'Cairo & Giza Region', 'branch_codes': ['DRG001', 'PHX001', 'FLC001']},
            {'username': 'raccountant2', 'full_name': 'Waleed Hegazy', 'phone': '0205550002',
             'label': 'Coastal Region', 'branch_codes': ['TGR001', 'SHK001', 'LON001']},
        ],
        'branch_accountants': [
            ('baccountant1', 'Amr Saleh', '0204440001', 'DRG001'),
            ('baccountant2', 'Tarek Hamdy', '0204440002', 'PHX001'),
            ('baccountant3', 'Mona Farid', '0204440003', 'TGR001'),
        ],
        # Every branch needs its own front desk — transactions, closings and
        # check-ins are all attributed to one, and borrowing another branch's
        # would silently corrupt the per-staff leaderboards.
        'reception': [
            ('reception1', 'Sara Mohamed', '0202220001', 'DRG001', True),
            ('reception2', 'Fatma Hassan', '0202220002', 'DRG001', True),
            ('reception3', 'Noha Ibrahim', '0202220003', 'PHX001', True),
            ('reception4', 'Heba Youssef', '0202220004', 'PHX001', True),
            ('reception5', 'Mariam Ali', '0202220005', 'FLC001', True),
            ('reception6', 'Yasmin Samir', '0202220006', 'TGR001', True),
            ('reception7', 'Rania Nabil', '0202220007', 'SHK001', True),
            ('reception8', 'Dina Ashraf', '0202220008', 'LON001', True),
            # Deactivated on purpose: the staff lists render an "inactive" badge
            # and this is the only row that proves it.
            ('reception9', 'Karim Adel (Former)', '0202220009', 'DRG001', False),
        ],
    },
    {
        'key': 'irontemple',
        'name': 'Iron Temple Fitness',
        'primary_color': '#2563EB',
        'secondary_color': '#3B82F6',
        'is_setup_complete': True,
        'is_active': True,
        'email_domain': 'irontemple.com',
        # A second, fully-working gym. Nothing here may ever surface in
        # PowerFit's dashboards — that isolation is what this gym tests.
        'owner': {
            'username': 'owner2',
            'password': 'owner123',
            'full_name': 'Sameh Darwish - Iron Temple Owner',
            'phone': '0201000002',
            'email': 'owner@irontemple.com',
        },
        'branches': [
            {'name': 'Iron Temple Downtown', 'code': 'ITD001', 'city': 'Cairo',
             'address': '9 Talaat Harb Street, Downtown, Cairo', 'phone': '0225770001',
             'perf': 0.70, 'customers': 20, 'region': 'main'},
            {'name': 'Iron Temple Maadi', 'code': 'ITM001', 'city': 'Cairo',
             'address': '55 Road 9, Maadi, Cairo', 'phone': '0225770002',
             'perf': 0.40, 'customers': 12, 'region': 'main', 'is_active': False},
        ],
        'regions': [
            {'username': 'regional3', 'password': 'regional123',
             'full_name': 'Laila Mounir', 'phone': '0201500003',
             'label': 'Iron Temple Region', 'branch_codes': ['ITD001', 'ITM001']},
        ],
        'managers': [
            ('it_manager1', 'Bassem Ragab', '0201112001', 'ITD001'),
            ('it_manager2', 'Ehab Sultan', '0201112002', 'ITM001'),
        ],
        'central_accountants': [
            ('it_accountant1', 'Nourhan Gamal', '0203331001'),
        ],
        'regional_accountants': [],
        'branch_accountants': [],
        'reception': [
            ('it_reception1', 'Salma Wagdy', '0202221001', 'ITD001', True),
            ('it_reception2', 'Menna Tarek', '0202221002', 'ITM001', True),
        ],
    },
    {
        'key': 'aqualife',
        'name': 'AquaLife Wellness',
        'primary_color': '#0891B2',
        'secondary_color': '#06B6D4',
        # Deliberately unfinished and switched off: logging in as this owner
        # lands in the setup wizard, and the super admin's gym list is the only
        # place this gym can be reactivated from.
        'is_setup_complete': False,
        'is_active': False,
        'email_domain': 'aqualife.com',
        'owner': {
            'username': 'owner3',
            'password': 'owner123',
            'full_name': 'Hoda Serry - AquaLife Owner',
            'phone': '0201000003',
            'email': 'owner@aqualife.com',
        },
        'branches': [
            {'name': 'AquaLife Sheikh Zayed', 'code': 'AQZ001', 'city': 'Giza',
             'address': '3 Beverly Hills, Sheikh Zayed, Giza', 'phone': '0238500001',
             'perf': 0.35, 'customers': 8, 'region': 'main'},
        ],
        'regions': [],
        'managers': [
            ('aq_manager1', 'Ziad Helmy', '0201113001', 'AQZ001'),
        ],
        'central_accountants': [],
        'regional_accountants': [],
        'branch_accountants': [],
        'reception': [
            ('aq_reception1', 'Farida Emad', '0202222001', 'AQZ001', True),
        ],
    },
]


# ─────────────────────────────────────────────────────────────────────────────
# NAME POOLS
# ─────────────────────────────────────────────────────────────────────────────

MALE_NAMES = [
    'Ahmed', 'Mohamed', 'Mahmoud', 'Ali', 'Omar', 'Khaled', 'Youssef', 'Amr',
    'Hassan', 'Karim', 'Tarek', 'Sherif', 'Tamer', 'Hossam', 'Essam', 'Walid',
    'Adel', 'Sami', 'Nader', 'Ramy', 'Hany', 'Fady', 'Magdy', 'Samir',
    'Ibrahim', 'Mostafa', 'Osama', 'Wael', 'Hatem', 'Mazen', 'Basel', 'Ziad',
]

FEMALE_NAMES = [
    'Sara', 'Fatma', 'Mona', 'Noha', 'Heba', 'Mariam', 'Yasmin', 'Nour',
    'Aya', 'Dina', 'Rania', 'Mai', 'Salma', 'Hana', 'Layla', 'Amira',
    'Rana', 'Somaya', 'Nada', 'Hala', 'Iman', 'Reham', 'Nourhan', 'Hadeer',
    'Doaa', 'Eman', 'Maha', 'Reem', 'Shaimaa', 'Nagwa', 'Amal', 'Zeinab',
]

LAST_NAMES = [
    'Mohamed', 'Ali', 'Hassan', 'Ibrahim', 'Mahmoud', 'Youssef', 'Ahmed',
    'Sayed', 'Abdel Rahman', 'El-Sayed', 'Khalil', 'Mostafa', 'Saad',
    'Farid', 'Rashad', 'Nasser', 'Mansour', 'Saleh', 'Gaber', 'Zaki',
    'Ismail', 'Hamdy', 'Fathy', 'Salem', 'Morsy', 'Kamel', 'Shafik',
]


def generate_temp_password():
    """Generate a random 6-character temporary password (e.g., AB12CD)."""
    part1 = ''.join(random.choices(string.ascii_uppercase, k=2))
    part2 = ''.join(random.choices(string.digits, k=2))
    part3 = ''.join(random.choices(string.ascii_uppercase, k=2))
    return f'{part1}{part2}{part3}'


def payment_method():
    """Realistic payment split: 40% cash, 40% network, 20% transfer."""
    rand = random.random()
    if rand < 0.40:
        return PaymentMethod.CASH
    if rand < 0.80:
        return PaymentMethod.NETWORK
    return PaymentMethod.TRANSFER


def reference_number(method):
    """Card and transfer payments carry a reference; cash doesn't."""
    if method == PaymentMethod.CASH:
        return None
    return f'TXN{random.randint(100000, 999999)}'


def at_business_hour(day):
    """Turn a date into a datetime somewhere in opening hours."""
    return datetime.combine(day, datetime.min.time()) + timedelta(
        hours=random.randint(8, 20), minutes=random.randint(0, 59)
    )


# ─────────────────────────────────────────────────────────────────────────────
# SEED ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────

def seed_database():
    """Seed the database with production-quality test data."""
    env = 'production' if any('pythonanywhere' in path.lower() for path in sys.path) \
        else os.getenv('FLASK_ENV', 'development')

    print(f'[+] Using environment: {env}')
    app = create_app(env)

    with app.app_context():
        print('\n' + '=' * 70)
        print('[*] SEEDING DATABASE - PRODUCTION-QUALITY TEST DATA')
        print('=' * 70 + '\n')

        print('  > Clearing existing data...')
        db.drop_all()
        db.create_all()

        print('  > Creating platform super admin...')
        create_super_admin()

        print('  > Creating service catalog...')
        services = create_services()

        worlds = []
        for spec in GYM_SPECS:
            print(f"\n  == Gym: {spec['name']} ==")
            worlds.append(build_gym(spec, services))

        db.session.commit()
        print_summary(worlds)


def build_gym(spec, services):
    """Create one complete, self-contained gym.

    Everything below is scoped to this gym's own branches and staff. Nothing
    reaches across gyms — that is precisely the isolation the app must honour.
    """
    gym = create_gym(spec)
    branches = create_branches(gym, spec)
    staff = create_staff(gym, branches, spec)
    customers = create_customers(branches, spec)
    subscriptions = create_subscriptions(customers, services, branches, staff)
    create_fingerprints(customers, subscriptions)
    create_transactions(subscriptions, branches, staff, spec)
    create_expenses(branches, staff, spec)
    create_complaints(branches, customers, spec)
    create_daily_closings(branches, staff)
    create_entry_logs(subscriptions, branches, spec)

    return {
        'spec': spec,
        'gym': gym,
        'branches': branches,
        'staff': staff,
        'customers': customers,
        'subscriptions': subscriptions,
    }


def create_super_admin():
    """The one account that stands above every gym."""
    super_admin = User(
        username=SUPER_ADMIN['username'],
        email=SUPER_ADMIN['email'],
        full_name=SUPER_ADMIN['full_name'],
        phone=SUPER_ADMIN['phone'],
        role=UserRole.SUPER_ADMIN,
        is_active=True,
    )
    super_admin.set_password(SUPER_ADMIN['password'])
    db.session.add(super_admin)
    db.session.flush()
    print(f"  ✓ Super admin: {SUPER_ADMIN['username']}")
    return super_admin


def create_gym(spec):
    """Create the gym and its owner."""
    owner_spec = spec['owner']
    owner = User(
        username=owner_spec['username'],
        email=owner_spec['email'],
        full_name=owner_spec['full_name'],
        phone=owner_spec['phone'],
        role=UserRole.OWNER,
        is_active=True,
    )
    owner.set_password(owner_spec['password'])
    db.session.add(owner)
    db.session.flush()

    gym = Gym(
        name=spec['name'],
        owner_id=owner.id,
        primary_color=spec['primary_color'],
        secondary_color=spec['secondary_color'],
        is_setup_complete=spec['is_setup_complete'],
        is_active=spec['is_active'],
    )
    db.session.add(gym)
    db.session.flush()

    # The owner belongs to their own gym, like every other member of staff.
    owner.gym_id = gym.id
    db.session.flush()

    print(f"  ✓ Gym + owner: {spec['name']} ({owner_spec['username']})")
    return gym


def create_branches(gym, spec):
    """Create the gym's branches, keyed by code for the staff wiring below."""
    branches = {}
    for branch_spec in spec['branches']:
        branch = Branch(
            name=branch_spec['name'],
            code=branch_spec['code'],
            address=branch_spec['address'],
            phone=branch_spec['phone'],
            city=branch_spec['city'],
            gym_id=gym.id,
            is_active=branch_spec.get('is_active', True),
        )
        db.session.add(branch)
        branches[branch_spec['code']] = branch

    db.session.flush()
    inactive = sum(1 for b in branches.values() if not b.is_active)
    suffix = f' ({inactive} inactive)' if inactive else ''
    print(f'  ✓ Branches: {len(branches)}{suffix}')
    return branches


def create_staff(gym, branches, spec):
    """Create every staff tier for this gym.

    Returns the roster grouped by role, plus a per-branch front-desk index —
    callers must attribute money and check-ins to someone who actually works at
    that branch, never to whoever happens to be first in the list.
    """
    domain = spec['email_domain']
    owner = User.query.filter_by(username=spec['owner']['username']).one()

    def add(username, full_name, phone, role, password, branch=None, active=True):
        user = User(
            username=username,
            email=f'{username}@{domain}',
            full_name=full_name,
            phone=phone,
            role=role,
            gym_id=gym.id,
            branch_id=branch.id if branch is not None else None,
            is_active=active,
        )
        user.set_password(password)
        db.session.add(user)
        return user

    regionals = []
    for region in spec['regions']:
        user = add(region['username'], region['full_name'], region['phone'],
                   UserRole.REGIONAL_MANAGER, region['password'])
        # The branch group *is* the role — without it a regional manager can
        # see nothing at all.
        user.managed_branches = [branches[code] for code in region['branch_codes']]
        regionals.append(user)

    managers = [
        add(username, name, phone, UserRole.BRANCH_MANAGER, 'manager123', branches[code])
        for username, name, phone, code in spec['managers']
    ]
    central_accountants = [
        add(username, name, phone, UserRole.CENTRAL_ACCOUNTANT, 'accountant123')
        for username, name, phone in spec['central_accountants']
    ]
    regional_accountants = []
    for region in spec['regional_accountants']:
        user = add(region['username'], region['full_name'], region['phone'],
                   UserRole.REGIONAL_ACCOUNTANT, 'accountant123')
        user.managed_branches = [branches[code] for code in region['branch_codes']]
        regional_accountants.append(user)
    branch_accountants = [
        add(username, name, phone, UserRole.BRANCH_ACCOUNTANT, 'accountant123', branches[code])
        for username, name, phone, code in spec['branch_accountants']
    ]
    reception = [
        add(username, name, phone, UserRole.FRONT_DESK, 'reception123', branches[code], active)
        for username, name, phone, code, active in spec['reception']
    ]

    db.session.flush()

    # Front desk per branch — only active staff can be credited with work.
    desk_by_branch = {}
    for user in reception:
        if user.is_active:
            desk_by_branch.setdefault(user.branch_id, []).append(user)

    missing = [b.name for b in branches.values() if b.id not in desk_by_branch]
    if missing:
        raise RuntimeError(
            f"Branches without active front desk staff: {missing}. "
            f"Every branch needs one, or its revenue would be attributed to another branch."
        )

    print(f'  ✓ Staff: 1 owner, {len(regionals)} regional, {len(managers)} branch managers, '
          f'{len(central_accountants) + len(regional_accountants) + len(branch_accountants)} accountants, '
          f'{len(reception)} front desk')
    for region, user in zip(spec['regions'], regionals):
        names = ', '.join(branches[c].name for c in region['branch_codes'])
        print(f"      - {region['username']} → {region['label']}: {names}")

    return {
        'owner': owner,
        'regionals': regionals,
        'managers': managers,
        'central_accountants': central_accountants,
        'regional_accountants': regional_accountants,
        'branch_accountants': branch_accountants,
        'reception': reception,
        'desk_by_branch': desk_by_branch,
    }


def create_services():
    """The service catalog, shared across gyms."""
    services = [
        Service(
            name='Monthly Gym Membership',
            service_type=ServiceType.GYM,
            description='Full gym access for 30 days',
            price=500, duration_days=30, allowed_days_per_week=7,
            freeze_count_limit=2, freeze_max_days=15, freeze_is_paid=False,
            is_active=True,
        ),
        Service(
            name='Quarterly Gym Membership',
            service_type=ServiceType.GYM,
            description='Full gym access for 90 days',
            price=1350, duration_days=90, allowed_days_per_week=7,
            freeze_count_limit=3, freeze_max_days=30, freeze_is_paid=False,
            is_active=True,
        ),
        Service(
            name='Swimming Education - Monthly',
            service_type=ServiceType.SWIMMING_EDUCATION,
            description='Learn to swim - 8 classes per month',
            price=600, duration_days=30, allowed_days_per_week=2, class_limit=8,
            freeze_count_limit=1, freeze_max_days=7, freeze_is_paid=True, freeze_cost=50,
            is_active=True,
        ),
        Service(
            name='Swimming Recreation - Monthly',
            service_type=ServiceType.SWIMMING_RECREATION,
            description='Recreational swimming access',
            price=400, duration_days=30, allowed_days_per_week=7,
            freeze_count_limit=2, freeze_max_days=10, freeze_is_paid=False,
            is_active=True,
        ),
        Service(
            name='Karate Classes - Monthly',
            service_type=ServiceType.KARATE,
            description='Karate training - 12 classes per month',
            price=550, duration_days=30, allowed_days_per_week=3, class_limit=12,
            freeze_count_limit=1, freeze_max_days=7, freeze_is_paid=True, freeze_cost=50,
            is_active=True,
        ),
        Service(
            name='Gym + Swimming Bundle',
            service_type=ServiceType.BUNDLE,
            description='Full gym and swimming pool access',
            price=800, duration_days=30, allowed_days_per_week=7,
            freeze_count_limit=2, freeze_max_days=15, freeze_is_paid=False,
            is_active=True,
        ),
        # Retired line item: proves the UI filters inactive services out of the
        # sell flow while old subscriptions that reference it still render.
        Service(
            name='Legacy Annual Pass (retired)',
            service_type=ServiceType.GYM,
            description='Discontinued annual membership - kept for historical records',
            price=4500, duration_days=365, allowed_days_per_week=7,
            freeze_count_limit=4, freeze_max_days=60, freeze_is_paid=False,
            is_active=False,
        ),
    ]

    for service in services:
        db.session.add(service)

    db.session.flush()
    sellable = [s for s in services if s.is_active]
    print(f'  ✓ Services: {len(services)} ({len(sellable)} sellable, prices 400-1350 EGP)')
    return services


def create_customers(branches, spec):
    """Create customers, weighted by each branch's performance."""
    from passlib.hash import pbkdf2_sha256

    customers = []
    gp_client = GOOGLE_PLAY_TEST_CLIENT

    for branch_spec in spec['branches']:
        branch = branches[branch_spec['code']]
        count = branch_spec['customers']

        # The Google Play reviewer's account is fixed, not generated — its
        # credentials are published in the Play Console and must not drift.
        if spec['key'] == gp_client['gym_key'] and branch_spec['code'] == gp_client['branch_code']:
            test_customer = Customer(
                full_name=gp_client['full_name'],
                phone=gp_client['phone'],
                email=gp_client['email'],
                national_id=gp_client['national_id'],
                date_of_birth=date(1998, 6, 15),
                gender=Gender.MALE,
                address=f"100 Review Street, {branch.city}",
                height=178,
                weight=78,
                health_notes='Google Play reviewer test account',
                branch_id=branch.id,
                is_active=True,
                temp_password=gp_client['password'],
                password_changed=False,
            )
            test_customer.password_hash = pbkdf2_sha256.hash(gp_client['password'])
            test_customer.calculate_health_metrics()
            customers.append(test_customer)
            db.session.add(test_customer)
            count = max(0, count - 1)

        for _ in range(count):
            gender = random.choice(['male', 'female'])
            first_name = random.choice(MALE_NAMES if gender == 'male' else FEMALE_NAMES)
            full_name = f'{first_name} {random.choice(LAST_NAMES)}'

            age = random.randint(18, 55)
            dob = date(date.today().year - age, random.randint(1, 12), random.randint(1, 28))
            temp_password = generate_temp_password()

            customer = Customer(
                full_name=full_name,
                phone=f'010{random.randint(10000000, 99999999)}',
                email=f'{spec["key"]}.customer{len(customers) + 1}@example.com',
                national_id=f'290{random.randint(1000000000, 9999999999)}',
                date_of_birth=dob,
                gender=Gender(gender),
                address=f'{random.randint(1, 200)} Street, {branch.city}',
                height=random.randint(155, 195),
                weight=random.randint(50, 120),
                health_notes=random.choice([
                    'No health issues',
                    'Previous knee injury',
                    'Back pain - needs special attention',
                    'Asthma - no heavy cardio',
                    'Diabetes - monitor blood sugar',
                    None,
                ]),
                branch_id=branch.id,
                is_active=True,
                temp_password=temp_password,
                password_changed=False,
            )
            # Not set_password() — that clears temp_password, and the client app
            # needs it to drive the first-login change flow.
            customer.password_hash = pbkdf2_sha256.hash(temp_password)
            customer.calculate_health_metrics()
            customers.append(customer)
            db.session.add(customer)

    db.session.flush()
    print(f'  ✓ Customers: {len(customers)}')
    return customers


def create_subscriptions(customers, services, branches, staff):
    """Create subscriptions across the whole status space.

    Statuses are derived from real expiry maths rather than sprinkled at random,
    so the 48-hour and 7-day expiry alerts fire on subscriptions that genuinely
    are about to lapse.
    """
    subscriptions = []
    sellable = [s for s in services if s.is_active]
    default_service = sellable[0]  # Monthly Gym Membership
    branch_by_id = {b.id: b for b in branches.values()}

    stop_reasons = [
        'Customer requested - medical reasons',
        'Customer requested - relocation',
        'Non-payment',
        'Violation of gym rules',
        'Customer dissatisfaction',
    ]

    customers_by_branch = {}
    for customer in customers:
        customers_by_branch.setdefault(customer.branch_id, []).append(customer)

    for branch_id, branch_customers in customers_by_branch.items():
        branch = branch_by_id[branch_id]
        desk = staff['desk_by_branch'][branch_id]

        for customer in branch_customers:
            reception = random.choice(desk)
            service = random.choice(sellable)

            days_old = random.choices(
                [random.randint(0, 10), random.randint(11, 25),
                 random.randint(26, 60), random.randint(61, 90)],
                weights=[30, 40, 20, 10],
                k=1,
            )[0]
            start_date = date.today() - timedelta(days=days_old)
            end_date = start_date + timedelta(days=service.duration_days)
            days_until_expiry = (end_date - date.today()).days

            if days_until_expiry < 0:
                status = SubscriptionStatus.EXPIRED
                freeze_count, total_frozen = 0, 0
            elif random.random() < 0.06:
                status = SubscriptionStatus.FROZEN
                freeze_count = random.randint(1, 2)
                total_frozen = random.randint(3, 14)
            elif random.random() < 0.04:
                status = SubscriptionStatus.STOPPED
                freeze_count, total_frozen = 0, 0
            else:
                status = SubscriptionStatus.ACTIVE
                freeze_count = random.randint(0, 2)
                total_frozen = random.randint(0, 7) if freeze_count else 0

            # The reviewer's account gets a predictable, comfortably-active plan.
            if customer.phone == GOOGLE_PLAY_TEST_CLIENT['phone']:
                service = default_service
                days_old = 5
                start_date = date.today() - timedelta(days=days_old)
                end_date = start_date + timedelta(days=service.duration_days)
                status = SubscriptionStatus.ACTIVE
                freeze_count, total_frozen = 0, 0

            subscription = Subscription(
                customer_id=customer.id,
                service_id=service.id,
                branch_id=branch.id,
                start_date=start_date,
                end_date=end_date,
                status=status,
                freeze_count=freeze_count,
                total_frozen_days=total_frozen,
                classes_attended=random.randint(0, service.class_limit) if service.class_limit else 0,
                stop_reason=random.choice(stop_reasons) if status == SubscriptionStatus.STOPPED else None,
                stopped_at=datetime.now() - timedelta(days=random.randint(1, 10))
                if status == SubscriptionStatus.STOPPED else None,
                created_by=reception.id,
            )
            apply_subscription_balance(subscription, service, status, days_old)
            subscriptions.append(subscription)
            db.session.add(subscription)

    db.session.flush()

    # Guarantee a spread of imminent expiries — the alert panels are a headline
    # feature and must never render empty. These are pinned rather than left to
    # the random draw above, which on a given seed might produce none.
    pin_expiring_subscriptions(subscriptions)

    # Every customer must be able to log into the client app and see an active
    # plan, so anyone the draw above left without one gets a fresh membership.
    ensured = 0
    with_active = {
        s.customer_id for s in subscriptions
        if s.status == SubscriptionStatus.ACTIVE and s.end_date >= date.today()
    }
    for customer in customers:
        if customer.id in with_active:
            continue
        desk = staff['desk_by_branch'][customer.branch_id]
        start_date = date.today() - timedelta(days=random.randint(0, 5))
        fallback = Subscription(
            customer_id=customer.id,
            service_id=default_service.id,
            branch_id=customer.branch_id,
            start_date=start_date,
            end_date=start_date + timedelta(days=default_service.duration_days),
            status=SubscriptionStatus.ACTIVE,
            freeze_count=0,
            total_frozen_days=0,
            classes_attended=0,
            created_by=random.choice(desk).id,
        )
        fallback.subscription_type = 'coins'
        fallback.total_coins = 30
        fallback.remaining_coins = random.randint(18, 30)
        subscriptions.append(fallback)
        db.session.add(fallback)
        with_active.add(customer.id)
        ensured += 1

    db.session.flush()
    create_freeze_history(subscriptions)
    db.session.flush()

    counts = {
        status.value: sum(1 for s in subscriptions if s.status == status)
        for status in SubscriptionStatus
    }
    expiring_48h = sum(
        1 for s in subscriptions
        if s.status == SubscriptionStatus.ACTIVE and 0 <= (s.end_date - date.today()).days <= 2
    )
    expiring_7d = sum(
        1 for s in subscriptions
        if s.status == SubscriptionStatus.ACTIVE and 0 <= (s.end_date - date.today()).days <= 7
    )
    print(f'  ✓ Subscriptions: {len(subscriptions)} '
          f'(active {counts["active"]}, frozen {counts["frozen"]}, '
          f'stopped {counts["stopped"]}, expired {counts["expired"]})')
    print(f'      - Expiry alerts: {expiring_48h} within 48h, {expiring_7d} within 7 days')
    if ensured:
        print(f'      - Added {ensured} fallback memberships so every client app login has one')
    return subscriptions


def apply_subscription_balance(subscription, service, status, days_old):
    """Set the coin/session balance to match the plan type and how used-up it is."""
    if service.service_type == ServiceType.GYM:
        subscription.subscription_type = 'coins'
        subscription.total_coins = random.choice([20, 25, 30])
        if status == SubscriptionStatus.EXPIRED:
            subscription.remaining_coins = 0
        elif status == SubscriptionStatus.STOPPED:
            subscription.remaining_coins = random.randint(0, subscription.total_coins // 2)
        else:
            used = int((days_old / service.duration_days) * subscription.total_coins
                       * random.uniform(0.6, 1.0))
            subscription.remaining_coins = max(0, subscription.total_coins - used)

    elif service.class_limit:
        subscription.subscription_type = (
            'training' if service.service_type == ServiceType.KARATE else 'sessions'
        )
        subscription.total_sessions = service.class_limit
        subscription.remaining_sessions = max(0, service.class_limit - subscription.classes_attended)
        if status == SubscriptionStatus.EXPIRED:
            subscription.remaining_sessions = 0
        elif status == SubscriptionStatus.STOPPED:
            subscription.remaining_sessions = random.randint(0, service.class_limit // 2)

    else:
        subscription.subscription_type = 'time_based'
        subscription.remaining_coins = None
        subscription.total_coins = None
        subscription.remaining_sessions = None
        subscription.total_sessions = None


def pin_expiring_subscriptions(subscriptions):
    """Force a handful of active plans to expire imminently, per branch.

    The expiry alerts are what the owner and managers open the app for; leaving
    their existence to chance would mean some seeds ship an empty alert panel.
    """
    by_branch = {}
    for subscription in subscriptions:
        if subscription.status == SubscriptionStatus.ACTIVE:
            by_branch.setdefault(subscription.branch_id, []).append(subscription)

    for branch_subscriptions in by_branch.values():
        # Two expiring inside 48h, three more inside the week.
        sample = random.sample(branch_subscriptions, min(5, len(branch_subscriptions)))
        for index, subscription in enumerate(sample):
            days_left = random.randint(0, 2) if index < 2 else random.randint(3, 7)
            subscription.end_date = date.today() + timedelta(days=days_left)
            subscription.start_date = subscription.end_date - timedelta(
                days=subscription.service.duration_days
            )


def create_freeze_history(subscriptions):
    """Write the freeze audit trail behind each subscription's freeze counters."""
    created = 0
    for subscription in subscriptions:
        if not (subscription.freeze_count > 0 and subscription.total_frozen_days > 0):
            continue
        for _ in range(subscription.freeze_count):
            freeze_start = subscription.start_date + timedelta(days=random.randint(5, 20))
            freeze_days = random.randint(1, max(1, min(10, subscription.total_frozen_days)))
            db.session.add(FreezeHistory(
                subscription_id=subscription.id,
                freeze_start=freeze_start,
                freeze_end=freeze_start + timedelta(days=freeze_days),
                freeze_days=freeze_days,
                reason=random.choice(['Travel', 'Medical', 'Personal', 'Work commitment']),
                cost=subscription.service.freeze_cost if subscription.service.freeze_is_paid else 0,
            ))
            created += 1
    return created


def create_fingerprints(customers, subscriptions):
    """Create fingerprints whose enrolment state tracks subscription state."""
    latest = {}
    for subscription in subscriptions:
        latest[subscription.customer_id] = subscription

    fingerprints = []
    for customer in random.sample(customers, int(len(customers) * 0.92)):
        subscription = latest.get(customer.id)
        if subscription is None:
            is_active = random.random() < 0.4
        elif subscription.status == SubscriptionStatus.ACTIVE:
            is_active = True
        elif subscription.status == SubscriptionStatus.FROZEN:
            is_active = random.random() < 0.3
        elif subscription.status == SubscriptionStatus.STOPPED:
            is_active = False
        else:  # expired — a few keep working through the grace period
            is_active = random.random() < 0.1

        fingerprint = Fingerprint(
            customer_id=customer.id,
            fingerprint_hash=Fingerprint.generate_fingerprint_hash(
                customer.id, f'fingerprint_data_{customer.id}_{random.randint(1000, 9999)}'
            ),
            is_active=is_active,
        )
        fingerprints.append(fingerprint)
        db.session.add(fingerprint)

    db.session.flush()
    active = sum(1 for f in fingerprints if f.is_active)
    print(f'  ✓ Fingerprints: {len(fingerprints)} ({active} active, {len(fingerprints) - active} disabled)')
    return fingerprints


MISC_SALES = [
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
    ('Lock purchase', 30, 60),
]


def create_transactions(subscriptions, branches, staff, spec):
    """Create the money trail: signups, renewals, freeze fees and counter sales.

    Sales reach back 8 months so the monthly revenue trend has a point in every
    bucket; a chart that starts mid-axis reads as a data bug, not a young gym.
    """
    transactions = []

    def desk_for(branch_id):
        return random.choice(staff['desk_by_branch'][branch_id])

    # 1. The signup payment behind every subscription.
    for subscription in subscriptions:
        method = payment_method()
        transactions.append(Transaction(
            amount=subscription.service.price,
            payment_method=method,
            transaction_type=TransactionType.SUBSCRIPTION,
            branch_id=subscription.branch_id,
            customer_id=subscription.customer_id,
            subscription_id=subscription.id,
            created_by=desk_for(subscription.branch_id).id,
            description=f'New subscription: {subscription.service.name}',
            transaction_date=subscription.start_date,
            created_at=at_business_hour(subscription.start_date),
            reference_number=reference_number(method),
        ))

    # 2. Renewal history for a third of members — the renewal-rate metric needs
    #    both renewers and non-renewers to say anything.
    for subscription in random.sample(subscriptions, int(len(subscriptions) * 0.35)):
        for renewal_num in range(random.choices([1, 2, 3], weights=[60, 30, 10], k=1)[0]):
            method = payment_method()
            renewal_date = subscription.start_date - timedelta(
                days=random.randint(30, 90) * (renewal_num + 1)
            )
            transactions.append(Transaction(
                amount=subscription.service.price,
                payment_method=method,
                transaction_type=TransactionType.RENEWAL,
                branch_id=subscription.branch_id,
                customer_id=subscription.customer_id,
                subscription_id=subscription.id,
                created_by=desk_for(subscription.branch_id).id,
                description=f'Renewal #{renewal_num + 1}: {subscription.service.name}',
                transaction_date=renewal_date,
                created_at=at_business_hour(renewal_date),
                reference_number=reference_number(method),
            ))

    # 3. Freeze fees, but only for the plans that actually charge for freezing.
    for subscription in subscriptions:
        if not (subscription.freeze_count > 0 and subscription.service.freeze_is_paid):
            continue
        for i in range(subscription.freeze_count):
            method = payment_method()
            freeze_date = subscription.start_date + timedelta(days=random.randint(5, 25))
            transactions.append(Transaction(
                amount=subscription.service.freeze_cost,
                payment_method=method,
                transaction_type=TransactionType.FREEZE,
                branch_id=subscription.branch_id,
                customer_id=subscription.customer_id,
                subscription_id=subscription.id,
                created_by=desk_for(subscription.branch_id).id,
                description=f'Freeze fee #{i + 1}: {subscription.service.name}',
                transaction_date=freeze_date,
                created_at=at_business_hour(freeze_date),
                reference_number=reference_number(method),
            ))

    # 4. Counter sales — the volume that makes leaderboards and trends move.
    subscriber_ids = [s.customer_id for s in subscriptions]
    for branch_spec, branch in _spec_branch_pairs(branches, spec):
        # Scaled by branch performance: a strong branch sells more of everything.
        sale_count = int(random.randint(90, 120) * branch_spec['perf'])
        for _ in range(sale_count):
            description, low, high = random.choice(MISC_SALES)
            sale_date = date.today() - timedelta(days=random.randint(0, HISTORY_DAYS))
            method = payment_method()
            transactions.append(Transaction(
                amount=random.randint(low, high),
                payment_method=method,
                transaction_type=TransactionType.OTHER,
                branch_id=branch.id,
                customer_id=random.choice(subscriber_ids) if random.random() < 0.7 else None,
                created_by=desk_for(branch.id).id,
                description=description,
                transaction_date=sale_date,
                created_at=at_business_hour(sale_date),
                reference_number=reference_number(method),
            ))

    for transaction in transactions:
        db.session.add(transaction)
    db.session.flush()

    revenue = sum(float(t.amount) for t in transactions)
    by_type = {
        t_type.value: sum(1 for t in transactions if t.transaction_type == t_type)
        for t_type in TransactionType
    }
    print(f'  ✓ Transactions: {len(transactions)} ({revenue:,.0f} EGP over {HISTORY_DAYS} days)')
    print(f'      - By type: {by_type}')
    return transactions


def _spec_branch_pairs(branches, spec):
    """Pair each Branch object back to the spec dict that described it."""
    for branch_spec in spec['branches']:
        yield branch_spec, branches[branch_spec['code']]


# Recurring monthly costs — the backbone of a real P&L, and the reason the
# expense-by-category chart has a shape instead of a flat scatter of repairs.
RECURRING_EXPENSES = [
    ('Staff Salaries', 'Monthly payroll', ExpenseCategory.SALARIES, 18000, 32000),
    ('Branch Rent', 'Monthly facility rent', ExpenseCategory.RENT, 12000, 22000),
    ('Electricity Bill', 'Monthly electricity consumption', ExpenseCategory.UTILITIES, 1200, 2000),
    ('Water Bill', 'Monthly water usage', ExpenseCategory.UTILITIES, 250, 500),
    ('Internet & Phone', 'Monthly communication bills', ExpenseCategory.UTILITIES, 400, 700),
    ('Security Service', 'Monthly security guard service', ExpenseCategory.SERVICES, 2000, 3000),
    ('Insurance Premium', 'Monthly insurance premium', ExpenseCategory.INSURANCE, 1500, 2500),
]

# Ad-hoc spending, spread thinly across the remaining categories.
ADHOC_EXPENSES = [
    ('Equipment Maintenance', 'Treadmill repair and maintenance', ExpenseCategory.MAINTENANCE, 500, 800),
    ('Cleaning Supplies', 'Monthly cleaning and sanitation supplies', ExpenseCategory.SUPPLIES, 150, 300),
    ('Equipment Purchase', 'New gym equipment', ExpenseCategory.EQUIPMENT, 1500, 5000),
    ('Pool Chemicals', 'Chlorine and pool maintenance chemicals', ExpenseCategory.SUPPLIES, 300, 600),
    ('Staff Training', 'Professional development and certifications', ExpenseCategory.TRAINING, 800, 1500),
    ('Marketing Campaign', 'Social media and promotional materials', ExpenseCategory.MARKETING, 200, 800),
    ('Repair Work', 'General facility repairs', ExpenseCategory.MAINTENANCE, 300, 1200),
    ('AC Maintenance', 'Air conditioning service and repair', ExpenseCategory.MAINTENANCE, 800, 1500),
    ('Locker Replacement', 'New lockers for changing room', ExpenseCategory.EQUIPMENT, 2000, 4000),
    ('Sound System Upgrade', 'Music and PA system', ExpenseCategory.EQUIPMENT, 1000, 2000),
    ('Painting Work', 'Interior painting and decoration', ExpenseCategory.MAINTENANCE, 1500, 3000),
    ('Uniform Purchase', 'Staff uniforms', ExpenseCategory.SUPPLIES, 500, 1000),
    ('First Aid Supplies', 'Medical supplies and first aid kit', ExpenseCategory.SUPPLIES, 200, 400),
    ('Software License', 'Management software fee', ExpenseCategory.SOFTWARE, 1000, 2000),
    ('Pest Control', 'Pest control service', ExpenseCategory.SERVICES, 300, 500),
    ('Fire Safety Inspection', 'Annual fire safety inspection', ExpenseCategory.SAFETY, 800, 1200),
    ('Emergency Exit Signs', 'Replace emergency lighting', ExpenseCategory.SAFETY, 600, 1000),
    ('Plumbing Repair', 'Shower and sink repairs', ExpenseCategory.MAINTENANCE, 400, 900),
    ('Mirror Replacement', 'Large wall mirrors for training area', ExpenseCategory.EQUIPMENT, 1200, 2000),
    ('Floor Resurfacing', 'Gym floor maintenance', ExpenseCategory.MAINTENANCE, 2500, 4000),
    ('LED Lighting Upgrade', 'Energy efficient lighting', ExpenseCategory.EQUIPMENT, 1500, 2500),
    ('Sauna Heater Repair', 'Sauna maintenance', ExpenseCategory.EQUIPMENT, 800, 1500),
    ('Miscellaneous', 'Uncategorised petty cash spending', ExpenseCategory.OTHER, 100, 500),
]

APPROVAL_NOTES = [
    'Approved', 'Approved - necessary expense', 'Approved - within budget',
    'Approved as per policy', 'Approved - urgent requirement', 'Approved by central office',
]

REJECTION_NOTES = [
    'Not in budget this month', 'Needs more documentation', 'Exceeds approval limit',
    'Duplicate expense', 'Requires manager escalation',
    'Quote too high - negotiate better price', 'Insufficient justification',
]


def create_expenses(branches, staff, spec):
    """Create spending with a realistic approval workflow.

    created_at tracks expense_date rather than defaulting to now: the money page
    filters on one and the reports on the other, and if they disagree the same
    expense appears and disappears depending on which screen you're looking at.
    """
    expenses = []
    reviewers = staff['central_accountants'] + staff['branch_accountants'] + staff['managers']
    manager_by_branch = {m.branch_id: m for m in staff['managers']}

    def author_for(branch_id):
        return manager_by_branch.get(branch_id) or staff['managers'][0]

    def add_expense(branch, title, description, category, amount, expense_date, status):
        expense = Expense(
            title=title,
            description=f'{description} - {branch.name}',
            amount=amount,
            category=category,
            branch_id=branch.id,
            status=status,
            expense_date=expense_date,
            created_by_id=author_for(branch.id).id,
            created_at=at_business_hour(expense_date),
        )
        if status in (ExpenseStatus.APPROVED, ExpenseStatus.REJECTED) and reviewers:
            expense.reviewed_by_id = random.choice(reviewers).id
            expense.reviewed_at = at_business_hour(
                expense_date + timedelta(days=random.randint(1, 7))
            )
            expense.review_notes = random.choice(
                APPROVAL_NOTES if status == ExpenseStatus.APPROVED else REJECTION_NOTES
            )
        expenses.append(expense)
        db.session.add(expense)
        return expense

    def status_for_age(days_old):
        """Older expenses have mostly been dealt with; fresh ones are pending."""
        if days_old < 3:
            weights = [(ExpenseStatus.PENDING, 80), (ExpenseStatus.APPROVED, 20)]
        elif days_old < 7:
            weights = [(ExpenseStatus.PENDING, 50), (ExpenseStatus.APPROVED, 45),
                       (ExpenseStatus.REJECTED, 5)]
        elif days_old < 15:
            weights = [(ExpenseStatus.PENDING, 20), (ExpenseStatus.APPROVED, 70),
                       (ExpenseStatus.REJECTED, 10)]
        else:
            weights = [(ExpenseStatus.PENDING, 5), (ExpenseStatus.APPROVED, 85),
                       (ExpenseStatus.REJECTED, 10)]
        return random.choices([w[0] for w in weights], weights=[w[1] for w in weights], k=1)[0]

    for branch_spec, branch in _spec_branch_pairs(branches, spec):
        # Recurring bills, once a month for the last 8 months.
        for months_ago in range(8):
            bill_date = date.today().replace(day=1) - timedelta(days=months_ago * 30)
            if bill_date > date.today():
                continue
            for title, description, category, low, high in RECURRING_EXPENSES:
                amount = int(random.randint(low, high) * branch_spec['perf'])
                if amount <= 0:
                    continue
                days_old = (date.today() - bill_date).days
                # Last month's bills may still be awaiting sign-off; older ones are settled.
                status = ExpenseStatus.APPROVED if days_old > 35 else status_for_age(days_old)
                add_expense(branch, title, description, category, amount, bill_date, status)

        # Ad-hoc spending across the whole history window.
        for _ in range(int(random.randint(18, 26) * max(branch_spec['perf'], 0.4))):
            title, description, category, low, high = random.choice(ADHOC_EXPENSES)
            expense_date = date.today() - timedelta(days=random.randint(0, HISTORY_DAYS))
            add_expense(branch, title, description, category,
                        random.randint(low, high), expense_date,
                        status_for_age((date.today() - expense_date).days))

        # Every branch gets live approvals waiting: the manager's and
        # accountant's review queue is a core flow and must never be empty.
        for _ in range(3):
            title, description, category, low, high = random.choice(ADHOC_EXPENSES)
            add_expense(branch, title, description, category,
                        random.randint(low, high),
                        date.today() - timedelta(days=random.randint(0, 5)),
                        ExpenseStatus.PENDING)

    db.session.flush()

    pending = sum(1 for e in expenses if e.status == ExpenseStatus.PENDING)
    approved = sum(1 for e in expenses if e.status == ExpenseStatus.APPROVED)
    rejected = sum(1 for e in expenses if e.status == ExpenseStatus.REJECTED)
    approved_total = sum(float(e.amount) for e in expenses if e.status == ExpenseStatus.APPROVED)
    categories = len({e.category for e in expenses})
    print(f'  ✓ Expenses: {len(expenses)} across {categories} categories '
          f'({approved_total:,.0f} EGP approved)')
    print(f'      - Pending {pending} (awaiting review), approved {approved}, rejected {rejected}')
    return expenses


COMPLAINT_TEMPLATES = [
    ('Broken Treadmill', 'Treadmill #{number} is not working properly', ComplaintType.DEVICE),
    ('Pool Temperature Issue', 'Pool water temperature is {temperature}', ComplaintType.POOL),
    ('Locker Room Cleanliness', 'Locker room needs better cleaning', ComplaintType.CLEANLINESS),
    ('Staff Behavior', 'Staff member was {staff} during my visit', ComplaintType.SERVICE),
    ('AC Not Working', 'Air conditioning not functioning in {area} area', ComplaintType.DEVICE),
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
    ('Lighting Dim', 'Insufficient lighting in certain areas', ComplaintType.OTHER),
]

COMPLAINT_DETAILS = {
    'temperature': ['too cold', 'too hot', 'not comfortable'],
    'area': ['main gym', 'cardio section', 'weight area', 'group class room'],
    'staff': ['rude', 'unhelpful', 'not attentive', 'unprofessional'],
    'number': ['1', '2', '3', '5', '7', '12'],
}

RESOLUTION_NOTES = [
    'Issue resolved', 'Equipment repaired', 'Staff member trained',
    'Cleaning schedule updated', 'Policy explained to customer',
    'Compensation provided', 'Maintenance completed', 'Replacement ordered',
    'Apology issued',
]


def create_complaints(branches, customers, spec):
    """Create complaints inversely weighted by branch performance.

    A well-run branch gets fewer complaints and closes them faster. Tying both
    to the same 'perf' number that drives revenue is what makes the branch
    leaderboard tell a coherent story instead of a random one.
    """
    complaints = []
    customers_by_branch = {}
    for customer in customers:
        customers_by_branch.setdefault(customer.branch_id, []).append(customer)

    for branch_spec, branch in _spec_branch_pairs(branches, spec):
        perf = branch_spec['perf']
        # Inverse of performance: the weakest branch carries the heaviest load.
        count = int(random.randint(8, 12) + (1 - perf) * 20)
        branch_customers = customers_by_branch.get(branch.id, [])

        for _ in range(count):
            title, template, complaint_type = random.choice(COMPLAINT_TEMPLATES)
            description = template.format(**{
                key: random.choice(values) for key, values in COMPLAINT_DETAILS.items()
            }) if '{' in template else template

            created_at = datetime.now() - timedelta(days=random.randint(0, 60))
            days_old = (datetime.now() - created_at).days
            status = _complaint_status(perf, days_old)

            customer = random.choice(branch_customers) \
                if branch_customers and random.random() < 0.75 else None

            complaints.append(Complaint(
                title=title,
                description=description,
                complaint_type=complaint_type,
                status=status,
                branch_id=branch.id,
                customer_id=customer.id if customer else None,
                customer_name=customer.full_name if customer else 'Anonymous Customer',
                customer_phone=customer.phone if customer else None,
                created_at=created_at,
                resolution_notes=random.choice(RESOLUTION_NOTES)
                if status == ComplaintStatus.CLOSED else None,
                resolved_at=created_at + timedelta(days=random.randint(1, 7))
                if status == ComplaintStatus.CLOSED else None,
            ))

    for complaint in complaints:
        db.session.add(complaint)
    db.session.flush()

    open_count = sum(1 for c in complaints if c.status == ComplaintStatus.OPEN)
    in_progress = sum(1 for c in complaints if c.status == ComplaintStatus.IN_PROGRESS)
    closed = sum(1 for c in complaints if c.status == ComplaintStatus.CLOSED)
    print(f'  ✓ Complaints: {len(complaints)} '
          f'(open {open_count}, in progress {in_progress}, closed {closed})')
    return complaints


def _complaint_status(perf, days_old):
    """Strong branches clear their queue; weak ones let it age."""
    close_rate = 0.55 + perf * 0.35  # 0.65 (weak) → 0.90 (strong)
    if days_old < 2:
        return ComplaintStatus.OPEN if random.random() < 0.6 else ComplaintStatus.IN_PROGRESS
    if days_old < 10:
        return random.choices(
            [ComplaintStatus.OPEN, ComplaintStatus.IN_PROGRESS, ComplaintStatus.CLOSED],
            weights=[25 * (1 - perf) + 5, 35, close_rate * 60],
            k=1,
        )[0]
    return ComplaintStatus.CLOSED if random.random() < close_rate else ComplaintStatus.OPEN


def create_daily_closings(branches, staff):
    """Close each branch's till for the last 30 days, against real takings.

    The expected cash is summed from that day's actual transactions rather than
    invented, so a shortage the accountant investigates traces back to real
    rows — an audit trail that stops at a random number teaches nothing.
    """
    from sqlalchemy import func, and_

    closings = []
    medium_alerts = high_alerts = 0

    for branch in branches.values():
        desk = staff['desk_by_branch'][branch.id]

        for days_ago in range(30, 0, -1):
            closing_date = date.today() - timedelta(days=days_ago)
            day_transactions = Transaction.query.filter(
                and_(
                    Transaction.branch_id == branch.id,
                    func.date(Transaction.transaction_date) == closing_date,
                )
            ).all()

            expected_cash = network_total = transfer_total = 0.0
            for transaction in day_transactions:
                amount = float(transaction.amount)
                if transaction.payment_method == PaymentMethod.CASH:
                    expected_cash += amount
                elif transaction.payment_method == PaymentMethod.NETWORK:
                    network_total += amount
                else:
                    transfer_total += amount

            if not (expected_cash or network_total or transfer_total):
                continue

            rand = random.random()
            if rand < 0.80:
                variance = random.randint(-30, 30)
                notes = random.choice(['Normal closing', 'All cash accounted',
                                       'Busy day', 'Regular operations', None])
            elif rand < 0.95:
                variance = random.choice([random.randint(50, 100), random.randint(-100, -50)])
                medium_alerts += 1
                notes = (f'Cash surplus: {variance} EGP - needs verification' if variance > 0
                         else f'Cash shortage: {variance} EGP - requires investigation')
            else:
                variance = random.choice([random.randint(100, 200), random.randint(-200, -100)])
                high_alerts += 1
                notes = (f'LARGE SURPLUS: {variance} EGP - URGENT: Verify all transactions'
                         if variance > 0
                         else f'LARGE SHORTAGE: {variance} EGP - URGENT: Manager investigation required')

            closings.append(DailyClosing(
                branch_id=branch.id,
                closing_date=closing_date,
                expected_cash=expected_cash,
                actual_cash=expected_cash + variance,
                cash_difference=variance,
                network_total=network_total,
                transfer_total=transfer_total,
                total_revenue=expected_cash + network_total + transfer_total,
                closed_by=random.choice(desk).id,
                notes=notes,
                created_at=datetime.combine(closing_date, datetime.min.time()) + timedelta(hours=22),
            ))

    for closing in closings:
        db.session.add(closing)
    db.session.flush()

    print(f'  ✓ Daily closings: {len(closings)} '
          f'({medium_alerts} medium + {high_alerts} urgent cash variances)')
    return closings


def create_entry_logs(subscriptions, branches, spec):
    """Create 30 days of check-ins, weighted toward recent days."""
    eligible = [
        s for s in subscriptions
        if s.status in (SubscriptionStatus.ACTIVE, SubscriptionStatus.FROZEN)
        or (s.status == SubscriptionStatus.EXPIRED and (date.today() - s.end_date).days < 30)
    ]
    if not eligible:
        print('  ! No eligible subscriptions for entry logs')
        return []

    by_branch = {}
    for subscription in eligible:
        by_branch.setdefault(subscription.branch_id, []).append(subscription)

    entry_logs = []
    for branch_spec, branch in _spec_branch_pairs(branches, spec):
        branch_subscriptions = by_branch.get(branch.id)
        if not branch_subscriptions:
            continue

        for day_offset in range(30):
            entry_date = date.today() - timedelta(days=day_offset)
            # Traffic scales with the branch and tapers off going back in time.
            base = 26 if day_offset < 7 else 20 if day_offset < 14 else 15
            daily = int(random.randint(base - 5, base + 5) * branch_spec['perf'])

            for _ in range(max(0, daily)):
                subscription = random.choice(branch_subscriptions)
                entry_time = datetime.combine(entry_date, datetime.min.time()) + timedelta(
                    hours=random.randint(6, 22), minutes=random.randint(0, 59)
                )
                entry_type = random.choices(
                    [EntryType.QR_SCAN, EntryType.FINGERPRINT, EntryType.MANUAL],
                    weights=[85, 10, 5], k=1,
                )[0]

                entry_logs.append(EntryLog(
                    customer_id=subscription.customer_id,
                    subscription_id=subscription.id,
                    branch_id=branch.id,
                    entry_time=entry_time,
                    entry_type=entry_type,
                    entry_status=EntryStatus.APPROVED,
                    coins_deducted=1 if subscription.subscription_type == 'coins' else 0,
                    validation_token=subscription.customer.qr_code
                    if entry_type == EntryType.QR_SCAN else None,
                    created_at=entry_time,
                ))

    for entry_log in entry_logs:
        db.session.add(entry_log)
    db.session.flush()

    print(f'  ✓ Entry logs: {len(entry_logs)} check-ins over the last 30 days')
    return entry_logs


# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

def print_summary(worlds):
    """Print the counts and every credential needed to test the app."""
    print('\n' + '=' * 70)
    print('[*] DATABASE TOTALS')
    print('=' * 70)
    print(f'  Gyms:          {Gym.query.count()}')
    print(f'  Branches:      {Branch.query.count()}')
    print(f'  Users:         {User.query.count()}')
    print(f'  Services:      {Service.query.count()}')
    print(f'  Customers:     {Customer.query.count()}')
    print(f'  Subscriptions: {Subscription.query.count()}')
    print(f'  Transactions:  {Transaction.query.count()}')
    print(f'  Expenses:      {Expense.query.count()}')
    print(f'  Complaints:    {Complaint.query.count()}')
    print(f'  Fingerprints:  {Fingerprint.query.count()}')
    print(f'  Freeze history:{FreezeHistory.query.count()}')
    print(f'  Daily closings:{DailyClosing.query.count()}')
    print(f'  Entry logs:    {EntryLog.query.count()}')

    print('\n' + '=' * 70)
    print('[*] STAFF ACCOUNTS BY RANK  (highest → lowest)')
    print('=' * 70)

    print('\n[SUPER ADMIN] — sees and edits every gym, every branch:')
    print(f"  {SUPER_ADMIN['username']} / {SUPER_ADMIN['password']}  ({SUPER_ADMIN['full_name']})")

    for world in worlds:
        spec, staff = world['spec'], world['staff']
        state = []
        if not spec['is_active']:
            state.append('DEACTIVATED')
        if not spec['is_setup_complete']:
            state.append('SETUP INCOMPLETE')
        suffix = f"   [{', '.join(state)}]" if state else ''

        print(f"\n--- {spec['name']}{suffix} ---")
        print(f"  [OWNER]    {spec['owner']['username']} / {spec['owner']['password']}"
              f"  — all {len(spec['branches'])} branches of this gym")

        for region in spec['regions']:
            names = ', '.join(
                b['name'] for b in spec['branches'] if b['code'] in region['branch_codes']
            )
            print(f"  [REGIONAL] {region['username']} / {region['password']}"
                  f"  — {region['label']}: {names}")

        for username, name, _phone, code in spec['managers']:
            branch = next(b['name'] for b in spec['branches'] if b['code'] == code)
            print(f'  [MANAGER]  {username} / manager123  — {branch} (full control of this branch)')

        for username, name, _phone in spec['central_accountants']:
            print(f'  [ACCT-C]   {username} / accountant123  — money across all branches')

        for region in spec['regional_accountants']:
            names = ', '.join(
                b['name'] for b in spec['branches'] if b['code'] in region['branch_codes']
            )
            print(f"  [ACCT-R]   {region['username']} / accountant123"
                  f"  — money for {region['label']}: {names}")

        for username, name, _phone, code in spec['branch_accountants']:
            branch = next(b['name'] for b in spec['branches'] if b['code'] == code)
            print(f'  [ACCT-B]   {username} / accountant123  — money at {branch}')

        for username, name, _phone, code, active in spec['reception']:
            branch = next(b['name'] for b in spec['branches'] if b['code'] == code)
            flag = '' if active else '  (INACTIVE - login must fail)'
            print(f'  [DESK]     {username} / reception123  — {branch}{flag}')

    print('\n' + '=' * 70)
    print('[*] CLIENT APP ACCOUNTS')
    print('=' * 70)
    print('\n[GOOGLE PLAY REVIEWER] — stable account, do not delete:')
    print(f"  Phone: {GOOGLE_PLAY_TEST_CLIENT['phone']} | Password: {GOOGLE_PLAY_TEST_CLIENT['password']}")
    print(f"  {GOOGLE_PLAY_TEST_CLIENT['full_name']} — active membership, Dragon Club")

    print('\n[SAMPLE MEMBERS] — every member has a temp password and must change it on first login:')
    for customer in Customer.query.limit(5).all():
        print(f'  {customer.phone} / {customer.temp_password}  — {customer.full_name} ({customer.branch.name})')

    print('\n' + '=' * 70)
    print('[*] WHAT THIS DATA LETS YOU TEST')
    print('=' * 70)
    print('  Hierarchy')
    print('    - regional1 sees Dragon/Phoenix/Falcon and is denied Tiger/Shark/Lion')
    print('    - regional2 sees Tiger/Shark/Lion and is denied the Cairo branches')
    print('    - manager1 sees only Dragon Club; owner sees all six')
    print('    - a manager cannot create a regional manager or another manager')
    print('  Cross-gym isolation')
    print('    - owner (PowerFit) must never see Iron Temple data, and vice versa')
    print('    - only the super admin sees both, plus the deactivated AquaLife gym')
    print('  Super admin')
    print('    - gym list with live branch/customer/staff counts; drill into any branch')
    print('    - activate/deactivate any gym (AquaLife starts deactivated)')
    print('  Owner setup wizard')
    print('    - owner3 / owner123 lands in the wizard (setup deliberately incomplete)')
    print('  Money & BI')
    print(f'    - {HISTORY_DAYS} days of revenue: daily, weekly and monthly trends all have points')
    print('    - expense categories led by salaries and rent, as in a real P&L')
    print('    - pending expenses at every branch for the approve/reject queue')
    print('    - daily closings with cash surpluses and shortages to investigate')
    print('  Alerts')
    print('    - subscriptions expiring within 48h and within 7 days at every branch')
    print('    - open complaints, weighted so weak branches carry more')
    print('  Edge cases')
    print('    - reception9 is deactivated; Iron Temple Maadi is an inactive branch')
    print('    - a retired service that must not appear in the sell flow')
    print('=' * 70 + '\n')


if __name__ == '__main__':
    seed_database()
