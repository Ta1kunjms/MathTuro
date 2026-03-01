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

# Main function to check and fix admin account
def main():
    try:
        # Get Supabase configuration
        config = get_config()
        
        print("Connecting to Supabase...")
        
        headers = {
            'apikey': config['key'],
            'Authorization': f'Bearer {config["key"]}',
            'Content-Type': 'application/json'
        }
        
        # Admin account details
        admin_data = {
            'id': '15c79e06-017f-48d5-acc0-a44f47d6d1d5',
            'email': 'admin@mathturo.com',
            'full_name': 'MathTuro Admin',
            'role': 'admin',
            'avatar_url': None,
            'is_active': True
        }
        
        # Check if admin exists in public.users table
        print("\nChecking public.users table for admin@mathturo.com...")
        
        check_url = f"{config['url']}/rest/v1/users?email=eq.{admin_data['email']}"
        check_response = requests.get(check_url, headers=headers)
        
        if check_response.status_code == 200 and len(check_response.json()) > 0:
            print("\nAdmin account already exists in public.users table:")
            print(check_response.json()[0])
        else:
            print("\nAdmin account not found in public.users table.")
            
            # Try to create admin account (this will fail if RLS is enabled)
            print("\nTrying to create admin account...")
            create_url = f"{config['url']}/rest/v1/users?select=*"
            
            try:
                create_response = requests.post(
                    create_url,
                    headers=headers,
                    json=admin_data
                )
                
                if create_response.status_code == 201:
                    print("\nSuccessfully created admin account in public.users table:")
                    print(create_response.json()[0])
                else:
                    print(f"\nError creating admin account: {create_response.status_code} - {create_response.text}")
                    
                    # If RLS error, provide SQL workaround
                    if create_response.status_code == 401 and 'row-level security' in create_response.text.lower():
                        print("\nRLS policy is blocking the insert.")
                        print("Run this SQL in Supabase SQL Editor:")
                        print("\n-- Step 1: Disable RLS temporarily")
                        print("ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;")
                        print("\n-- Step 2: Create admin account")
                        print("INSERT INTO public.users (")
                        print("    id, email, full_name, role, avatar_url, is_active, created_at, updated_at")
                        print(") VALUES (")
                        print("    '" + admin_data['id'] + "', ")
                        print("    '" + admin_data['email'] + "', ")
                        print("    '" + admin_data['full_name'] + "', ")
                        print("    '" + admin_data['role'] + "', ")
                        print("    " + ("NULL" if admin_data['avatar_url'] is None else "'" + admin_data['avatar_url'] + "'") + ", ")
                        print("    " + str(admin_data['is_active']) + ", ")
                        print("    NOW(), ")
                        print("    NOW()")
                        print(") ON CONFLICT (id) DO NOTHING;")
                        print("\n-- Step 3: Re-enable RLS")
                        print("ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;")
                        print("\n-- Step 4: Verify")
                        print("SELECT * FROM public.users WHERE role = 'admin';")
                    
            except Exception as e:
                print(f"\nError: {e}")
        
        # Verify admin accounts
        print("\nVerifying admin accounts...")
        verify_url = f"{config['url']}/rest/v1/users?role=eq.admin"
        verify_response = requests.get(verify_url, headers=headers)
        
        if verify_response.status_code == 200:
            admins = verify_response.json()
            print(f"\nFound {len(admins)} admin account(s):")
            for admin in admins:
                print(f"\nEmail: {admin.get('email', 'N/A')}")
                print(f"Name: {admin.get('full_name', 'N/A')}")
                print(f"Role: {admin.get('role', 'N/A')}")
                print(f"Active: {admin.get('is_active', 'N/A')}")
        else:
            print(f"\nError verifying admin accounts: {verify_response.status_code} - {verify_response.text}")
            
        # Check if user exists in auth system by trying to send reset password email
        print("\nChecking if user exists in auth system...")
        reset_url = f"{config['url']}/auth/v1/recover"
        reset_data = {
            "email": admin_data['email'],
            "redirect_to": "http://localhost:3000/reset-password.html"
        }
        
        try:
            reset_response = requests.post(reset_url, headers=headers, json=reset_data)
            
            if reset_response.status_code == 200:
                print("User exists in auth system! A password reset email has been sent to admin@mathturo.com")
            else:
                print(f"User may not exist in auth system: {reset_response.status_code} - {reset_response.text}")
                
                # If user doesn't exist in auth system, try to create them
                print("\nTrying to create user in auth system...")
                sign_up_url = f"{config['url']}/auth/v1/signup"
                sign_up_data = {
                    "email": admin_data['email'],
                    "password": "Admin123!",
                    "options": {
                        "data": {
                            "full_name": admin_data['full_name'],
                            "role": admin_data['role']
                        },
                        "emailRedirectTo": "http://localhost:3000"
                    }
                }
                
                sign_up_response = requests.post(sign_up_url, headers=headers, json=sign_up_data)
                
                if sign_up_response.status_code == 200:
                    print("Successfully created user in auth system!")
                    print(sign_up_response.json())
                else:
                    print(f"Error creating user in auth system: {sign_up_response.status_code} - {sign_up_response.text}")
                    
        except Exception as e:
            print(f"\nError checking auth system: {e}")
            
    except Exception as e:
        print(f"\nError: {e}")
        print("\nMake sure you have the 'requests' Python package installed:")
        print("pip install requests")

if __name__ == "__main__":
    main()
