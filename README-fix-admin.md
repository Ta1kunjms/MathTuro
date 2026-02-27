# Fix Admin Account Issue

## Problem Summary
There is an admin account in `auth.users` table (admin@mathturo.com) but it's missing from `public.users` table. This prevents the admin from accessing the dashboard.

## Solution Options

### Option 1: Run SQL Script in Supabase SQL Editor (Recommended)

#### Step 1: Copy the SQL Script
1. Open `create_admin_public_record.sql` in a text editor
2. Copy all the content

#### Step 2: Run in Supabase SQL Editor
1. Go to your Supabase project dashboard
2. Click on "SQL Editor" in the left sidebar
3. Click "New Query"
4. Paste the copied SQL script
5. Click "Run"

#### Step 3: Verify the Fix
1. After running, you should see the admin record in the results
2. Try logging in to the admin dashboard at `http://localhost:3000/admin/dashboard.html`

### Option 2: Use the Fix Admin Record Page

1. Open your browser and go to `http://localhost:3000/fix-admin-record.html`
2. Click the "Fix Admin Record" button
3. If successful, you'll see a success message
4. If you get an RLS error, use Option 1 instead

### Option 3: Check Admin Account Status

You can check if there are any admin accounts using Python:

```bash
python check_admin_accounts.py
```

## Admin Account Information

- **Email:** admin@mathturo.com
- **User ID:** 15c79e06-017f-48d5-acc0-a44f47d6d1d5
- **Role:** admin
- **Password:** (not stored in plain text - you should know this from when the account was created)

## If You Need to Reset the Password

1. Go to `http://localhost:3000/reset-password.html`
2. Enter admin@mathturo.com
3. Click "Send Reset Email"
4. Check your email for the reset link

## If You Need to Create a New Admin Account

1. Go to `http://localhost:3000/create-admin.html`
2. Fill out the form with new email, name, and password
3. Click "Create Admin Account"
4. The new admin will receive a confirmation email

## Troubleshooting

### RLS Policy Errors
If you get "new row violates row-level security policy for table 'users'", this means the anonymous user doesn't have permission to insert into public.users. Use Option 1 to run the SQL directly.

### No Admin Accounts Found
If `check_admin_accounts.py` still shows "No admin accounts found", try running Option 1 again.
