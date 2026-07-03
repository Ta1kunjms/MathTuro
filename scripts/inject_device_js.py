import os, re, glob

ROOT = r'd:\Personal_Projects\MathTuro'
FILES = glob.glob(os.path.join(ROOT, '**', '*.html'), recursive=True)
FILES = [f for f in FILES if 'node_modules' not in f]

def device_rel_path(filepath):
    rel = os.path.relpath(filepath, ROOT)
    parts = rel.replace('\\', '/').split('/')
    depth = len(parts) - 1
    return '../' * depth + 'shared/js/device.js'

changed = 0
skipped = 0

for filepath in FILES:
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    if 'shared/js/device.js' in content:
        skipped += 1
        continue

    original = content
    device_path = device_rel_path(filepath)
    script_tag = f'    <script src="{device_path}"></script>'

    # Insert immediately after the compiled CSS <link> tag
    content = re.sub(
        r'(<link rel="stylesheet" href="[^"]*dist/styles\.css">)',
        r'\1\n' + script_tag,
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
        print(f'  No CSS link found, skipped: {os.path.relpath(filepath, ROOT)}')

print(f'\nDone. Changed: {changed}, Skipped: {skipped}')
