import re
from supabase import create_client

# Load configuration from config.js
def get_config():
    with open('public/shared/js/config.js', 'r') as f:
        config_content = f.read()
    
    url_match = re.search(r'SUPABASE_URL:\s*\'([^\']+)\'', config_content)
    key_match = re.search(r'SUPABASE_ANON_KEY:\s*\'([^\']+)\'', config_content)
    
    if url_match and key_match:
        return {
            'url': url_match.group(1),
            'key': key_match.group(1)
        }
    else:
        raise Exception("Could not find Supabase configuration in config.js")

# Create admin account
def create_admin_account(email, password, full_name):
    try:
        config = get_config()
        supabase = create_client(config['url'], config['key'])
        
        print("Creating admin account...")
        
        # Create user in auth.users
        auth_response = supabase.auth.sign_up({
            "email": email,
            "password": password,
            "options": {
                "data": {
                    "full_name": full_name,
                    "role": "admin"
                }
            }
        })
        
        if auth_response.user:
            print(f"Successfully created user: {auth_response.user.email}")
            
            # Create corresponding entry in public.users table
            user_response = supabase.table('users').insert({
                'id': auth_response.user.id,
                'email': email,
                'full_name': full_name,
                'role': 'admin',
                'is_active': True
            }).execute()
            
            if user_response.data:
                print("Admin account created successfully!")
                return True
            else:
                print(f"Error creating user record: {user_response.error}")
                return False
        else:
            print(f"Error creating user: {auth_response.error}")
            return False
            
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 4:
        print("Usage: python create_admin_direct.py <email> <password> <full_name>")
        print("\nExample:")
        print("python create_admin_direct.py admin@example.com Password123 'System Administrator'")
    else:
        email = sys.argv[1]
        password = sys.argv[2]
        full_name = ' '.join(sys.argv[3:])
        
        success = create_admin_account(email, password, full_name)
        
        if success:
            print("\nAdmin account created successfully!")
            print(f"Email: {email}")
            print(f"Full Name: {full_name}")
            print(f"Role: Admin")
        else:
            print("\nFailed to create admin account.")