"""
Customer model - Gym members/clients
"""
from datetime import datetime
from app.extensions import db
from passlib.hash import pbkdf2_sha256
import enum
import secrets
import string


class Gender(enum.Enum):
    """Gender enum"""
    MALE = 'male'
    FEMALE = 'female'


class Customer(db.Model):
    """Customer/Member model"""
    __tablename__ = 'customers'

    id = db.Column(db.Integer, primary_key=True)
    
    # Personal Information
    full_name = db.Column(db.String(150), nullable=False)
    phone = db.Column(db.String(20), unique=True, nullable=False, index=True)  # Unique key
    email = db.Column(db.String(120), nullable=True)
    national_id = db.Column(db.String(50), nullable=True)
    date_of_birth = db.Column(db.Date, nullable=True)
    gender = db.Column(db.Enum(Gender), nullable=True)
    address = db.Column(db.Text, nullable=True)
    
    # Health Information
    height = db.Column(db.Float, nullable=True)  # in cm
    weight = db.Column(db.Float, nullable=True)  # in kg
    bmi = db.Column(db.Float, nullable=True)  # Calculated
    bmi_category = db.Column(db.String(20), nullable=True)  # Calculated (Underweight, Normal, Overweight, Obese)
    bmr = db.Column(db.Float, nullable=True)  # Basal Metabolic Rate - Calculated
    ideal_weight = db.Column(db.Float, nullable=True)  # Calculated
    daily_calories = db.Column(db.Integer, nullable=True)  # Calculated
    health_notes = db.Column(db.Text, nullable=True)
    
    # QR Code for gym access
    qr_code = db.Column(db.String(50), unique=True, nullable=True, index=True)
    
    # Client App Authentication
    password_hash = db.Column(db.String(255), nullable=True)  # Hashed password for client app
    temp_password = db.Column(db.String(20), nullable=True)  # Plain temporary password (for first login)
    password_changed = db.Column(db.Boolean, default=False, nullable=False)  # Has client changed password?

    # Preferred UI language ('ar' or 'en'). NULL means the client hasn't
    # set one yet — used as the signal to show the first-login language step.
    preferred_language = db.Column(db.String(5), nullable=True)
    
    # Branch relationship
    branch_id = db.Column(db.Integer, db.ForeignKey('branches.id'), nullable=False, index=True)
    branch = db.relationship('Branch', back_populates='customers')
    
    # Status
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    subscriptions = db.relationship('Subscription', back_populates='customer', lazy='dynamic', cascade='all, delete-orphan')
    fingerprints = db.relationship('Fingerprint', back_populates='customer', lazy='dynamic', cascade='all, delete-orphan')

    def __repr__(self):
        return f'<Customer {self.full_name} ({self.phone})>'

    def calculate_health_metrics(self):
        """Calculate BMI, BMI category, BMR, ideal weight, and daily calories"""
        if self.height and self.weight:
            # BMI = weight(kg) / (height(m))^2
            height_m = self.height / 100
            self.bmi = round(self.weight / (height_m ** 2), 2)
            
            # BMI Category
            if self.bmi < 18.5:
                self.bmi_category = "Underweight"
            elif 18.5 <= self.bmi < 25:
                self.bmi_category = "Normal"
            elif 25 <= self.bmi < 30:
                self.bmi_category = "Overweight"
            else:
                self.bmi_category = "Obese"
            
            # Ideal weight (using Devine formula)
            # Male: 50 + 2.3 * (height_in - 60)
            # Female: 45.5 + 2.3 * (height_in - 60)
            height_in = self.height / 2.54
            if self.gender == Gender.MALE:
                self.ideal_weight = round(50 + 2.3 * (height_in - 60), 2)
            elif self.gender == Gender.FEMALE:
                self.ideal_weight = round(45.5 + 2.3 * (height_in - 60), 2)
            
            # BMR and Daily calories (Harris-Benedict Equation)
            if self.gender and self.date_of_birth:
                age = (datetime.utcnow().date() - self.date_of_birth).days // 365
                if self.gender == Gender.MALE:
                    # BMR = 88.362 + (13.397 × weight in kg) + (4.799 × height in cm) - (5.677 × age)
                    self.bmr = round(88.362 + (13.397 * self.weight) + (4.799 * self.height) - (5.677 * age), 2)
                else:
                    # BMR = 447.593 + (9.247 × weight in kg) + (3.098 × height in cm) - (4.330 × age)
                    self.bmr = round(447.593 + (9.247 * self.weight) + (3.098 * self.height) - (4.330 * age), 2)
                
                # Multiply by activity factor (1.55 for moderate activity)
                self.daily_calories = round(self.bmr * 1.55)

    @property
    def age(self):
        """Calculate age from date_of_birth"""
        if self.date_of_birth:
            today = datetime.utcnow().date()
            age = today.year - self.date_of_birth.year
            # Subtract one year if birthday hasn't occurred this year yet
            if (today.month, today.day) < (self.date_of_birth.month, self.date_of_birth.day):
                age -= 1
            return age
        return None
    
    def set_password(self, password):
        """Hash and set password"""
        self.password_hash = pbkdf2_sha256.hash(password)
        self.temp_password = None  # Clear temp password once real password is set
        self.password_changed = True
    
    def check_password(self, password):
        """Verify password"""
        if not self.password_hash:
            return False
        return pbkdf2_sha256.verify(password, self.password_hash)
    
    def generate_temp_password(self):
        """Generate a random temporary password"""
        # Generate 8-character alphanumeric password
        alphabet = string.ascii_uppercase + string.digits
        temp_pass = ''.join(secrets.choice(alphabet) for _ in range(8))
        self.set_password(temp_pass)  # Hash the password (this clears temp_password)
        # Set temp_password AFTER set_password (which clears it)
        self.temp_password = temp_pass
        self.password_changed = False
        return temp_pass

    def to_dict(self, include_temp_password=True):
        """Convert to dictionary
        
        Args:
            include_temp_password: If True, includes temp_password for staff viewing
                                  Set to False for client-facing endpoints
        """
        # Check if customer has active subscription
        from app.models.subscription import Subscription, SubscriptionStatus
        from datetime import date
        
        # Active subscription = status is ACTIVE AND (coins type OR not expired)
        has_active_subscription = db.session.query(
            db.exists().where(
                db.and_(
                    Subscription.customer_id == self.id,
                    Subscription.status == SubscriptionStatus.ACTIVE,
                    db.or_(
                        Subscription.subscription_type == 'coins',  # Coins never expire by date
                        Subscription.end_date >= date.today()  # Time-based must not be expired
                    )
                )
            )
        ).scalar()
        
        data = {
            'id': self.id,
            'full_name': self.full_name,
            'phone': self.phone,
            'email': self.email,
            'national_id': self.national_id,
            'date_of_birth': self.date_of_birth.isoformat() if self.date_of_birth else None,
            'age': self.age,
            'gender': self.gender.value if self.gender else None,
            'address': self.address,
            'height': self.height,
            'weight': self.weight,
            'bmi': self.bmi,
            'bmi_category': self.bmi_category,
            'bmr': self.bmr,
            'ideal_weight': self.ideal_weight,
            'daily_calories': self.daily_calories,
            'health_notes': self.health_notes,
            'qr_code': self.qr_code or f"customer_id:{self.id}",  # Generate QR code if not set
            'branch_id': self.branch_id,
            'branch_name': self.branch.name if self.branch else None,
            'is_active': self.is_active,
            'password_changed': self.password_changed,
            'preferred_language': self.preferred_language,
            'has_active_subscription': has_active_subscription,  # ✅ CRITICAL FIX
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
        
        # Only include temp_password for staff (not customers)
        # Only show if password hasn't been changed yet
        if include_temp_password and not self.password_changed:
            data['temp_password'] = self.temp_password
        
        return data
