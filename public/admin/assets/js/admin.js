/*
  File: admin.js
  Purpose:
  - Contains all admin-specific functionality
  - Manages users (students, teachers, admins)
  - Handles system-wide settings and configuration
  - Provides access to all data and reports

  Dependencies:
  - supabase.js - for Supabase client connection
  - auth.js - for authentication checks
  - modules.js - for module and lesson data handling
  - teacher.js - for teacher-specific functionality
*/

/*
  Function Name: getUsers
  Purpose:
  - Retrieves all users from the system
  - Optional filter by role
  - Returns users with role information

  When it runs:
  - Called when admin views the users management page
  - Called when admin generates user reports

  Who can use it:
  - Admin

  Backend interaction:
  - Reads from users table
  - Optional filter by role column
  - Orders by created_at descending

  Error handling:
  - Returns empty array if no users found
  - Logs errors to console
*/
async function getUsers(role = null) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      if (typeof showToast === 'function') showToast('You do not have permission to access user data', 'error');
      return [];
    }

    let query = getSupabase()
      .from('users')
      .select('*')
      .order('created_at', { ascending: false });

    if (role) {
      query = query.eq('role', role);
    }

    const { data, error } = await query;

    if (error) {
      console.error('Error loading users:', error);
      return [];
    }

    return data;

  } catch (error) {
    console.error('Error getting users:', error);
    return [];
  }
}

/*
  Function Name: createUser
  Purpose:
  - Creates a new user in the system
  - Handles both user record creation and Supabase Auth sign-up
  - Sets user role and basic profile information

  When it runs:
  - Called when admin creates a new user
  - Called from the users management page

  Who can use it:
  - Admin

  Backend interaction:
  - Signs up user with Supabase Auth (email/password)
  - Creates user record in users table
  - Sets initial role and profile information

  Error handling:
  - Validates user data
  - Handles Supabase Auth errors
  - Handles database insertion errors
  - Shows alert for errors
*/
async function createUser(email, password, fullName, role = 'student') {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      if (typeof showToast === 'function') showToast('You do not have permission to create users', 'error');
      return null;
    }

    // Validate input
    if (!email || !password || !fullName) {
      if (typeof showToast === 'function') showToast('Email, password, and full name are required', 'error');
      return null;
    }

    if (password.length < 6) {
      if (typeof showToast === 'function') showToast('Password must be at least 6 characters', 'error');
      return null;
    }

    // Validate role
    const allowedRoles = ['student', 'teacher', 'admin'];
    if (!allowedRoles.includes(role)) {
      if (typeof showToast === 'function') showToast('Invalid user role', 'error');
      return null;
    }

    // Create user in Supabase Auth
    const { data: authData, error: authError } = await getSupabase().auth.signUp({
      email: email,
      password: password,
      options: {
        data: {
          full_name: fullName,
          role: role
        }
      }
    });

    if (authError) {
      console.error('Auth error:', authError);
      if (typeof showToast === 'function') showToast('Failed to create user: ' + authError.message, 'error');
      return null;
    }

    // Create user record in users table
    const { data: userData, error: userError } = await getSupabase()
      .from('users')
      .insert({
        id: authData.user.id,
        email: email,
        full_name: fullName,
        role: role,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select('*')
      .single();

    if (userError) {
      console.error('Database error:', userError);
      // Try to delete the Auth user if database creation failed
      await getSupabase().auth.admin.deleteUser(authData.user.id);
      if (typeof showToast === 'function') showToast('Failed to create user record: ' + userError.message, 'error');
      return null;
    }

    return userData;

  } catch (error) {
    console.error('Error creating user:', error);
    if (typeof showToast === 'function') showToast('Failed to create user. Please try again.', 'error');
    return null;
  }
}

