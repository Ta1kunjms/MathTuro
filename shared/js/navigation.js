/**
 * Navigation Manager - Smart Routing, Breadcrumbs, and Keyboard Shortcuts
 * Advanced navigation system with SPA-like capabilities
 */

class NavigationManager {
    constructor() {
        this.config = this.initializeConfig();
        this.routes = new Map();
        this.currentRoute = null;
        this.navigationHistory = [];
        this.breadcrumbs = [];
        this.keyboardShortcuts = new Map();
        this.routeGuards = new Map();
        
        this.initializeRouter();
        this.setupKeyboardShortcuts();
        this.initializeBreadcrumbs();
        this.bindNavigationEvents();
    }

    initializeConfig() {
        return {
            enableHistory: true,
            enableBreadcrumbs: true,
            enableKeyboardShortcuts: true,
            maxHistoryLength: 50,
            routeTransitionDuration: 300,
            enableRouteGuards: true
        };
    }

    // Router Setup
    initializeRouter() {
        // Define application routes
        this.defineRoutes();
        
        // Handle initial route
        this.handleInitialRoute();
        
        // Setup history handling
        if (this.config.enableHistory) {
            window.addEventListener('popstate', (event) => {
                this.handleRouteChange(event.state?.route, false);
            });
        }
    }

    defineRoutes() {
        // Public routes
        this.addRoute('/', 'home', { title: 'Home', public: true });
        this.addRoute('/login', 'login', { title: 'Login', public: true });
        this.addRoute('/register', 'register', { title: 'Register', public: true });
        this.addRoute('/about', 'about', { title: 'About', public: true });
        this.addRoute('/contact', 'contact', { title: 'Contact', public: true });
        this.addRoute('/modules', 'modules', { title: 'Modules', public: true });
        this.addRoute('/tutorial-videos', 'tutorial-videos', { title: 'Tutorial Videos', public: true });

        // Student routes
        this.addRoute('/student/dashboard', 'student-dashboard', { 
            title: 'Student Dashboard', 
            role: 'student',
            icon: 'dashboard'
        });
        this.addRoute('/student/modules', 'student-modules', { 
            title: 'Modules', 
            role: 'student',
            parent: '/student/dashboard'
        });
        this.addRoute('/student/module-view/:id', 'student-module-view', { 
            title: 'Module View', 
            role: 'student',
            parent: '/student/modules'
        });
        this.addRoute('/student/quizzes', 'student-quizzes', { 
            title: 'Quizzes', 
            role: 'student',
            parent: '/student/dashboard'
        });

        // Teacher routes
        this.addRoute('/teacher/dashboard', 'teacher-dashboard', { 
            title: 'Teacher Dashboard', 
            role: 'teacher',
            icon: 'dashboard'
        });
        this.addRoute('/teacher/manage-modules', 'teacher-manage-modules', { 
            title: 'Manage Modules', 
            role: 'teacher',
            parent: '/teacher/dashboard'
        });
        this.addRoute('/teacher/manage-quizzes', 'teacher-manage-quizzes', { 
            title: 'Manage Quizzes', 
            role: 'teacher',
            parent: '/teacher/dashboard'
        });
        this.addRoute('/teacher/manage-videos', 'teacher-manage-videos', { 
            title: 'Manage Videos', 
            role: 'teacher',
            parent: '/teacher/dashboard'
        });
        this.addRoute('/teacher/student-progress', 'teacher-student-progress', { 
            title: 'Student Progress', 
            role: 'teacher',
            parent: '/teacher/dashboard'
        });
        this.addRoute('/teacher/reports', 'teacher-reports', { 
            title: 'Reports', 
            role: 'teacher',
            parent: '/teacher/dashboard'
        });
        this.addRoute('/teacher/submissions', 'teacher-submissions', { 
            title: 'Submissions', 
            role: 'teacher',
            parent: '/teacher/dashboard'
        });

        // Admin routes
        this.addRoute('/admin/dashboard', 'admin-dashboard', { 
            title: 'Admin Dashboard', 
            role: 'admin',
            icon: 'dashboard'
        });
        this.addRoute('/admin/users', 'admin-users', { 
            title: 'Users', 
            role: 'admin',
            parent: '/admin/dashboard'
        });
        this.addRoute('/admin/grade-levels', 'admin-grade-levels', { 
            title: 'Grade Levels & Sections', 
            role: 'admin',
            parent: '/admin/dashboard'
        });
        this.addRoute('/admin/lesson-plan', 'admin-lesson-plan', { 
            title: 'Lesson Plans', 
            role: 'admin',
            parent: '/admin/dashboard'
        });
        this.addRoute('/admin/manage-modules', 'admin-manage-modules', { 
            title: 'Manage Modules', 
            role: 'admin',
            parent: '/admin/dashboard'
        });
        this.addRoute('/admin/manage-videos', 'admin-manage-videos', { 
            title: 'Manage Videos', 
            role: 'admin',
            parent: '/admin/dashboard'
        });
        this.addRoute('/admin/manage-quizzes', 'admin-manage-quizzes', { 
            title: 'Manage Quizzes', 
            role: 'admin',
            parent: '/admin/dashboard'
        });
        this.addRoute('/admin/activity', 'admin-activity', { 
            title: 'Activity Log', 
            role: 'admin',
            parent: '/admin/dashboard'
        });
        this.addRoute('/admin/analytics', 'admin-analytics', { 
            title: 'Analytics', 
            role: 'admin',
            parent: '/admin/dashboard'
        });
        this.addRoute('/admin/system-status', 'admin-system-status', { 
            title: 'System Status', 
            role: 'admin',
            parent: '/admin/dashboard'
        });
        this.addRoute('/admin/settings', 'admin-settings', { 
            title: 'Settings', 
            role: 'admin',
            parent: '/admin/dashboard'
        });
    }

