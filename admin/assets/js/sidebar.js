// Admin Sidebar Component
const ADMIN_ICON_STYLESHEET_ID = 'admin-fontawesome-css';
const ADMIN_ICON_STYLESHEET_HREF = 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css';

function ensureAdminIconStylesheet() {
    const existingById = document.getElementById(ADMIN_ICON_STYLESHEET_ID);
    const existingByHref = Array.from(document.querySelectorAll('link[rel="stylesheet"]')).some(
        (link) => (link.getAttribute('href') || '').includes('font-awesome')
    );

    if (existingById || existingByHref) {
        return;
    }

    const iconStylesheet = document.createElement('link');
    iconStylesheet.id = ADMIN_ICON_STYLESHEET_ID;
    iconStylesheet.rel = 'stylesheet';
    iconStylesheet.href = ADMIN_ICON_STYLESHEET_HREF;
    document.head.appendChild(iconStylesheet);
}

function createAdminSidebar() {
    ensureAdminIconStylesheet();

    const sidebarHTML = `
        <aside class="w-64 bg-gray-900 text-white h-screen fixed left-0 top-0 z-50 transform -translate-x-full lg:transform-none transition-transform duration-300 ease-in-out flex flex-col">
            <div class="p-6 border-b border-gray-800">
                <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 bg-maroon rounded-lg flex items-center justify-center">
                        <i class="fas fa-book"></i>
                    </div>
                    <div>
                        <h2 class="text-lg font-semibold">MathTuro</h2>
                        <p class="text-xs text-gray-400">Admin Portal</p>
                    </div>
                </div>
                <div class="mt-4">
                    <div class="flex items-center space-x-3">
                        <div id="userInitials" class="w-8 h-8 bg-gray-700 rounded-full flex items-center justify-center">
                            <span class="text-sm font-semibold">AD</span>
                        </div>
                        <div>
                            <p id="sidebarUserName" class="text-sm font-medium">Admin User</p>
                            <p class="text-xs text-gray-400">Administrator</p>
                        </div>
                    </div>
                </div>
            </div>

            <nav class="p-4 space-y-2 flex-1 overflow-y-auto">
                <a href="dashboard.html" class="nav-link flex items-center space-x-3 px-3 py-2 rounded-lg text-gray-300 hover:bg-gray-800 hover:text-white transition-colors" data-section="dashboard">
                    <i class="fas fa-tachometer-alt"></i>
                    <span>Dashboard</span>
                </a>

                <a href="users.html" class="nav-link flex items-center space-x-3 px-3 py-2 rounded-lg text-gray-300 hover:bg-gray-800 hover:text-white transition-colors" data-section="users">
                    <i class="fas fa-users"></i>
                    <span>Users</span>
                </a>

                <a href="grade-levels.html" class="nav-link flex items-center space-x-3 px-3 py-2 rounded-lg text-gray-300 hover:bg-gray-800 hover:text-white transition-colors" data-section="grade-levels">
                    <i class="fas fa-graduation-cap"></i>
                    <span>Grade Levels & Sections</span>
                </a>

                <div class="pt-4 border-t border-gray-800">
                    <button class="w-full nav-link flex items-center justify-between space-x-3 px-3 py-2 rounded-lg text-gray-300 hover:bg-gray-800 hover:text-white transition-colors" onclick="toggleFilesDropdown()">
                        <div class="flex items-center space-x-3">
                            <i class="fas fa-folder"></i>
                            <span>Files</span>
                        </div>
                        <i class="fas fa-chevron-down text-xs transition-transform duration-200" id="filesDropdownIcon"></i>
                    </button>
                    
                    <div id="filesDropdown" class="pl-4 mt-1 space-y-1 hidden">
                        <a href="lesson-plan.html" class="nav-link flex items-center space-x-3 px-3 py-2 rounded-lg text-gray-300 hover:bg-gray-800 hover:text-white transition-colors" data-section="lesson-plan">
                            <i class="fas fa-book"></i>
                            <span>Lesson Plans</span>
                        </a>

                        <a href="manage-modules.html" class="nav-link flex items-center space-x-3 px-3 py-2 rounded-lg text-gray-300 hover:bg-gray-800 hover:text-white transition-colors" data-section="manage-modules">
                            <i class="fas fa-folder-open"></i>
                            <span>Modules</span>
                        </a>

                        <a href="manage-videos.html" class="nav-link flex items-center space-x-3 px-3 py-2 rounded-lg text-gray-300 hover:bg-gray-800 hover:text-white transition-colors" data-section="manage-videos">
                            <i class="fas fa-video"></i>
                            <span>Videos</span>
                        </a>

                        <a href="manage-quizzes.html" class="nav-link flex items-center space-x-3 px-3 py-2 rounded-lg text-gray-300 hover:bg-gray-800 hover:text-white transition-colors" data-section="manage-quizzes">
                            <i class="fas fa-question-circle"></i>
                            <span>Quizzes</span>
                        </a>
                    </div>
                </div>

                <a href="activity.html" class="nav-link flex items-center space-x-3 px-3 py-2 rounded-lg text-gray-300 hover:bg-gray-800 hover:text-white transition-colors" data-section="activity">
                    <i class="fas fa-clock"></i>
                    <span>Activity Log</span>
                </a>

                <a href="analytics.html" class="nav-link flex items-center space-x-3 px-3 py-2 rounded-lg text-gray-300 hover:bg-gray-800 hover:text-white transition-colors" data-section="analytics">
                    <i class="fas fa-chart-bar"></i>
                    <span>Analytics</span>
                </a>

                <a href="system-status.html" class="nav-link flex items-center space-x-3 px-3 py-2 rounded-lg text-gray-300 hover:bg-gray-800 hover:text-white transition-colors" data-section="system-status">
                    <i class="fas fa-cog"></i>
                    <span>System Status</span>
                </a>

                <a href="settings.html" class="nav-link flex items-center space-x-3 px-3 py-2 rounded-lg text-gray-300 hover:bg-gray-800 hover:text-white transition-colors" data-section="settings">
                    <i class="fas fa-sliders-h"></i>
                    <span>Settings</span>
                </a>
            </nav>

            <div class="absolute bottom-0 left-0 right-0 p-4 border-t border-gray-800 bg-gray-900">
                <button id="logoutButton" class="w-full flex items-center space-x-3 px-3 py-2 text-left text-gray-300 hover:bg-gray-800 hover:text-white transition-colors">
                    <i class="fas fa-sign-out-alt"></i>
                    <span>Logout</span>
                </button>
            </div>
        </aside>
    `;

    let sidebarContainer = document.getElementById('sidebar');
    if (!sidebarContainer) {
        sidebarContainer = document.querySelector('.sidebar-container');
    }
    
    if (sidebarContainer) {
        if (sidebarContainer.tagName === 'ASIDE') {
            const wrapper = document.createElement('div');
            wrapper.innerHTML = sidebarHTML.trim();
            const generatedSidebar = wrapper.firstElementChild;

            sidebarContainer.className = generatedSidebar.className;
            sidebarContainer.innerHTML = generatedSidebar.innerHTML;
        } else {
            sidebarContainer.innerHTML = sidebarHTML;
        }
    }

     const currentPath = window.location.pathname.toLowerCase();
     
     const navLinks = document.querySelectorAll('.nav-link');
     
     navLinks.forEach(link => {
         const section = (link.getAttribute('data-section') || '').toLowerCase();
         const isSectionMatch = section && currentPath.includes(section);
         const isGradeSectionPair = section === 'grade-levels' && currentPath.includes('sections.html');

         if (isSectionMatch || isGradeSectionPair) {
             link.classList.remove('text-gray-300', 'hover:bg-gray-800', 'hover:text-white');
             link.classList.add('bg-maroon', 'text-white');
         }
     });

    const logoutButton = document.getElementById('logoutButton');
    if (logoutButton) {
        logoutButton.addEventListener('click', async () => {
            try {
                if (typeof logout === 'function') {
                    await logout();
                } else {
                    localStorage.removeItem('user');
                    const supabase = getSupabase();
                    if (supabase) {
                        await supabase.auth.signOut();
                    }
                }
                window.location.href = 'login.html';
            } catch (error) {
                console.error('Logout error:', error);
                window.location.href = 'login.html';
            }
        });
    }

    const mobileMenuBtn = document.getElementById('mobileMenuBtn');
    const mobileOverlay = document.getElementById('mobileOverlay');
    const sidebar = document.querySelector('aside');

    if (mobileMenuBtn) {
        mobileMenuBtn.addEventListener('click', () => {
            sidebar.classList.toggle('-translate-x-full');
            mobileOverlay.classList.toggle('hidden');
        });
    }

    if (mobileOverlay) {
        mobileOverlay.addEventListener('click', () => {
            sidebar.classList.add('-translate-x-full');
            mobileOverlay.classList.add('hidden');
        });
    }
}

