# Admin Account Creation Guide

This guide explains how to create an admin account for the Learning Management System. There are two main methods:

## Method 1: Using the Web Interface (Recommended for Beginners)

1. Open your browser and go to: `http://localhost:8000/create-admin.html`
2. Fill in the form with:
   - **Email**: admin@example.com (or your own email)
   - **Full Name**: System Administrator (or your name)
   - **Password**: A strong password (at least 8 characters)
3. Click "Create Admin Account"
4. The user will receive a confirmation email
5. Once confirmed, the account will have full admin privileges

## Method 2: Using SQL Script (For Advanced Users)

1. Go to your Supabase project dashboard
2. Navigate to "SQL Editor"
3. Copy and paste the content of `create_admin_account.sql`
4. Replace the placeholder values with your desired email and password
5. Click "Run"

## Method 3: Using Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to "Authentication" > "Users"
3. Click "Add user"
4. Fill in the details:
   - Email: admin@example.com
   - Password: your-strong-password
5. Click "Create user"
6. Then run this SQL to update the role:

```sql
UPDATE public.users 
SET role = 'admin', full_name = 'System Administrator'
WHERE email = 'admin@example.com';
```

## Verifying Admin Account

After creating the admin account, you can verify it by:

1. Using the "Check Existing Admin Accounts" button on the web interface
2. Running this SQL query:

```sql
SELECT id, email, role, full_name, is_active, created_at
FROM public.users
WHERE role = 'admin';
```

## Admin Login

Once the admin account is created, you can login at:
`http://localhost:8000/admin/login.html`

## Troubleshooting

- **Email not received**: Check your spam folder or verify your email provider settings
- **Password issues**: Make sure you use a strong password (8+ characters, mixed types)
- **Permission errors**: Ensure you're using an account with sufficient privileges to create users
- **Account not created**: Check the browser console for error messages

## Security Considerations

1. Always use strong passwords for admin accounts
2. Never share admin credentials
3. Enable two-factor authentication if available
4. Regularly rotate admin passwords
5. Monitor admin account activity