with open('public/index.html', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('../../admin/login.html', '../admin/login.html')

with open('public/index.html', 'w', encoding='utf-8') as f:
    f.write(content)

print("Links updated successfully")