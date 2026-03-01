import requests
import json

# Supabase configuration
SUPABASE_URL = 'https://ynkzcybctsstpqxdoweq.supabase.co'
SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlua3pjeWJjdHNzdHBxeGRvd2VxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk4NzI1NjAsImV4cCI6MjA4NTQ0ODU2MH0.ZXdFcLmSmgaikZrA9MpP6d9enp4rjz_9nuiTpwm9n2k'

# Headers
headers = {
    'apikey': SUPABASE_ANON_KEY,
    'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
    'Content-Type': 'application/json'
}

# Test 1: Check if we can connect to Supabase and get users
print("Testing Supabase connection...")

try:
    # Get all users
    response = requests.get(
        f'{SUPABASE_URL}/rest/v1/users?select=*',
        headers=headers
    )
    
    if response.status_code == 200:
        users = response.json()
        print(f"✅ Success! Found {len(users)} users")
        
        # Count users by role
        role_counts = {}
        for user in users:
            role = user.get('role', 'unknown')
            role_counts[role] = role_counts.get(role, 0) + 1
        
        print("\nUsers by role:")
        for role, count in role_counts.items():
            print(f"  {role}: {count}")
    else:
        print(f"❌ Error: {response.status_code} - {response.text}")

except Exception as e:
    print(f"❌ Error: {str(e)}")

# Test 2: Check if we can get modules
print("\n\nTesting modules table...")
try:
    response = requests.get(
        f'{SUPABASE_URL}/rest/v1/modules?select=*',
        headers=headers
    )
    
    if response.status_code == 200:
        modules = response.json()
        print(f"✅ Success! Found {len(modules)} modules")
    else:
        print(f"❌ Error: {response.status_code} - {response.text}")

except Exception as e:
    print(f"❌ Error: {str(e)}")

# Test 3: Check if we can get lessons{