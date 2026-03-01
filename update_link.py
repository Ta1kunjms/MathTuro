import os
with open('public/index.html', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('modules.html', 'guest-modules.html')
with open('public/index.html', 'w', encoding='utf-8') as f:
    f.write(content)
print('Successfully updated modules.html to guest-modules.html')