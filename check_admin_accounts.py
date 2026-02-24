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

# Main function to check admin accounts
def main():
    try:
        # Get Supabase configuration
        config = get_config()
        
        print("Connecting to Supabase...")
        supabase = create_client(config['url'], config['key'])
        
        # Check for admin accounts
        print("\nChecking for admin accounts...")
        response = supabase.table('users').select('id', 'email', 'full_name', 'role', 'created_at', 'is_active').eq('role', 'admin').execute()
        
        if response.data:
            print(f"\nFound {len(response.data)} admin account(s):")
            for user in response.data:
                print("\n--- Admin Account ---")
                print(f"Email: {user['email']}")
                print(f"Name: {user['full_name']}")
                print(f"User ID: {user['id']}")
                print(f"Created: {user['created_at']}")
                print(f"Active: {user['is_active']}")
        else:
            print("\nNo admin accounts found. Please create one.")
            
        # Check total users
        total_response = supabase.table('users').select('id', 'email', 'role').execute()
        if total_response.data:
            role_counts = {}
            for user in total_response.data:
                role = user['role']
                role_counts[role] = role_counts.get(role, 0) + 1
                
            print(f"\nTotal users: {len(total_response.data)}")
            print("User role distribution:")
            for role, count in role_counts.items():
                print(f"  {role}: {count} user(s)")
                
    except Exception as e:
        print(f"\nError: {e}")
        print("\nMake sure you have the 'supabase' Python package installed:")
        print("pip install supabase")

if __name__ == "__main__":
    main()