/*
  Function Name: updateUser
  Purpose:
  - Updates an existing user's information
  - Handles user profile and role updates
  - Does NOT handle password changes

  When it runs:
  - Called when admin edits a user
  - Called from the users management page

  Who can use it:
  - Admin

  Backend interaction:
  - Updates users table with new information
  - Sets updated_at timestamp

  Error handling:
  - Validates user data
  - Handles database update errors
  - Shows alert for errors
*/
async function updateUser(userId, userData) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      if (typeof showToast === 'function') showToast('You do not have permission to update users', 'error');
      return false;
    }

    // Validate input
    if (userData.role) {
      const allowedRoles = ['student', 'teacher', 'admin'];
      if (!allowedRoles.includes(userData.role)) {
        if (typeof showToast === 'function') showToast('Invalid user role', 'error');
        return false;
      }
    }

    // Update user record
    const { error } = await getSupabase()
      .from('users')
      .update({
        full_name: userData.fullName,
        role: userData.role,
        updated_at: new Date().toISOString()
      })
      .eq('id', userId);

    if (error) {
      console.error('Error updating user:', error);
      if (typeof showToast === 'function') showToast('Failed to update user: ' + error.message, 'error');
      return false;
    }

    // Update user data in localStorage if updating current user
    if (user.id === userId) {
      user.fullName = userData.fullName;
      user.role = userData.role;
      localStorage.setItem('user', JSON.stringify(user));
    }

    return true;

  } catch (error) {
    console.error('Error updating user:', error);
    if (typeof showToast === 'function') showToast('Failed to update user. Please try again.', 'error');
    return false;
  }
}

/*
  Function Name: deleteUser
  Purpose:
  - Deletes a user from the system
  - Handles both database record and Supabase Auth user deletion

  When it runs:
  - Called when admin deletes a user
  - Called from the users management page

  Who can use it:
  - Admin

  Backend interaction:
  - Deletes user record from users table
  - Deletes user from Supabase Auth

  Error handling:
  - Validates user role
  - Handles database deletion errors
  - Handles Supabase Auth deletion errors
  - Shows alert for errors
*/
async function deleteUser(userId) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      if (typeof showToast === 'function') showToast('You do not have permission to delete users', 'error');
      return false;
    }

    // Cannot delete current user
    if (user.id === userId) {
      if (typeof showToast === 'function') showToast('You cannot delete your own account', 'error');
      return false;
    }

    // Delete user record from database
    const { error: dbError } = await getSupabase()
      .from('users')
      .delete()
      .eq('id', userId);

    if (dbError) {
      console.error('Database error:', dbError);
      if (typeof showToast === 'function') showToast('Failed to delete user: ' + dbError.message, 'error');
      return false;
    }

    // Delete user from Supabase Auth
    const { error: authError } = await getSupabase().auth.admin.deleteUser(userId);

    if (authError) {
      console.error('Auth error:', authError);
      if (typeof showToast === 'function') showToast('Failed to delete user from authentication system: ' + authError.message, 'error');
      return false;
    }

    return true;

  } catch (error) {
    console.error('Error deleting user:', error);
    if (typeof showToast === 'function') showToast('Failed to delete user. Please try again.', 'error');
    return false;
  }
}

/*
  Function Name: resetUserPassword
  Purpose:
  - Sends a password reset email to a user
  - User will receive an email with password reset instructions

  When it runs:
  - Called when admin initiates a password reset for a user
  - Called from the users management page

  Who can use it:
  - Admin

  Backend interaction:
  - Calls Supabase Auth's resetPasswordForEmail method
  - Sends email to user's registered email address

  Error handling:
  - Validates user email
  - Handles password reset request errors
  - Shows alert for errors
*/
async function resetUserPassword(email) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      if (typeof showToast === 'function') showToast('You do not have permission to reset passwords', 'error');
      return false;
    }

    const { error } = await getSupabase().auth.resetPasswordForEmail(email, {
      redirectTo: window.location.origin + '/reset-password.html'
    });

    if (error) {
      console.error('Error resetting password:', error);
      if (typeof showToast === 'function') showToast('Failed to send password reset email: ' + error.message, 'error');
      return false;
    }

    return true;

  } catch (error) {
    console.error('Error resetting password:', error);
    if (typeof showToast === 'function') showToast('Failed to send password reset email. Please try again.', 'error');
    return false;
  }
}

