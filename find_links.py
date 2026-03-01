import re
with open('public/index.html', 'r', encoding='utf-8') as f:
    content = f.read()

hrefs = re.findall(r'href=["\'](.*?)["\']', content)
for href in hrefs:
    if href and not href.startswith('#') and not href.startswith('http'):
        print(f'Check: {href}')