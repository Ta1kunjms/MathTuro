with open('public/developer.html', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('taikun.merchandise@gmail.com', 'tycoonjamesflores@gmail.com')
content = content.replace('+639123640851', '+639123456789')  # Replace with Tycoon James Flores' actual phone number

with open('public/developer.html', 'w', encoding='utf-8') as f:
    f.write(content)

print("Contact information updated successfully")