# Deploying Gym Management System to PythonAnywhere

This guide will help you deploy the Flask backend to PythonAnywhere.

## Prerequisites

1. Create a free account at [PythonAnywhere](https://www.pythonanywhere.com/)
2. Your GitHub repository: `https://github.com/yamenmod9/gym-management-system.git`

## Step 1: Clone Your Repository

Open a Bash console on PythonAnywhere and run:

```bash
cd ~
git clone https://github.com/yamenmod9/gym-management-system.git
cd gym-management-system
```

## Step 2: Create Virtual Environment

```bash
python3.11 -m venv venv
source venv/bin/activate
```

## Step 3: Install Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

## Step 4: Create Environment Variables

```bash
cp .env.example .env
nano .env
```

Edit the `.env` file with your production settings:
```
FLASK_ENV=production
SECRET_KEY=your-super-secret-key-change-this-in-production
JWT_SECRET_KEY=your-jwt-secret-key-change-this-in-production
DATABASE_URL=sqlite:///gym_management.db
```

Press `CTRL+X`, then `Y`, then `ENTER` to save.

## Step 5: Initialize Database

```bash
python -c "from app import create_app; from app.extensions import db; app = create_app('production'); app.app_context().push(); db.create_all(); print('Database created!')"
```

## Step 6: Seed Database (Optional)

```bash
python seed.py
```

## Step 7: Configure Web App

1. Go to the **Web** tab in PythonAnywhere
2. Click **Add a new web app**
3. Choose **Manual configuration** (not Flask)
4. Choose **Python 3.11**

## Step 8: Configure WSGI File

1. Click on the **WSGI configuration file** link
2. Delete all content and replace with:

```python
import sys
import os

# Add your project directory to the sys.path
project_home = '/home/YOUR_USERNAME/gym-management-system'
if project_home not in sys.path:
    sys.path = [project_home] + sys.path

# Set environment variables
os.environ['FLASK_ENV'] = 'production'

# Import the Flask app
from app import create_app
application = create_app('production')
```

**Replace `YOUR_USERNAME` with your actual PythonAnywhere username!**

## Step 9: Configure Virtual Environment

1. In the **Web** tab, scroll to **Virtualenv** section
2. Enter: `/home/YOUR_USERNAME/gym-management-system/venv`
3. Click the checkmark

## Step 10: Reload Your Web App

1. Scroll to the top of the **Web** tab
2. Click the green **Reload** button
3. Your app will be available at: `https://YOUR_USERNAME.pythonanywhere.com`

## Testing Your API

Once deployed, test your API at:
- Base URL: `https://YOUR_USERNAME.pythonanywhere.com`
- Test Page: `https://YOUR_USERNAME.pythonanywhere.com/test`
- Privacy Policy: `https://YOUR_USERNAME.pythonanywhere.com/privacy-policy`
- API Endpoints: `https://YOUR_USERNAME.pythonanywhere.com/api/...`

## Common Issues & Solutions

### Issue: Import errors
**Solution:** Make sure the virtual environment path is correct in the Web tab.

### Issue: 500 Internal Server Error
**Solution:** Check error logs in the **Web** tab → **Error log** link.

### Issue: Database not found
**Solution:** Make sure you ran the database initialization command in Step 5.

### Issue: CORS errors
**Solution:** Update `CORS_ORIGINS` in `app/config.py` to include your frontend URL.

## Environment Variables for Production

Remember to use strong secret keys in production:

```python
# Generate secure keys using:
python -c "import secrets; print(secrets.token_hex(32))"
```

## Updating Your Deployment

When you make changes to your code:

```bash
cd ~/gym-management-system
git pull origin main
source venv/bin/activate
pip install -r requirements.txt  # if dependencies changed
# Reload your web app from the Web tab
```

## API Documentation

Your interactive API documentation will be available at:
`https://YOUR_USERNAME.pythonanywhere.com/test`

## Support

- PythonAnywhere Help: https://help.pythonanywhere.com/
- PythonAnywhere Forums: https://www.pythonanywhere.com/forums/

---

**Note:** Free PythonAnywhere accounts have limitations:
- Limited daily CPU quota
- Can only access whitelisted sites (GitHub is included)
- One web app only
- Consider upgrading for production use
