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

# Main function to fix admin account
def main():
    try:
        # Get Supabase configuration
        config = get_config()
        
        print("Connecting to Supabase...")
        supabase = create_client(config['url'], config['key'])
        
        # Admin account details
        email = "admin@mathturo.com"
        full_name = "MathTuro Admin"
        
        print(f"Checking for admin account: {email}")
        
        # Check if user exists in public.users table
        check_response = supabase.table('users').select('*').eq('email', email).execute()
        
        if check_response.data:
            # User exists, update role to admin
            print("User exists, updating to admin role...")
            update_response = supabase.table('users').update({
                'role': 'admin',
                'is_active': True,
                'updated_at': datetime.now().isoformat()
            }).eq('email', email).execute()
            
            if update_response.error:
                raise Exception(update_response.error['message'])
                
            print("Successfully updated user to admin role")
        else:
            print("User not found in public.users table. Please create an admin account using the register form.")
        
    except Exception as e:
        print(f"Error: {e}")
        print("\nMake sure you have the 'supabase' Python package installed:")
        print("pip install supabase")

if __name__ == "__main__":
    main()
