import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Base configuration"""
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'jwt-secret-key-change-in-production')
    
    # Database
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'sqlite:///gym_management.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    # pool_pre_ping pings each connection before reuse so a connection the DB
    # server already dropped (MySQL's wait_timeout, common on shared hosting
    # like PythonAnywhere) gets silently replaced instead of surfacing as a
    # 500 on the next request. pool_recycle forces a refresh before that
    # timeout is hit at all.
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_pre_ping': True,
        'pool_recycle': 280,
    }
    
    # JWT Configuration
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=12)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    JWT_TOKEN_LOCATION = ['headers']
    JWT_HEADER_NAME = 'Authorization'
    JWT_HEADER_TYPE = 'Bearer'
    
    # Pagination
    ITEMS_PER_PAGE = 20
    MAX_ITEMS_PER_PAGE = 100
    
    # File Upload (for future expansion)
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB
    
    # CORS Configuration
    # Allow all origins for development. Restrict in production.
    CORS_ORIGINS = '*'  # or ['http://localhost:3000', 'http://localhost:5000'] for specific origins


class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    TESTING = False


class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    TESTING = False
    # Override with environment variables in production
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'sqlite:///gym_management.db')
    # CORS: Allow all origins for now, restrict later for security
    # CORS_ORIGINS = ['https://your-frontend-domain.com', 'https://your-other-domain.com']
    CORS_ORIGINS = '*'  # Change to specific origins in production for better security


class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///test_gym.db'
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=5)


config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
