/*
  File: auth.js
  Purpose:
  - Handles all authentication-related functionality
  - Manages login, logout, and session checks
  - Validates user roles from the database

  Dependencies:
  - supabase.js - for Supabase client connection
*/

/*
  Function Name: login
  Purpose:
  - Handles user login using email and password
  - Authenticates with Supabase Auth
  - Fetches user role from the database
  - Stores user data in localStorage for quick access

  When it runs:
  - Called when user clicks the login button on login.html

  Who can use it:
  - All users (Student / Teacher / Admin)

  Backend interaction:
  1. Calls Supabase Auth's signInWithPassword method
  2. Queries the users table to get the user's role and profile information
  3. Returns user data and role

  Error handling:
  - Shows alert if login credentials are invalid
  - Shows alert if user's role is not found in database
  - Shows alert for any other Supabase error
*/
async function login(email, password) {
  try {
    // Step 1: Sign in with Supabase Auth using email and password
    const { data: authData, error: authError } = await getSupabase().auth.signInWithPassword({
      email: email,
      password: password
    });

    // Check if login failed (invalid credentials)
    if (authError) {
      if (typeof showToast === 'function') {
        showToast('Login failed: ' + authError.message, 'error');
      }
      return null;
    }

    // Step 2: Get user role from the database
    let { data: userData, error: userError } = await getSupabase()
      .from('users')
      .select('id, email, role, full_name')
      .eq('id', authData.user.id)
      .single();

    // If user doesn't exist in users table, create them
    if (userError || !userData) {
      console.log('User not found in users table, creating record...');
      
      // Get user metadata from auth
      const userMeta = authData.user.user_metadata || {};
      const role = userMeta.role || 'student';
      const fullName = userMeta.full_name || authData.user.email.split('@')[0];

      // Insert the user record
      const { data: newUser, error: insertError } = await getSupabase()
        .from('users')
        .insert({
          id: authData.user.id,
          email: authData.user.email,
          full_name: fullName,
          role: role,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .select()
        .single();

      if (insertError) {
        console.error('Failed to create user record:', insertError);
        if (typeof showToast === 'function') {
          showToast('Error: Could not create user profile. Please contact support.', 'error');
        }
        await getSupabase().auth.signOut();
        return null;
      }

      userData = newUser;
    }

    // Step 3: Store user information in localStorage
    const user = {
      id: authData.user.id,
      email: authData.user.email,
      role: userData.role,
      fullName: userData.full_name
    };
    localStorage.setItem('user', JSON.stringify(user));

    return user;

  } catch (error) {
    if (typeof showToast === 'function') {
      showToast('Login failed: ' + error.message, 'error');
    }
    return null;
  }
}

/*
  Function Name: logout
  Purpose:
  - Handles user logout
  - Clears user session from Supabase Auth
  - Removes user data from localStorage

  When it runs:
  - Called when user clicks the logout button on any dashboard

  Who can use it:
  - All users (Student / Teacher / Admin)

  Backend interaction:
  - Calls Supabase Auth's signOut method

  Error handling:
  - Shows alert if logout fails
*/
async function logout() {
  try {
    // Sign out from Supabase Auth
    const { error } = await getSupabase().auth.signOut();
    
    if (error) {
      if (typeof showToast === 'function') {
        showToast('Logout failed: ' + error.message, 'error');
      }
      return false;
    }

    // Clear user data from localStorage
    localStorage.removeItem('user');
    
    return true;
  } catch (error) {
    if (typeof showToast === 'function') {
      showToast('Logout failed: ' + error.message, 'error');
    }
    return false;
  }
}

/*
  Function Name: checkAuthSession
  Purpose:
  - Verifies if the user is currently authenticated
  - Checks if the current session is still valid
  - Returns user data if session is valid

  When it runs:
  - Called when dashboard pages load to verify user session

  Who can use it:
  - All users (Student / Teacher / Admin)

  Backend interaction:
  - Uses Supabase Auth's getSession method to validate session

  Error handling:
  - Returns null if no valid session is found
  - Returns null if user data is not in localStorage
*/
async function checkAuthSession() {
  try {
    // Get current session from Supabase
    const { data: { session }, error } = await getSupabase().auth.getSession();

    // If session is invalid, clear user data
    if (error || !session) {
      localStorage.removeItem('user');
      return null;
    }

    // Get user data from localStorage
    const user = JSON.parse(localStorage.getItem('user'));
    
    // If no user data in localStorage, try to fetch from database
    if (!user) {
      const { data: userData, error: userError } = await getSupabase()
        .from('users')
        .select('id, email, role, full_name')
        .eq('id', session.user.id)
        .single();

      if (userError || !userData) {
        return null;
      }

      const newUser = {
        id: session.user.id,
        email: session.user.email,
        role: userData.role,
        fullName: userData.full_name
      };
      
      localStorage.setItem('user', JSON.stringify(newUser));
      return newUser;
    }

    return user;

  } catch (error) {
    console.error('Session check error:', error);
    localStorage.removeItem('user');
    return null;
  }
}

/*
  Function Name: getUserRole
  Purpose:
  - Returns the role of the currently logged-in user from localStorage

  When it runs:
  - Called by role-based access check functions
  - Used to determine which features are available to the user

  Who can use it:
  - All users (Student / Teacher / Admin)

  Backend interaction:
  - Reads from localStorage only - no direct Supabase call

  Error handling:
  - Returns null if no user data is available
*/
function getUserRole() {
  const user = JSON.parse(localStorage.getItem('user'));
  return user ? user.role : null;
}

/*
  Function Name: isAuthenticated
  Purpose:
  - Checks if the user is currently logged in

  When it runs:
  - Called by pages to check if user should see login page or dashboard

  Who can use it:
  - All users (Student / Teacher / Admin)

  Backend interaction:
  - Reads from localStorage only - no direct Supabase call
*/
function isAuthenticated() {
  return localStorage.getItem('user') !== null;
}

/*
  Function Name: getBasePath
  Purpose:
  - Determines the correct base path based on current location
*/
function getBasePath() {
  const path = window.location.pathname;
  if (path.includes('/student/') || path.includes('/teacher/') || path.includes('/admin/') || path.includes('/public/')) {
    return '../';
  }
  return '';
}

/*
  Function Name: redirectToLogin
  Purpose:
  - Redirects unauthenticated users to the login page

  When it runs:
  - Called by dashboard pages if checkAuthSession fails

  Who can use it:
  - Not applicable (redirects unauthenticated users)

  Backend interaction:
  - N/A - just a redirect
*/
function redirectToLogin() {
  const basePath = getBasePath();
  window.location.href = basePath + 'public/login.html';
}

/*
  Function Name: redirectToDashboard
  Purpose:
  - Redirects authenticated users to their appropriate dashboard based on role

  When it runs:
  - Called after successful login
  - Called by index.html if user is already authenticated

  Who can use it:
  - All users (Student / Teacher / Admin)

  Backend interaction:
  - Reads from localStorage to get user role
*/
function redirectToDashboard() {
  const user = JSON.parse(localStorage.getItem('user'));
  const basePath = getBasePath();
  
  if (user) {
    switch (user.role) {
      case 'student':
        window.location.href = basePath + 'student/dashboard.html';
        break;
      case 'teacher':
        window.location.href = basePath + 'teacher/dashboard.html';
        break;
      case 'admin':
        window.location.href = basePath + 'admin/dashboard.html';
        break;
      default:
        // If role is unknown, sign out and redirect to login
        logout();
        redirectToLogin();
    }
  } else {
    redirectToLogin();
  }
}
