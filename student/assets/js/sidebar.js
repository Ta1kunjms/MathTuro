// Student Sidebar - Reusable Component
// Usage: Add <div id="sidebar"></div> in your HTML, then include this script at the end of <body>

document.addEventListener('DOMContentLoaded', function () {
  const sidebarHTML = `
  <div class="sidebar-scrollable flex-1 overflow-y-auto">
            <!-- Logo -->
            <div class="p-6 border-b border-gray-100">
                <a href="dashboard.html" class="flex items-center space-x-3">
                    <div class="w-12 h-12 bg-white rounded-xl flex items-center justify-center shadow-lg">
                        <img src="../Logo/MATHURO-LOGO.png" alt="MathTuro" class="w-10 h-10 object-contain">
                    </div>
                    <div>
                        <span class="text-xl font-bold gradient-text">MathTuro</span>
                        <p class="text-xs text-gray-500">Student Portal</p>
                    </div>
                </a>
            </div>
            
            <!-- User Info -->
            <div class="p-6 border-b border-gray-100">
                <div class="flex items-center space-x-3">
                    <div class="w-12 h-12 bg-brand/10 rounded-full flex items-center justify-center">
                        <span id="userInitials" class="text-brand font-bold text-lg">--</span>
                    </div>
                    <div class="flex-1">
                        <p id="sidebarUserName" class="font-semibold text-gray-800">Loading...</p>
                        <div class="flex items-center space-x-1">
                            <span id="streakBadge" class="text-sm">🔥</span>
                            <span id="streakCount" class="text-sm text-orange-500 font-medium">0 day streak</span>
                        </div>
                        <div id="gradeSectionInfo" class="text-xs text-gray-500 mt-1">
                            <!-- Grade and section info will be loaded here -->
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Navigation -->
            <nav class="p-4 space-y-2 overflow-y-auto" style="max-height: calc(100vh - 320px);">
                <p class="text-xs text-gray-400 uppercase tracking-wider px-4 mb-2">Main Menu</p>
                <a href="dashboard.html" class="sidebar-link active flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
                    </svg>
                    <span>Dashboard</span>
                </a>
                <a href="modules.html" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
                    </svg>
                    <span>Browse Modules</span>
                </a>
                <a href="../public/tutorial-videos.html" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <span>Tutorial Videos</span>
                </a>
                <a href="quizzes.html" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/>
                    </svg>
                    <span>Quizzes</span>
                </a>
            </nav>
        </div>
        
        <!-- Bottom Actions -->
        <div class="absolute bottom-0 left-0 right-0 p-4 border-t border-gray-100 bg-white">
            <button id="logoutButton" class="w-full flex items-center space-x-3 px-4 py-3 text-red-600 hover:bg-red-50 rounded-xl transition-colors">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                </svg>
                <span>Logout</span>
            </button>
        </div>
    </div>
  `;

  const sidebarContainer = document.getElementById('sidebar');
  if (sidebarContainer) {
    sidebarContainer.innerHTML = sidebarHTML;
  }

  // Set active link based on current page
  const currentPage = window.location.pathname.split('/').pop().toLowerCase();
  const sidebarLinks = document.querySelectorAll('.sidebar-link');
  sidebarLinks.forEach(link => {
    const href = (link.getAttribute('href') || '').toLowerCase();
    const linkPage = href.split('#')[0].split('?')[0];
    const isActive =
      currentPage === linkPage ||
      (currentPage === '' && linkPage === 'dashboard.html') ||
      ((currentPage === 'module-view.html' || currentPage === 'lesson-view.html') && linkPage === 'modules.html');

    if (isActive) {
      link.classList.add('active');
      link.style.background = 'linear-gradient(135deg, #005801 0%, #006B01 100%)';
      link.style.color = 'white';
    } else {
      // Remove active class from other links
      link.classList.remove('active');
      link.style.background = '';
      link.style.color = '';
    }
  });

  // Load sidebar user info
  loadSidebarUserInfo();

  // Load streak count
  loadStreakCount();

  // Setup logout handler
  const logoutButton = document.getElementById('logoutButton');
  if (logoutButton) {
    logoutButton.addEventListener('click', handleLogout);
  }
});