    addRoute(path, name, options = {}) {
        this.routes.set(path, {
            path,
            name,
            title: options.title || name,
            role: options.role || null,
            public: options.public || false,
            icon: options.icon || null,
            parent: options.parent || null,
            component: options.component || null,
            guard: options.guard || null,
            ...options
        });
    }

    // Route Management
    navigateTo(path, data = {}, replace = false) {
        const route = this.matchRoute(path);
        
        if (!route) {
            console.warn(`Route not found: ${path}`);
            return false;
        }

        // Check route guards
        if (this.config.enableRouteGuards && !this.checkRouteGuard(route)) {
            return false;
        }

        // Update history
        if (this.config.enableHistory) {
            const state = { route: path, data };
            const method = replace ? 'replaceState' : 'pushState';
            history[method](state, route.title, path);
        }

        // Handle route change
        this.handleRouteChange(route, true, data);
        
        return true;
    }

    handleInitialRoute() {
        const currentPath = window.location.pathname;
        const route = this.matchRoute(currentPath);
        
        if (route) {
            this.handleRouteChange(route, false);
        } else {
            // Redirect to home or dashboard
            this.redirectToDefault();
        }
    }

    handleRouteChange(route, addToHistory = true, data = {}) {
        // Check if route is accessible
        if (!this.isRouteAccessible(route)) {
            this.redirectToLogin();
            return;
        }

        const previousRoute = this.currentRoute;
        this.currentRoute = route;

        // Update navigation history
        if (addToHistory && this.config.enableHistory) {
            this.navigationHistory.push({
                route,
                timestamp: Date.now(),
                data
            });
            
            // Limit history length
            if (this.navigationHistory.length > this.config.maxHistoryLength) {
                this.navigationHistory = this.navigationHistory.slice(-this.config.maxHistoryLength);
            }
        }

        // Update breadcrumbs
        if (this.config.enableBreadcrumbs) {
            this.updateBreadcrumbs(route);
        }

        // Update page title
        this.updatePageTitle(route);

        // Emit navigation event
        window.dispatchEvent(new CustomEvent('navigation:route-changed', {
            detail: {
                from: previousRoute,
                to: route,
                data
            }
        }));

        // Handle route-specific logic
        this.handleRouteSpecificLogic(route);
    }

    matchRoute(path) {
        // Exact match first
        if (this.routes.has(path)) {
            return this.routes.get(path);
        }

        // Parameterized routes
        for (const [routePath, route] of this.routes.entries()) {
            if (this.pathMatches(path, routePath)) {
                return { ...route, params: this.extractPathParams(path, routePath) };
            }
        }

        return null;
    }

    pathMatches(path, routePath) {
        const pathParts = path.split('/').filter(Boolean);
        const routeParts = routePath.split('/').filter(Boolean);
        
        if (pathParts.length !== routeParts.length) {
            return false;
        }

        return routeParts.every((part, index) => {
            return part.startsWith(':') || part === pathParts[index];
        });
    }

    extractPathParams(path, routePath) {
        const pathParts = path.split('/').filter(Boolean);
        const routeParts = routePath.split('/').filter(Boolean);
        const params = {};
        
        routeParts.forEach((part, index) => {
            if (part.startsWith(':')) {
                const paramName = part.slice(1);
                params[paramName] = pathParts[index];
            }
        });
        
        return params;
    }

