import re
import requests
import json
from datetime import datetime

# Load configuration from config.js
def get_config():
    with open('public/shared/js/config.js', 'r') as f:
        config_content = f.read()
    
    # Extract SUPABASE_URL and SUPABASE_ANON_KEY
    url_match = re.search(r'SUPABASE_URL:\s*\'([^\']+)\'', config_content)
    key_match = re.search(r'SUPABASE_ANON_KEY:\s*\'([^\']+)\'', config_content)
    
    if url_match and key_match:
        return {
            'url': url_match.group(1),
            'key': key_match.group(1)
        }
    else:
        raise Exception("Could not find Supabase configuration in config.js")

# Main function to create admin account bypassing RLS
def main():
    try:
        # Get Supabase configuration
        config = get_config()
        
        print("Connecting to Supabase...")
        
        # Admin account details
        email = "admin@mathturo.com"
        full_name = "MathTuro Admin"
        user_id = "15c79e06-017f-48d5-acc0-a44f47d6d1d5"  # This is the same as in the fix_admin_account.py
        
        print(f"Creating admin account: {email}")
        print(f"Full name: {full_name}")
        print(f"User ID: {user_id}")
        
        # Create user in public.users table
        print("\nCreating admin record in public.users table...")
        
        # Use the Supabase REST API to create the user
        headers = {
            'apikey': config['key'],
            'Authorization': f'Bearer {config["key"]}',
            'Content-Type': 'application/json'
        }
        
        user_data = {
            'id': user_id,
            'email': email,
            'full_name': full_name,
            'role': 'admin',
            'avatar_url': None,
            'is_active': True,
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat()
        }
        
        url = f"{config['url']}/rest/v1/users"
        response = requests.post(url, json=user_data, headers=headers, params={'select': '*'})
        
        if response.status_code == 201:
            print("\nSuccessfully created admin account!")
            print(f"Response: {response.json()}")
        else:
            print(f"\nError: {response.status_code} - {response.text}")
            
            # If we get 42501 (RLS error), try to disable RLS temporarily (not recommended, but for testing)
            if response.status_code == 42501:
                print("\nRLS policy is blocking the insert.")
                print("Try running the following SQL in Supabase SQL Editor:")
                print(f"""
-- Bypass RLS temporarily to create admin account
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Create admin account
INSERT INTO public.users (
    id, email, full_name, role, avatar_url, is_active, created_at, updated_at
) VALUES (
    '{user_id}', 
    '{email}', 
    '{full_name}', 
    'admin', 
    NULL, 
    TRUE, 
    NOW(), 
    NOW()
);

-- Enable RLS again
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
""")
                
    except Exception as e:
        print(f"\nError: {e}")
        print("\nMake sure you have the 'requests' Python package installed:")
        print("pip install requests")

if __name__ == "__main__":
    main()
