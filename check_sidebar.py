import os

admin_dir = 'admin'
for filename in os.listdir(admin_dir):
    if filename.endswith('.html'):
        filepath = os.path.join(admin_dir, filename)
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                has_sidebar = 'sidebar.js' in content
                status = 'included' if has_sidebar else 'missing'
                print(f"{filepath.ljust(30)}: {status}")
        except Exception as e:
            print(f"{filepath.ljust(30)}: Error - {e}")