    // Route Guards
    checkRouteGuard(route) {
        // Role-based guard
        if (route.role && route.role !== 'public') {
            const userRole = this.getCurrentUserRole();
            if (userRole !== route.role) {
                this.redirectToLogin();
                return false;
            }
        }

        // Custom guard
        if (route.guard && typeof route.guard === 'function') {
            return route.guard(route);
        }

        return true;
    }

    isRouteAccessible(route) {
        // Public routes are always accessible
        if (route.public) {
            return true;
        }

        // Check authentication
        const isAuthenticated = this.isAuthenticated();
        if (!isAuthenticated) {
            return false;
        }

        // Check role
        if (route.role) {
            const userRole = this.getCurrentUserRole();
            return userRole === route.role;
        }

        return true;
    }

    // Breadcrumbs
    initializeBreadcrumbs() {
        this.breadcrumbContainer = this.createBreadcrumbContainer();
    }

    createBreadcrumbContainer() {
        let container = document.querySelector('.breadcrumb-container');
        
        if (!container) {
            container = document.createElement('nav');
            container.className = 'breadcrumb-container';
            container.setAttribute('aria-label', 'breadcrumb');
            
            // Insert after header or at beginning of body
            const header = document.querySelector('header');
            if (header) {
                header.insertAdjacentElement('afterend', container);
            } else {
                document.body.insertAdjacentElement('afterbegin', container);
            }
        }
        
        return container;
    }

    updateBreadcrumbs(route) {
        this.breadcrumbs = this.generateBreadcrumbs(route);
        this.renderBreadcrumbs();
    }

    generateBreadcrumbs(route) {
        const breadcrumbs = [];
        const visited = new Set();
        
        // Build breadcrumb trail
        this.buildBreadcrumbTrail(route, breadcrumbs, visited);
        
        // Reverse to get correct order
        return breadcrumbs.reverse();
    }

    buildBreadcrumbTrail(route, breadcrumbs, visited) {
        if (!route || visited.has(route.path)) {
            return;
        }
        
        visited.add(route.path);
        
        // Add current route
        breadcrumbs.push({
            title: route.title,
            path: route.path,
            icon: route.icon
        });
        
        // Add parent
        if (route.parent) {
            const parentRoute = this.matchRoute(route.parent);
            this.buildBreadcrumbTrail(parentRoute, breadcrumbs, visited);
        }
    }

    renderBreadcrumbs() {
        if (!this.breadcrumbContainer || this.breadcrumbs.length === 0) {
            return;
        }

        const html = `
            <ol class="breadcrumb-list">
                ${this.breadcrumbs.map((crumb, index) => `
                    <li class="breadcrumb-item ${index === this.breadcrumbs.length - 1 ? 'active' : ''}">
                        ${index === 0 ? `
                            <a href="${crumb.path}" class="breadcrumb-link">
                                ${crumb.icon ? `<i class="icon-${crumb.icon}"></i>` : ''}
                                Home
                            </a>
                        ` : index < this.breadcrumbs.length - 1 ? `
                            <a href="${crumb.path}" class="breadcrumb-link">
                                ${crumb.icon ? `<i class="icon-${crumb.icon}"></i>` : ''}
                                ${crumb.title}
                            </a>
                        ` : `
                            <span class="breadcrumb-current">
                                ${crumb.icon ? `<i class="icon-${crumb.icon}"></i>` : ''}
                                ${crumb.title}
                            </span>
                        `}
                    </li>
                `).join('')}
            </ol>
        `;

        this.breadcrumbContainer.innerHTML = html;
    }

    // Keyboard Shortcuts
    setupKeyboardShortcuts() {
        if (!this.config.enableKeyboardShortcuts) return;

        // Define default shortcuts
        this.addKeyboardShortcut('Ctrl+K', () => this.openCommandPalette());
        this.addKeyboardShortcut('Ctrl+/', () => this.showKeyboardShortcuts());
        this.addKeyboardShortcut('Ctrl+H', () => this.navigateHome());
        this.addKeyboardShortcut('Ctrl+B', () => this.goBack());
        this.addKeyboardShortcut('Ctrl+F', () => this.focusSearch());
        this.addKeyboardShortcut('Escape', () => this.closeModals());

        // Global keyboard event listener
        document.addEventListener('keydown', (event) => {
            this.handleKeyboardShortcut(event);
        });
    }

    addKeyboardShortcut(combo, handler) {
        this.keyboardShortcuts.set(combo.toLowerCase(), handler);
    }

    handleKeyboardShortcut(event) {
        const combo = this.getKeyboardCombo(event);
        const handler = this.keyboardShortcuts.get(combo);
        
        if (handler) {
            event.preventDefault();
            handler(event);
        }
    }

