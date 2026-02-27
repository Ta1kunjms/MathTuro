import re
from pathlib import Path

def main():
    try:
        # Read the SQL script
        sql_path = Path('create_admin_public_record.sql')
        if not sql_path.exists():
            print("Error: create_admin_public_record.sql not found")
            return
            
        with open(sql_path, 'r') as f:
            sql_content = f.read()
            
        print("=" * 60)
        print("ADMIN ACCOUNT FIX SQL SCRIPT")
        print("=" * 60)
        print()
        print("Please copy the following SQL and run it in your Supabase SQL Editor:")
        print()
        print("=" * 60)
        print(sql_content)
        print("=" * 60)
        print()
        print("=" * 60)
        print("INSTRUCTIONS:")
        print("=" * 60)
        print()
        print("1. Go to your Supabase project dashboard")
        print("2. Click on 'SQL Editor' in the left sidebar")
        print("3. Click 'New Query'")
        print("4. Paste the SQL script above")
        print("5. Click 'Run'")
        print()
        print("This will check if the admin record exists and create it if needed.")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
