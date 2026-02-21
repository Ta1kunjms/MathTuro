// Student Sidebar - Reusable Component
// Usage: Add <div id="sidebar"></div> in your HTML, then include this script at the end of <body>

document.addEventListener('DOMContentLoaded', function () {
  const sidebarHTML = `
    <aside id="sidebar" class="fixed left-0 top-0 h-full w-72 glass-sidebar border-r border-gray-200 z-50 transform -translate-x-full lg:translate-x-0 transition-transform duration-300 flex flex-col">
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
                <p class="text-xs text-gray-400 uppercase tracking-wider px-4 mb-2 mt-6">My Learning</p>
                <a href="#" onclick="showMyProgress(); return false;" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
                    </svg>
                    <span>My Progress</span>
                </a>
                <a href="#" onclick="showAchievements(); return false;" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"/>
                    </svg>
                    <span>Achievements</span>
                    <span id="achievementCount" class="ml-auto px-2 py-0.5 bg-yellow-100 text-yellow-700 text-xs rounded-full">0</span>
                </a>
                <a href="#" onclick="showLeaderboard(); return false;" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"/>
                    </svg>
                    <span>Leaderboard</span>
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
  const currentPage = window.location.pathname.split('/').pop();
  const sidebarLinks = document.querySelectorAll('.sidebar-link');
  sidebarLinks.forEach(link => {
    const linkPage = link.getAttribute('href');
    // Check if link is active based on current page
    if (currentPage === linkPage || (currentPage === '' && linkPage === 'dashboard.html')) {
      link.classList.add('active');
      link.style.background = 'linear-gradient(135deg, #005801 0%, #006B01 100%)';
      link.style.color = 'white';
    } else {
      // Remove active class from other links
      link.classList.remove('active');
      link.style.background = '';
      link.style.color = 'text-gray-700';
    }
  });

  // Load sidebar user info
  loadSidebarUserInfo();

  // Load streak count
  loadStreakCount();

  // Load achievement count
  loadAchievementCount();

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

// Load and display the student's achievement count
async function loadAchievementCount() {
  try {
    // This function would typically fetch the achievement count from the database
    // For now, we'll use a placeholder value
    const achievementCount = 0;
    const achievementCountEl = document.getElementById('achievementCount');
    if (achievementCountEl) {
      achievementCountEl.textContent = achievementCount;
    }
  } catch (error) {
    console.error('Error loading achievement count:', error);
  }
}

// Handle logout
async function handleLogout() {
  try {
    const supabase = getSupabase();
    if (supabase) await supabase.auth.signOut();
    window.location.href = '../login.html';
  } catch (error) {
    console.error('Logout error:', error);
    window.location.href = '../login.html';
  }
}