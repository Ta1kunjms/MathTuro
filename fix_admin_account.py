import re
from supabase import create_client

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

# Main function to fix admin account
def main():
    try:
        # Get Supabase configuration
        config = get_config()
        
        print("Connecting to Supabase...")
        supabase = create_client(config['url'], config['key'])
        
        # Check if admin exists in public.users table
        print("\nChecking public.users table for admin@mathturo.com...")
        response = supabase.table('users').select('*').eq('email', 'admin@mathturo.com').execute()
        
        if response.data:
            print("\nAdmin account already exists in public.users table:")
            print(response.data[0])
        else:
            print("\nAdmin account not found in public.users table. Creating record...")
            
            # Create admin record in public.users table
            admin_data = {
                'id': '15c79e06-017f-48d5-acc0-a44f47d6d1d5',
                'email': 'admin@mathturo.com',
                'full_name': 'MathTuro Admin',
                'role': 'admin',
                'avatar_url': None,
                'is_active': True,
                'created_at': '2026-02-23 00:51:28.91259+00',
                'updated_at': '2026-02-23 00:51:29.055923+00'
            }
            
            insert_response = supabase.table('users').insert(admin_data).execute()
            
            if insert_response.data:
                print("\nSuccessfully created admin account in public.users table:")
                print(insert_response.data[0])
            else:
                print("\nError creating admin account:", insert_response.error)
        
        # Verify the fix
        print("\nVerifying admin accounts...")
        admin_response = supabase.table('users').select('*').eq('role', 'admin').execute()
        
        if admin_response.data:
            print(f"\nFound {len(admin_response.data)} admin account(s):")
            for admin in admin_response.data:
                print(f"\nEmail: {admin['email']}")
                print(f"Name: {admin['full_name']}")
                print(f"Role: {admin['role']}")
                print(f"Active: {admin['is_active']}")
        else:
            print("\nNo admin accounts found in public.users table.")
            
    except Exception as e:
        print(f"\nError: {e}")
        print("\nMake sure you have the 'supabase' Python package installed:")
        print("pip install supabase")

if __name__ == "__main__":
    main()
