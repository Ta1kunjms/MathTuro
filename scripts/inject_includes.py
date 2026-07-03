import os, re, glob

ROOT = r'd:\Personal_Projects\MathTuro'

# Target folders and corresponding role-based mobile nav name
DIRECTORIES = {
    'student': 'nav-mobile-student',
    'teacher': 'nav-mobile-teacher',
    'admin': 'nav-mobile-admin'
}

changed = 0
skipped = 0

for folder, partial_name in DIRECTORIES.items():
    folder_path = os.path.join(ROOT, folder)
    files = glob.glob(os.path.join(folder_path, '*.html'))
    
    for filepath in files:
        # Skip login pages in subdirectories (like admin/login.html if it exists)
        filename = os.path.basename(filepath)
        if filename == 'login.html' or filename == 'register.html':
            skipped += 1
            continue
            
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            
        original = content
        
        # 1. Inject the data-include div after <body>
        # We look for <body ...>
        include_tag = f'\n    <!-- Mobile bottom navigation -->\n    <div data-include="{partial_name}" data-depth="../"></div>\n'
        if 'data-include="' not in content:
            content = re.sub(
                r'(<body[^>]*>)',
                r'\1' + include_tag,
                content,
                count=1
            )
            
        # 2. Inject the script tag for includes.js at the bottom before </body> or with other script tags
        script_tag = '    <script src="../shared/js/includes.js"></script>\n'
        if 'shared/js/includes.js' not in content:
            # Inject before the first sibling script inside <!-- Scripts --> or right before </body>
            if '<!-- Scripts -->' in content:
                content = re.sub(
                    r'(<!-- Scripts -->)',
                    r'\1\n' + script_tag,
                    content,
                    count=1
                )
            else:
                # Fallback to before </body>
                content = re.sub(
                    r'(</body>)',
                    script_tag + r'\1',
                    content,
                    count=1
                )
                
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            changed += 1
            print(f'  Updated: {os.path.relpath(filepath, ROOT)}')
        else:
            skipped += 1

print(f'\nDone. Changed: {changed}, Skipped: {skipped}')
