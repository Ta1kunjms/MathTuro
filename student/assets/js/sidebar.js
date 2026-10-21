// Student Sidebar - Reusable Component
// Usage: Add <div id="sidebar"></div> in your HTML, then include this script at the end of <body>

function initSidebar() {
  const isPublicDir = window.location.pathname.toLowerCase().includes('/public/');
  const studentPrefix = isPublicDir ? '../student/' : '';
  const publicPrefix = isPublicDir ? '' : '../public/';
  const logoPrefix = '../Logo/MATHURO-LOGO-v2.png';

  const sidebarHTML = `
  <div class="sidebar-scrollable flex-1 overflow-y-auto pb-36">
            <!-- Logo -->
            <div class="p-6 border-b border-gray-100">
                <a href="${studentPrefix}dashboard.html" class="flex items-center space-x-3">
                    <div class="w-12 h-12 bg-white rounded-xl flex items-center justify-center shadow-lg">
                        <img src="${logoPrefix}" alt="MathTuro" class="w-10 h-10 object-contain">
                    </div>
                    <div>
                        <span class="text-xl font-bold gradient-text">MathTuro</span>
                        <p class="text-xs text-gray-500">Student Portal</p>
                    </div>
                </a>
            </div>
            
            <!-- User Info -->
            <div class="p-6 border-b border-gray-100 cursor-pointer hover:bg-gray-50 transition-colors" onclick="if(typeof showProfile==='function'){showProfile();}" title="Click to view profile">
                <div class="flex items-center space-x-3">
                    <div class="w-12 h-12 bg-forest-800/10 rounded-full flex items-center justify-center">
                        <span id="userInitials" class="text-forest-800 font-bold text-lg">--</span>
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
            <!-- Six distinct destinations: Dashboard, Modules, Quizzes,
                 Videos, Presentations, Progress. Each link carries its own
                 data-nav-key used by the active-link matching below —
                 do not rely on href/filename parsing alone, since Progress
                 shares dashboard.html's URL but is distinguished by hash. -->
            <nav class="p-4 space-y-2 overflow-y-auto" style="max-height: calc(100vh - 320px);">
                <p class="text-xs text-gray-400 uppercase tracking-wider px-4 mb-2">Main Menu</p>
                <a href="${studentPrefix}dashboard.html" data-nav-key="dashboard" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
                    </svg>
                    <span>Dashboard</span>
                </a>
                <a href="${studentPrefix}modules.html" data-nav-key="modules" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/>
                    </svg>
                    <span>Modules</span>
                </a>
                <a href="${studentPrefix}quizzes.html" data-nav-key="quizzes" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/>
                    </svg>
                    <span>Quizzes</span>
                </a>
                <a href="${studentPrefix}tutorial-videos.html" data-nav-key="videos" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <span>Videos</span>
                </a>
                <a href="${studentPrefix}presentations.html" data-nav-key="presentations" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                    </svg>
                    <span>Presentations</span>
                </a>
                <a href="${studentPrefix}dashboard.html#progress" data-nav-key="progress" class="sidebar-link flex items-center space-x-3 px-4 py-3 rounded-xl text-gray-700">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 012-2h2a2 2 0 012 2v6m-9 0h10a2 2 0 002-2V9.5a1 1 0 00-.4-.8l-5-3.75a1 1 0 00-1.2 0l-5 3.75a1 1 0 00-.4.8V17a2 2 0 002 2z"/>
                    </svg>
                    <span>Progress</span>
                </a>
            </nav>
        </div>
        
        <!-- Bottom Actions -->
        <div class="absolute bottom-0 left-0 right-0 p-4 border-t border-gray-100 bg-white">
            <div data-font-toggle-mount data-variant="light" class="mb-1"></div>
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
    // Dyslexia-friendly font switch (shared/js/font-toggle.js), mounted above Logout
    if (window.MathTuroFont) window.MathTuroFont.mountAll();
  }

  // Set active link based on current page, matched by the data-nav-key each
  // link declares rather than by parsing hrefs. Each real destination file
  // maps to exactly one nav key; drill-down pages (module-view/lesson-view,
  // take-quiz, view-presentation) map to their parent section's key so that
  // section stays highlighted while browsing within it. Progress shares
  // dashboard.html's URL but is distinguished by the #progress hash, so it's
  // checked separately and wins over the plain dashboard match when present.
  const currentPage = window.location.pathname.split('/').pop().toLowerCase();
  const currentHash = window.location.hash.toLowerCase();
  const pageNavKeyMap = {
    'dashboard.html': 'dashboard',
    '': 'dashboard',
    'modules.html': 'modules',
    'module-view.html': 'modules',
    'lesson-view.html': 'modules',
    'quizzes.html': 'quizzes',
    'take-quiz.html': 'quizzes',
    'tutorial-videos.html': 'videos',
    'presentations.html': 'presentations',
    'view-presentation.html': 'presentations'
  };
  const activeNavKey = currentHash === '#progress' ? 'progress' : (pageNavKeyMap[currentPage] || null);
  const sidebarLinks = document.querySelectorAll('.sidebar-link');
  sidebarLinks.forEach(link => {
    const isActive = !!activeNavKey && link.dataset.navKey === activeNavKey;

    if (isActive) {
      // Styling comes from student.css (#sidebar .sidebar-link.active)
      link.classList.add('active');
      link.setAttribute('aria-current', 'page');
    } else {
      // Remove active class from other links
      link.classList.remove('active');
      link.removeAttribute('aria-current');
    }
  });

  // Handle mobile drawer toggles
  const mobileMenuBtn = document.getElementById('mobileMenuBtn');
  const mobileOverlay = document.getElementById('mobileOverlay');
  if (mobileMenuBtn && sidebarContainer) {
    mobileMenuBtn.addEventListener('click', () => {
      sidebarContainer.classList.toggle('-translate-x-full');
      if (mobileOverlay) mobileOverlay.classList.toggle('hidden');
    });
  }
  if (mobileOverlay && sidebarContainer) {
    mobileOverlay.addEventListener('click', () => {
      sidebarContainer.classList.add('-translate-x-full');
      mobileOverlay.classList.add('hidden');
    });
  }

  // Load sidebar user info
  loadSidebarUserInfo();

  // Load streak count
  loadStreakCount();

  // Setup logout handler
  const logoutButton = document.getElementById('logoutButton');
  if (logoutButton) {
    logoutButton.addEventListener('click', handleLogout);
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initSidebar);
} else {
  initSidebar();
}

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
    const supabase = getSupabase();
    if (!supabase) return;

    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.user?.id) return;

    let streakCount = 0;

    const { data: streakData, error: streakError } = await supabase
      .from('student_streaks')
      .select('current_streak')
      .eq('student_id', session.user.id)
      .maybeSingle();

    if (streakError && !(String(streakError.code || '') === 'PGRST116')) {
      const message = `${streakError.message || ''} ${streakError.details || ''}`.toLowerCase();
      if (!message.includes('student_streaks')) {
        throw streakError;
      }
    }

    if (streakData?.current_streak !== undefined && streakData?.current_streak !== null) {
      streakCount = Number(streakData.current_streak || 0);
    } else {
      const activeDays = new Set();

      const { data: progressRows } = await supabase
        .from('lesson_progress')
        .select('completed_at, updated_at, created_at')
        .eq('user_id', session.user.id)
        .order('updated_at', { ascending: false })
        .limit(200);

      (progressRows || []).forEach(row => {
        const timestamp = row.completed_at || row.updated_at || row.created_at;
        if (!timestamp) return;
        const date = new Date(timestamp);
        date.setHours(0, 0, 0, 0);
        activeDays.add(date.toISOString().slice(0, 10));
      });

      const { data: moduleProgressRows } = await supabase
        .from('student_module_progress')
        .select('last_opened_at, first_opened_at, updated_at')
        .eq('student_id', session.user.id)
        .order('last_opened_at', { ascending: false })
        .limit(200);

      (moduleProgressRows || []).forEach(row => {
        const timestamp = row.last_opened_at || row.first_opened_at || row.updated_at;
        if (!timestamp) return;
        const date = new Date(timestamp);
        date.setHours(0, 0, 0, 0);
        activeDays.add(date.toISOString().slice(0, 10));
      });

      const cursor = new Date();
      cursor.setHours(0, 0, 0, 0);

      const todayKey = cursor.toISOString().slice(0, 10);
      if (!activeDays.has(todayKey)) {
        cursor.setDate(cursor.getDate() - 1);
      }

      while (activeDays.has(cursor.toISOString().slice(0, 10))) {
        streakCount += 1;
        cursor.setDate(cursor.getDate() - 1);
      }
    }

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

// Global Modal & Profile Management for all Student pages
function ensureModalContainer() {
  let container = document.getElementById('modalContainer');
  if (!container) {
    container = document.createElement('div');
    container.id = 'modalContainer';
    container.className = 'hidden fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4 transition-opacity duration-300';
    container.innerHTML = `
      <div id="modalContent" class="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto shadow-2xl transform transition-all scale-100">
        <!-- Modal content loaded dynamically -->
      </div>
    `;
    container.addEventListener('click', (e) => {
      if (e.target === container) window.closeModal();
    });
    document.body.appendChild(container);
  }
  return container;
}

window.showModal = function (title, content) {
  ensureModalContainer();
  const modal = document.getElementById('modalContainer');
  const modalContent = document.getElementById('modalContent');
  if (modalContent) {
    modalContent.innerHTML = `
      <div class="p-6 border-b border-gray-100 flex items-center justify-between">
        <h3 class="text-xl font-bold text-gray-800">${title}</h3>
        <button onclick="closeModal()" class="p-2 text-gray-500 hover:text-gray-700 rounded-lg hover:bg-gray-100 transition-colors">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>
      <div class="p-6">${content}</div>
    `;
  }
  if (modal) modal.classList.remove('hidden');
};

window.closeModal = function () {
  const modal = document.getElementById('modalContainer');
  if (modal) modal.classList.add('hidden');
};

window.showProfile = async function () {
  let name = '';
  let email = '';

  const sidebarUserNameEl = document.getElementById('sidebarUserName');
  if (sidebarUserNameEl && sidebarUserNameEl.textContent !== 'Loading...') {
    name = sidebarUserNameEl.textContent;
  }

  if (typeof getSupabase === 'function') {
    try {
      const supabase = getSupabase();
      if (supabase) {
        const { data: { session } } = await supabase.auth.getSession();
        if (session && session.user) {
          email = session.user.email || '';
          if (!name || name === 'Loading...') {
            name = session.user.user_metadata?.full_name || session.user.user_metadata?.name || email.split('@')[0] || 'Student';
          }
        }
      }
    } catch (e) {
      console.warn('Error fetching user for profile modal:', e);
    }
  }

  window.showModal('Profile Settings', `
    <form id="profileForm" class="space-y-4" onsubmit="handleGlobalProfileSave(event)">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Full Name</label>
        <input type="text" id="profileName" value="${name || 'Student'}" class="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-forest-800">
      </div>
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Email</label>
        <input type="email" id="profileEmail" value="${email || ''}" disabled class="w-full px-4 py-3 border border-gray-200 rounded-xl bg-gray-50 text-gray-500">
      </div>
      <button type="submit" class="w-full py-3 bg-forest-800 text-white rounded-xl font-semibold hover:bg-forest-900 transition-all transform active:scale-95">Save Changes</button>
    </form>
  `);
};

window.handleGlobalProfileSave = async function (event) {
  event.preventDefault();
  const nameInput = document.getElementById('profileName');
  const newName = nameInput ? nameInput.value.trim() : '';
  if (!newName) return;

  try {
    if (typeof getSupabase === 'function') {
      const supabase = getSupabase();
      if (supabase) {
        const { data: { session } } = await supabase.auth.getSession();
        if (session?.user?.id) {
          await supabase.from('users').update({ full_name: newName, updated_at: new Date().toISOString() }).eq('id', session.user.id);
          await supabase.auth.updateUser({ data: { full_name: newName } });
        }
      }
    }
    const sidebarUserNameEl = document.getElementById('sidebarUserName');
    if (sidebarUserNameEl) sidebarUserNameEl.textContent = newName;

    if (typeof showToast === 'function') {
      showToast('Profile updated successfully!', 'success');
    } else {
      alert('Profile updated successfully!');
    }
    window.closeModal();
  } catch (err) {
    console.error('Error saving profile:', err);
    if (typeof showToast === 'function') {
      showToast('Failed to update profile.', 'error');
    } else {
      alert('Failed to update profile.');
    }
  }
};