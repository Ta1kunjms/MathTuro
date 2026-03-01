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

# Main function to create admin account directly with predefined credentials (no input required)
def main():
    try:
        # Get Supabase configuration
        config = get_config()
        
        print("Connecting to Supabase...")
        supabase = create_client(config['url'], config['key'])
        
        # Predefined admin account details
        email = "admin@mathturo.com"
        full_name = "MathTuro Admin"
        
        print("\nCreating admin account with email: " + email)
        print("Full name: " + full_name)
        
        # Step 1: Check if user exists in auth system
        print("\n1. Checking if user exists in auth system...")
        
        # We already know the user is registered (from previous error)
        
        # Step 2: Check if user exists in public.users table
        print("\n2. Checking if user exists in public.users table...")
        
        # Get user by email from auth system
        # Note: This is a workaround since we can't directly query auth.users via REST API
        
        # Try to login to get user ID
        print("\nTrying to login to get user ID...")
        
        try:
            login_response = supabase.auth.sign_in_with_password({
                "email": email,
                "password": "Admin123!"
            })
            
            if login_response and 'data' in login_response and 'user' in login_response['data']:
                user_id = login_response['data']['user']['id']
                print("Successfully logged in! User ID: " + user_id)
                
                # Check if user exists in public.users
                check_response = supabase.table('users').select('*').eq('id', user_id).execute()
                
                if check_response.data:
                    print("User already exists in public.users table")
                    print(check_response.data[0])
                else:
                    print("User not found in public.users table. Creating...")
                    
                    # Try to create user in public.users
                    try:
                        insert_response = supabase.table('users').insert({
                            'id': user_id,
                            'email': email,
                            'full_name': full_name,
                            'role': 'admin',
                            'avatar_url': None,
                            'is_active': True,
                            'created_at': datetime.now().isoformat(),
                            'updated_at': datetime.now().isoformat()
                        }).execute()
                        
                        if insert_response.error:
                            print("Error creating user in public.users: " + str(insert_response.error))
                            
                            # If RLS error, provide SQL workaround
                            if 'row-level security' in str(insert_response.error).lower():
                                print("\nRLS policy is blocking the insert.")
                                print("Run this SQL in Supabase SQL Editor:")
                                print("\n-- Step 1: Disable RLS temporarily")
                                print("ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;")
                                print("\n-- Step 2: Create admin account")
                                print("INSERT INTO public.users (")
                                print("    id, email, full_name, role, avatar_url, is_active, created_at, updated_at")
                                print(") VALUES (")
                                print("    '" + user_id + "', ")
                                print("    '" + email + "', ")
                                print("    '" + full_name + "', ")
                                print("    'admin', ")
                                print("    NULL, ")
                                print("    TRUE, ")
                                print("    NOW(), ")
                                print("    NOW()")
                                print(") ON CONFLICT (id) DO NOTHING;")
                                print("\n-- Step 3: Re-enable RLS")
                                print("ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;")
                                print("\n-- Step 4: Verify")
                                print("SELECT * FROM public.users WHERE role = 'admin';")
                        else:
                            print("Successfully created user in public.users table")
                            print(insert_response.data[0])
                    
                    except Exception as e:
                        print("Error inserting into public.users: " + str(e))
                        
            else:
                print("Login failed: User not found or invalid credentials")
                
        except Exception as e:
            print("Login error: " + str(e))
            
    except Exception as e:
        print("Error: " + str(e))
        print("\nMake sure you have the 'supabase' Python package installed:")
        print("pip install supabase")

if __name__ == "__main__":
    main()