/*
  Function Name: getSystemStats
  Purpose:
  - Retrieves system-wide statistics for admin dashboard
  - Returns counts of users, modules, lessons, and submissions

  When it runs:
  - Called when admin views the dashboard
  - Provides overview of system usage

  Who can use it:
  - Admin

  Backend interaction:
  - Reads from users, modules, lessons, and quiz_submissions tables
  - Counts records and groups by relevant criteria

  Error handling:
  - Returns default stats if queries fail
  - Logs errors to console
*/
async function getSystemStats() {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      return null;
    }

    // Get all users and count by role client-side
    const { data: allUsers, error: userError } = await getSupabase()
      .from('users')
      .select('role');

    // Get module count
    const { data: modules, error: moduleError } = await getSupabase()
      .from('modules')
      .select('id')
      .eq('is_active', true);

    // Get lesson count
    const { data: lessons, error: lessonError } = await getSupabase()
      .from('lessons')
      .select('id');

    // Get all submissions and count by status client-side
    const { data: allSubmissions, error: submissionError } = await getSupabase()
      .from('quiz_submissions')
      .select('status');

    // Calculate user totals
    const users = {
      total: 0,
      students: 0,
      teachers: 0,
      admins: 0
    };

    if (allUsers) {
      allUsers.forEach(u => {
        if (u.role === 'student') users.students++;
        else if (u.role === 'teacher') users.teachers++;
        else if (u.role === 'admin') users.admins++;
      });
      users.total = users.students + users.teachers + users.admins;
    }

    const modulesCount = modules ? modules.length : 0;
    const lessonsCount = lessons ? lessons.length : 0;

    const submissions = {
      total: 0,
      pending: 0,
      approved: 0,
      rejected: 0
    };

    if (allSubmissions) {
      allSubmissions.forEach(s => {
        if (s.status === 'pending') submissions.pending++;
        else if (s.status === 'approved') submissions.approved++;
        else if (s.status === 'rejected') submissions.rejected++;
      });
      submissions.total = submissions.pending + submissions.approved + submissions.rejected;
    }

    return {
      users,
      modules: modulesCount,
      lessons: lessonsCount,
      submissions
    };

  } catch (error) {
    console.error('Error getting system stats:', error);
    return null;
  }
}

/*
  Function Name: getActivityLog
  Purpose:
  - Retrieves system activity log entries
  - Returns recent actions by users

  When it runs:
  - Called when admin views system activity page
  - Provides audit trail of user actions

  Who can use it:
  - Admin

  Backend interaction:
  - Reads from activity_log table
  - Orders by created_at descending
  - Optional limit on number of records

  Error handling:
  - Returns empty array if no activity found
  - Logs errors to console
*/
async function getActivityLog(limit = 50) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      return [];
    }

    const { data, error } = await getSupabase()
      .from('activity_log')
      .select('*, users(full_name, role)')
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) {
      console.error('Error loading activity log:', error);
      return [];
    }

    return data;

  } catch (error) {
    console.error('Error getting activity log:', error);
    return [];
  }
}

/*
  Function Name: logActivity
  Purpose:
  - Logs an activity in the system activity log
  - Records user actions for auditing purposes

  When it runs:
  - Called from various functions to record important actions
  - Runs automatically when specific events occur

  Who can use it:
  - All users (automatically triggered)

  Backend interaction:
  - Inserts into activity_log table
  - Records user_id, action, details, and timestamp

  Error handling:
  - Handles database insertion errors
  - Logs errors to console but doesn't fail operation
*/
async function logActivity(action, details = null) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user) {
      return;
    }

    const { error } = await getSupabase()
      .from('activity_log')
      .insert({
        user_id: user.id,
        action: action,
        details: details,
        created_at: new Date().toISOString()
      });

    if (error) {
      console.error('Error logging activity:', error);
    }

  } catch (error) {
    console.error('Error logging activity:', error);
  }
}