function toggleFilesDropdown() {
    const dropdown = document.getElementById('filesDropdown');
    const icon = document.getElementById('filesDropdownIcon');
    
    dropdown.classList.toggle('hidden');
    icon.classList.toggle('rotate-180');
}

// Close dropdown when clicking outside
document.addEventListener('click', function(event) {
    const dropdown = document.getElementById('filesDropdown');
    const dropdownButton = document.querySelector('button[onclick="toggleFilesDropdown()"]');
    
    if (dropdown && !dropdown.contains(event.target) && 
        dropdownButton && !dropdownButton.contains(event.target)) {
        dropdown.classList.add('hidden');
        const filesDropdownIcon = document.getElementById('filesDropdownIcon');
        if (filesDropdownIcon) {
            filesDropdownIcon.classList.remove('rotate-180');
        }
    }
});

document.addEventListener('DOMContentLoaded', function() {
    createAdminSidebar();
    
    // Check if current path is in files dropdown to keep it open
    const currentPath = window.location.pathname;
    const filesSections = ['lesson-plan', 'manage-modules', 'manage-videos', 'manage-quizzes'];
    
    filesSections.forEach(section => {
        if (currentPath.includes(section)) {
            const dropdown = document.getElementById('filesDropdown');
            const icon = document.getElementById('filesDropdownIcon');
            if (dropdown) {
                dropdown.classList.remove('hidden');
                icon.classList.add('rotate-180');
            }
        }
    });
});
