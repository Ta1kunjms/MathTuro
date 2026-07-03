import os, re, glob

ROOT = r'd:\Personal_Projects\MathTuro'
FILES = glob.glob(os.path.join(ROOT, '**', '*.html'), recursive=True)
FILES = [f for f in FILES if 'node_modules' not in f]

def css_rel_path(filepath):
    rel = os.path.relpath(filepath, ROOT)
    parts = rel.replace('\\', '/').split('/')
    depth = len(parts) - 1
    return '../' * depth + 'dist/styles.css'

changed = 0
skipped = 0

for filepath in FILES:
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    original = content
    css_path = css_rel_path(filepath)

    # 1. Remove the CDN tailwind script tag
    content = re.sub(
        r'[ \t]*<script src="https://cdn\.tailwindcss\.com"></script>\r?\n',
        '',
        content
    )

    # 2. Remove the inline tailwind.config script block
    content = re.sub(
        r'[ \t]*<script>\r?\n\s*tailwind\.config\s*=\s*\{.*?\}\s*</script>\r?\n',
        '',
        content,
        flags=re.DOTALL
    )

    # 3. Insert <link> to compiled CSS after the viewport meta tag if not already present
    link_tag = f'    <link rel="stylesheet" href="{css_path}">'
    if 'dist/styles.css' not in content:
        content = re.sub(
            r'(<meta name="viewport"[^>]+>)',
            r'\1\n' + link_tag,
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
