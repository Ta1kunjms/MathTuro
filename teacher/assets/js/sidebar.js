// Teacher Sidebar - Reusable Component
// Usage: Add <div id="sidebar"></div> in your HTML, then include this script at the end of <body>

document.addEventListener('DOMContentLoaded', function () {
  const sidebarHTML = `
    <aside id="teacherSidebar" class="fixed left-0 top-0 h-screen w-72 glass-sidebar border-r border-gray-200 z-50 transform -translate-x-full lg:translate-x-0 transition-transform duration-300 flex flex-col">
        <div class="sidebar-scrollable flex-1 overflow-y-auto">
            <!-- Logo -->
            <div class="p-6 border-b border-gray-100">
                <a href="dashboard.html" class="flex items-center space-x-3">
                    <div class="w-12 h-12 bg-white rounded-xl flex items-center justify-center shadow-lg">
                        <img src="../Logo/MATHURO-LOGO-v2.png" alt="MathTuro" class="w-10 h-10 object-contain">
                    </div>
                    <div>
                        <span class="text-xl font-bold gradient-text">MathTuro</span>
                        <p class="text-xs text-gray-500">Teacher Portal</p>
                    </div>
                </a>
            </div>
            
            <!-- User Info -->
            <div class="p-6 border-b border-gray-100">
                <a href="profile.html" class="flex items-center space-x-3 group hover:opacity-80 transition-opacity cursor-pointer">
                    <div class="w-12 h-12 bg-teacher-100 rounded-full flex items-center justify-center ring-2 ring-transparent group-hover:ring-teacher-300 transition-all">
                        <span id="userInitials" class="text-teacher-600 font-bold text-lg">--</span>
                    </div>
                    <div>
                        <p id="sidebarUserName" class="font-semibold text-gray-800">Loading...</p>
                        <p class="text-sm text-teacher-600 font-medium">Teacher</p>
                    </div>
                </a>
            </div>
            
            <!-- Navigation -->
            <nav class="p-4 space-y-2">
                <a href="dashboard.html" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
                    </svg>
                    <span>Dashboard</span>
                </a>
                <a href="submissions.html" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/>
                    </svg>
                    <span>Submissions</span>
                    <span id="pendingBadge" class="pulse-badge ml-auto bg-yellow-500 text-white text-xs px-2 py-0.5 rounded-full hidden">0</span>
                </a>
                <a href="manage-modules.html" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
                    </svg>
                    <span>Manage Modules</span>
                </a>
                <a href="manage-videos.html" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                    </svg>
                    <span>Manage Videos</span>
                </a>
                <a href="manage-quizzes.html" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/>
                    </svg>
                    <span>Manage Quizzes</span>
                </a>
                <a href="lessonplan.html" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 20h9"/>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16.5 3.5a2.121 2.121 0 113 3L7 19.5 3 21l1.5-4L16.5 3.5z"/>
                    </svg>
                    <span>Lesson Plan</span>
                </a>
                <a href="student-progress.html" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
                    </svg>
                    <span>Student Progress</span>
                </a>
                <a href="reports.html" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                    </svg>
                    <span>Reports</span>
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
    </aside>
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
      (currentPage === 'edit-module.html' && linkPage === 'manage-modules.html');

    if (isActive) {
      link.classList.add('active');
      link.style.background = 'linear-gradient(135deg, #005801 0%, #006B01 100%)';
      link.style.color = 'white';
    }
  });

  // Load sidebar user info
  loadSidebarUserInfo();

  // Load pending submissions count
  loadPendingSubmissionsCount();

  // Setup logout handler
  const logoutButton = document.getElementById('logoutButton');
  if (logoutButton) {
    logoutButton.addEventListener('click', handleLogout);
  }
});

// Load and display the logged-in teacher's name and initials in the sidebar
async function loadSidebarUserInfo() {
  try {
    const supabase = getSupabase();
    if (!supabase) return;

    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return;

    const { data: user } = await supabase
      .from('users')
      .select('full_name, email')
      .eq('id', session.user.id)
      .single();

    if (user) {
      const displayName = (user.full_name && user.full_name.trim()) ? user.full_name : session.user.email;
      const initials = (user.full_name && user.full_name.trim())
        ? user.full_name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)
        : session.user.email.slice(0, 2).toUpperCase();

      const userInitialsEl = document.getElementById('userInitials');
      const sidebarUserNameEl = document.getElementById('sidebarUserName');
      if (userInitialsEl) userInitialsEl.textContent = initials;
      if (sidebarUserNameEl) sidebarUserNameEl.textContent = displayName;
    }
  } catch (error) {
    console.error('Error loading sidebar user info:', error);
  }
}

// Load pending submissions count for the badge
async function loadPendingSubmissionsCount() {
  try {
    const supabase = getSupabase();
    if (!supabase) return;

    const { count, error } = await supabase
      .from('quiz_submissions')
      .select('id', { count: 'exact', head: true })
      .eq('status', 'pending');
    
    if (error) throw error;
    
    const pendingBadge = document.getElementById('pendingBadge');
    if (!pendingBadge) return;

    if (typeof count === 'number' && count > 0) {
      pendingBadge.textContent = String(count);
      pendingBadge.classList.remove('hidden');
    } else {
      pendingBadge.classList.add('hidden');
    }
  } catch (error) {
    console.error('Error loading pending submissions count:', error);
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
      localStorage.removeItem('user');
    }

    if (typeof redirectToLogin === 'function') {
      redirectToLogin();
      return;
    }

    window.location.href = '../public/login.html';
  } catch (error) {
    console.error('Logout error:', error);
    window.location.href = '../public/login.html';
  }
}