// Load and display the logged-in student's name and initials in the sidebar
async function loadSidebarUserInfo() {
  try {
    const supabase = getSupabase();
    if (!supabase) return;

    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return;

    const fallbackDisplayName =
      session.user.user_metadata?.full_name ||
      session.user.user_metadata?.name ||
      session.user.email ||
      'Student';
    const fallbackInitials = fallbackDisplayName
      .split(' ')
      .map(part => part[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);

    const userInitialsEl = document.getElementById('userInitials');
    const sidebarUserNameEl = document.getElementById('sidebarUserName');
    if (userInitialsEl) userInitialsEl.textContent = fallbackInitials;
    if (sidebarUserNameEl) sidebarUserNameEl.textContent = fallbackDisplayName;

    const { data: users, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('id', session.user.id)
      .limit(1);

    let user = Array.isArray(users) ? users[0] : null;

    if (userError) {
      console.warn('Could not load full sidebar user profile, using session fallback:', userError);
    }

    if (!user) {
      const metadata = session.user.user_metadata || {};
      const fallbackFullName = metadata.full_name || metadata.name || (session.user.email || '').split('@')[0] || 'Student';
      const fallbackRole = metadata.role || 'student';

      const { data: upsertedRows, error: upsertError } = await supabase
        .from('users')
        .upsert({
          id: session.user.id,
          email: session.user.email,
          full_name: fallbackFullName,
          role: fallbackRole,
          updated_at: new Date().toISOString()
        }, { onConflict: 'id' })
        .select('*')
        .limit(1);

      if (upsertError) {
        console.warn('Could not auto-create sidebar user profile, using session fallback:', upsertError);
      } else {
        user = Array.isArray(upsertedRows) ? upsertedRows[0] : null;
      }
    }

    if (user) {
      const displayName = (user.full_name && user.full_name.trim()) ? user.full_name : session.user.email;
      const initials = (user.full_name && user.full_name.trim())
        ? user.full_name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)
        : session.user.email.slice(0, 2).toUpperCase();

      if (userInitialsEl) userInitialsEl.textContent = initials;
      if (sidebarUserNameEl) sidebarUserNameEl.textContent = displayName;
    }

    // Load grade and section information
    await loadGradeSectionInfo(session.user.id, user, session.user);
  } catch (error) {
    console.error('Error loading sidebar user info:', error);
  }
}

async function loadGradeSectionInfo(studentId, userProfile = null, authUser = null) {
  try {
    let gradeSectionInfo = null;
    if (typeof getStudentGradeSection === 'function') {
      gradeSectionInfo = await getStudentGradeSection(studentId);
    }

    const gradeSectionEl = document.getElementById('gradeSectionInfo');

    if (!gradeSectionEl) return;

    const metadata = authUser?.user_metadata || {};

    const gradeLevel =
      gradeSectionInfo?.gradeLevel?.name ||
      userProfile?.grade_level_text ||
      userProfile?.grade_level ||
      metadata.grade_level_text ||
      metadata.grade_level ||
      null;

    const section =
      gradeSectionInfo?.section?.name ||
      userProfile?.section_text ||
      userProfile?.section ||
      metadata.section_text ||
      metadata.section ||
      null;

    if (gradeLevel || section) {
      gradeSectionEl.textContent = `${gradeLevel || 'N/A'} - ${section || 'N/A'}`;
    }
  } catch (error) {
    console.error('Error loading grade/section info:', error);
  }
}

// Load and display the student's streak count
async function loadStreakCount() {
  try {
    // This function would typically fetch the streak count from the database
    // For now, we'll use a placeholder value
    const streakCount = 0;
    const streakCountEl = document.getElementById('streakCount');
    if (streakCountEl) {
      streakCountEl.textContent = `${streakCount} day streak`;
    }
  } catch (error) {
    console.error('Error loading streak count:', error);
  }
}

// Handle logout
async function handleLogout() {
  try {
    if (typeof logout === 'function') {
      await logout();
    } else {
      const supabase = getSupabase();
      if (supabase) await supabase.auth.signOut();
    }

    if (typeof redirectToLogin === 'function') {
      redirectToLogin();
      return;
    }

    window.location.href = '../public/login.html';
  } catch (error) {
    console.error('Logout error:', error);
    if (typeof redirectToLogin === 'function') {
      redirectToLogin();
      return;
    }
    window.location.href = '../public/login.html';
  }
}