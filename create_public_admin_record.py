import re
from supabase import create_client
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

# Main function to create the missing public.users record for admin
def main():
    try:
        # Get Supabase configuration
        config = get_config()
        
        print("Connecting to Supabase...")
        supabase = create_client(config['url'], config['key'])
        
        # Admin user details from auth.users table
        admin_id = "15c79e06-017f-48d5-acc0-a44f47d6d1d5"
        email = "admin@mathturo.com"
        full_name = "MathTuro Admin"
        
        print("\nChecking if admin record exists in public.users table...")
        check_response = supabase.table('users').select('*').eq('id', admin_id).execute()
        
        if check_response.data:
            print("\nAdmin record already exists in public.users table:")
            print(check_response.data[0])
        else:
            print("\nCreating admin record in public.users table...")
            
            # Try to create the record directly
            try:
                insert_response = supabase.table('users').insert({
                    'id': admin_id,
                    'email': email,
                    'full_name': full_name,
                    'role': 'admin',
                    'avatar_url': None,
                    'is_active': True,
                    'created_at': '2026-02-23 00:51:28.91259+00',
                    'updated_at': '2026-02-23 00:51:29.055923+00'
                }).execute()
                
                if insert_response.data:
                    print("\nSuccessfully created admin record in public.users table:")
                    print(insert_response.data[0])
                else:
                    print("\nError creating admin record:", insert_response.error)
                    
            except Exception as e:
                print(f"\nError creating admin record: {e}")
                print("\nThis might be due to Row-Level Security (RLS) policies.")
                print("Please try running the SQL script in create_admin_public_record.sql directly in the Supabase SQL Editor.")
        
        # Verify all admin accounts
        print("\n--- All Admin Accounts ---")
        admin_response = supabase.table('users').select('*').eq('role', 'admin').execute()
        
        if admin_response.data:
            print(f"Found {len(admin_response.data)} admin account(s):")
            for admin in admin_response.data:
                print()
                print(f"Email: {admin['email']}")
                print(f"Name: {admin['full_name']}")
                print(f"User ID: {admin['id']}")
                print(f"Role: {admin['role']}")
                print(f"Active: {admin['is_active']}")
                print(f"Created: {admin['created_at']}")
        else:
            print("No admin accounts found in public.users table")
            
    except Exception as e:
        print(f"\nError: {e}")
        print("\nMake sure you have the 'supabase' Python package installed:")
        print("pip install supabase")

if __name__ == "__main__":
    main()