    getKeyboardCombo(event) {
        const parts = [];
        
        if (event.ctrlKey) parts.push('ctrl');
        if (event.altKey) parts.push('alt');
        if (event.shiftKey) parts.push('shift');
        if (event.metaKey) parts.push('meta');
        
        parts.push(event.key.toLowerCase());
        
        return parts.join('+');
    }

    // Navigation Utilities
    goBack() {
        if (this.navigationHistory.length > 1) {
            window.history.back();
        } else {
            this.navigateHome();
        }
    }

    goForward() {
        window.history.forward();
    }

    navigateHome() {
        const userRole = this.getCurrentUserRole();
        const homePath = userRole ? `/${userRole}/dashboard` : '/';
        this.navigateTo(homePath);
    }

    redirectToLogin() {
        this.navigateTo('/login', { redirect: window.location.pathname });
    }

    redirectToDefault() {
        const userRole = this.getCurrentUserRole();
        if (userRole) {
            this.navigateTo(`/${userRole}/dashboard`);
        } else {
            this.navigateTo('/');
        }
    }

    // Authentication helpers
    isAuthenticated() {
        // Check with auth manager
        return window.authManager?.isAuthenticated() || 
               localStorage.getItem('authToken') !== null;
    }

    getCurrentUserRole() {
        // Get role from auth manager or storage
        return window.authManager?.getUser()?.role || 
               localStorage.getItem('userRole');
    }

    // Page management
    updatePageTitle(route) {
        document.title = `${route.title} - MathTuro LMS`;
    }

    handleRouteSpecificLogic(route) {
        // Role-specific logic
        switch (route.role) {
            case 'student':
                this.handleStudentRoute(route);
                break;
            case 'teacher':
                this.handleTeacherRoute(route);
                break;
            case 'admin':
                this.handleAdminRoute(route);
                break;
        }
    }

    handleStudentRoute(route) {
        // Student-specific navigation logic
        this.updateSidebar('student');
    }

    handleTeacherRoute(route) {
        // Teacher-specific navigation logic
        this.updateSidebar('teacher');
    }

    handleAdminRoute(route) {
        // Admin-specific navigation logic
        this.updateSidebar('admin');
    }

    updateSidebar(role) {
        const sidebar = document.querySelector('.sidebar');
        if (sidebar) {
            sidebar.setAttribute('data-role', role);
        }
    }

    // Shortcut actions
    openCommandPalette() {
        // Implementation for command palette
        window.dispatchEvent(new CustomEvent('command-palette:open'));
    }

    showKeyboardShortcuts() {
        // Show keyboard shortcuts modal
        window.dispatchEvent(new CustomEvent('shortcuts:show'));
    }

    focusSearch() {
        const searchInput = document.querySelector('[data-search-input]');
        if (searchInput) {
            searchInput.focus();
        }
    }

    closeModals() {
        const modals = document.querySelectorAll('.modal.show');
        modals.forEach(modal => {
            modal.classList.remove('show');
        });
    }

    // Event binding
    bindNavigationEvents() {
        // Handle internal link clicks
        document.addEventListener('click', (event) => {
            const link = event.target.closest('a[href]');
            if (link && this.isInternalLink(link)) {
                event.preventDefault();
                this.navigateTo(link.getAttribute('href'));
            }
        });

        // Handle form submissions with action
        document.addEventListener('submit', (event) => {
            const form = event.target;
            const action = form.getAttribute('action');
            
            if (action && this.isInternalLink({ href: action })) {
                event.preventDefault();
                this.navigateTo(action, new FormData(form));
            }
        });
    }

    isInternalLink(link) {
        const href = link.getAttribute('href');
        if (!href) return false;
        
        return href.startsWith('/') || href.startsWith(window.location.origin);
    }

    // Analytics
    trackNavigation(from, to) {
        if (window.analytics) {
            window.analytics.track('page_view', {
                path: to.path,
                title: to.title,
                referrer: from?.path
            });
        }
    }

    // Public API
    getCurrentRoute() {
        return this.currentRoute;
    }

    getNavigationHistory() {
        return [...this.navigationHistory];
    }

    getBreadcrumbs() {
        return [...this.breadcrumbs];
    }

    getAllRoutes() {
        return Array.from(this.routes.values());
    }

    getRoutesByRole(role) {
        return this.getAllRoutes().filter(route => route.role === role || route.public);
    }
}

// Global navigation manager instance
window.navigationManager = new NavigationManager();

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    // Additional initialization can go here
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = NavigationManager;
}