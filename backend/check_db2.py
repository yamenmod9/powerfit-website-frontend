from app import create_app
from app.extensions import db
app = create_app('development')
with app.app_context():
    from app.models import User, UserRole
    # Check for super admin
    super_admin = User.query.filter_by(role=UserRole.SUPER_ADMIN).all()
    print('Super admins:', [u.username for u in super_admin])
    # Check Zyad
    zyad = User.query.filter_by(username='Zyad').first()
    if zyad:
        print(f'Zyad found: role={zyad.role}, active={zyad.is_active}')
    else:
        print('Zyad not found - seeding issue')
    print('\nAll users:')
    for u in User.query.all():
        print(f'  {u.username} | {u.role} | branch={u.branch_id}')

