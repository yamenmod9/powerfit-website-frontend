from app import create_app
from app.extensions import db
app = create_app('development')
with app.app_context():
    from app.models import User, Branch, Customer, Transaction, Expense
    print('Users:', User.query.count())
    print('Branches:', Branch.query.count())
    print('Customers:', Customer.query.count())
    print('Transactions:', Transaction.query.count())
    print('Expenses:', Expense.query.count())
    # Check users
    for u in User.query.all():
        print(f'  User: {u.username} | Role: {u.role} | Branch: {u.branch_id}')

