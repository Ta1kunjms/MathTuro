import re
from supabase import create_client
import uuid
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

# Main function to create admin account automatically
def main():
    try:
        # Get Supabase configuration
        config = get_config()
        
        print("Connecting to Supabase...")
        supabase = create_client(config['url'], config['key'])
        
        # Default admin account details
        email = "admin@mathturo.com"
        full_name = "MathTuro Admin"
        password = "Admin1234!"
        
        print(f"\nCreating admin account:")
        print(f"Email: {email}")
        print(f"Name: {full_name}")
        print(f"Password: {password}")
        
        print("\nCreating admin account...")
        
        # Step 1: Create user in Supabase Auth
        print("1. Creating user in auth.users table...")
        auth_response = supabase.auth.sign_up({
            "email": email,
            "password": password,
            "options": {
                "data": {
                    "full_name": full_name,
                    "role": "admin"
                },
                "emailRedirectTo": "http://localhost:3000"
            }
        })
        
        if 'error' in auth_response and auth_response['error']:
            raise Exception(auth_response['error']['message'])
            
        user = auth_response['data']['user']
        print(f"   Success! User ID: {user['id']}")
        
        # Step 2: Wait for user to be created (there might be a slight delay)
        import time
        print("2. Waiting for user to be created...")
        time.sleep(2)
        
        # Step 3: Create or update user in public.users table
        print("3. Creating record in public.users table...")
        
        # Check if user exists in public.users table
        check_response = supabase.table('users').select('*').eq('id', user['id']).execute()
        
        if check_response.data:
            # Update existing user
            update_response = supabase.table('users').update({
                'email': email,
                'full_name': full_name,
                'role': 'admin',
                'is_active': True,
                'updated_at': datetime.now().isoformat()
            }).eq('id', user['id']).execute()
            
            if update_response.error:
                raise Exception(update_response.error['message'])
                
            print("   Updated existing user record")
        else:
            # Create new user
            insert_response = supabase.table('users').insert({
                'id': user['id'],
                'email': email,
                'full_name': full_name,
                'role': 'admin',
                'avatar_url': None,
                'is_active': True,
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }).execute()
            
            if insert_response.error:
                raise Exception(insert_response.error['message'])
                
            print("   Created new user record")
        
        # Verify the admin account
        print("\nVerifying admin account...")
        admin_response = supabase.table('users').select('*').eq('role', 'admin').execute()
        
        if admin_response.data:
            print(f"\nSuccessfully created admin account!")
            print(f"\n--- Admin Account Details ---")
            for admin in admin_response.data:
                print(f"Email: {admin['email']}")
                print(f"Name: {admin['full_name']}")
                print(f"User ID: {admin['id']}")
                print(f"Role: {admin['role']}")
                print(f"Active: {admin['is_active']}")
                print(f"Created: {admin['created_at']}")
                print()
        else:
            print("\nError: Admin account not found after creation")
            
    except Exception as e:
        print(f"\nError: {e}")
        print("\nMake sure you have the 'supabase' Python package installed:")
        print("pip install supabase")

if __name__ == "__main__":
    main()
