/**
 * Advanced Path Manager - Dynamic Path Management with Environment Detection
 * Handles dynamic path resolution across different environments and deployment scenarios
 */

class PathManager {
    constructor() {
        this.isDevelopment = this.detectEnvironment();
        this.basePaths = this.initializeBasePaths();
        this.cache = new Map();
        this.observers = [];
    }

    detectEnvironment() {
        return (
            window.location.hostname === 'localhost' ||
            window.location.hostname === '127.0.0.1' ||
            window.location.hostname.includes('dev') ||
            window.location.port !== ''
        );
    }

    initializeBasePaths() {
        const protocol = window.location.protocol;
        const host = window.location.host;
        const pathname = window.location.pathname;

        return {
            api: this.isDevelopment ? 
                `${protocol}//${host}/api` : 
                'https://api.mathturo.com',
            assets: '/assets',
            shared: '/shared',
            images: '/assets/images',
            uploads: '/uploads',
            modules: '/modules',
            quizzes: '/quizzes',
            videos: '/videos'
        };
    }

    resolve(path, context = 'default') {
        const cacheKey = `${path}:${context}`;
        
        if (this.cache.has(cacheKey)) {
            return this.cache.get(cacheKey);
        }

        let resolvedPath = path;
        
        // Handle relative paths
        if (path.startsWith('./') || path.startsWith('../')) {
            resolvedPath = this.resolveRelativePath(path);
        }
        
        // Handle absolute paths
        else if (path.startsWith('/')) {
            resolvedPath = this.resolveAbsolutePath(path);
        }
        
        // Handle URL-based paths
        else if (path.startsWith('http://') || path.startsWith('https://')) {
            resolvedPath = path;
        }
        
        // Handle module-specific paths
        else if (this.basePaths[path]) {
            resolvedPath = this.basePaths[path];
        }

        // Add cache busting for development
        if (this.isDevelopment && this.isAssetPath(resolvedPath)) {
            resolvedPath = this.addCacheBusting(resolvedPath);
        }

        this.cache.set(cacheKey, resolvedPath);
        return resolvedPath;
    }

    resolveRelativePath(path) {
        const currentPath = window.location.pathname;
        const basePath = currentPath.substring(0, currentPath.lastIndexOf('/'));
        
        // Normalize and resolve the relative path
        const parts = path.split('/').filter(part => part !== '');
        const currentParts = basePath.split('/').filter(part => part !== '');
        
        parts.forEach(part => {
            if (part === '..') {
                currentParts.pop();
            } else if (part !== '.') {
                currentParts.push(part);
            }
        });
        
        return '/' + currentParts.join('/');
    }

    resolveAbsolutePath(path) {
        return path; // Already absolute
    }

    isAssetPath(path) {
        return /\.(js|css|png|jpg|jpeg|gif|svg|ico|woff|woff2|ttf|eot)$/i.test(path);
    }

    addCacheBusting(path) {
        const separator = path.includes('?') ? '&' : '?';
        return `${path}${separator}t=${Date.now()}`;
    }

    getApiEndpoint(endpoint) {
        return `${this.basePaths.api}${endpoint}`;
    }

    getAssetPath(asset) {
        return `${this.basePaths.assets}/${asset}`;
    }

    getSharedPath(resource) {
        return `${this.basePaths.shared}/${resource}`;
    }

    // Route management
    getRoleRoute(role, route) {
        const routes = {
            student: `/student/${route}`,
            teacher: `/teacher/${route}`,
            admin: `/admin/${route}`
        };
        return routes[role] || `/${route}`;
    }

    // Path validation
    isValidPath(path) {
        try {
            new URL(path, window.location.origin);
            return true;
        } catch {
            return false;
        }
    }

    // Cache management
    clearCache() {
        this.cache.clear();
    }

    // Observer pattern for path changes
    subscribe(callback) {
        this.observers.push(callback);
        return () => {
            this.observers = this.observers.filter(obs => obs !== callback);
        };
    }

    notify(pathChange) {
        this.observers.forEach(callback => callback(pathChange));
    }

    // Dynamic path updates
    updateBasePath(key, value) {
        this.basePaths[key] = value;
        this.clearCache();
        this.notify({ type: 'basePathUpdate', key, value });
    }

    // Utility methods
    getCurrentRole() {
        const path = window.location.pathname;
        if (path.includes('/student/')) return 'student';
        if (path.includes('/teacher/')) return 'teacher';
        if (path.includes('/admin/')) return 'admin';
        return 'public';
    }

    isInRoleSection(role) {
        return this.getCurrentRole() === role;
    }

    // API convenience methods
    getAuthEndpoint(action) {
        return this.getApiEndpoint(`/auth/${action}`);
    }

    getModulesEndpoint(action = '') {
        return this.getApiEndpoint(`/modules${action ? `/${action}` : ''}`);
    }

    getQuizzesEndpoint(action = '') {
        return this.getApiEndpoint(`/quizzes${action ? `/${action}` : ''}`);
    }

    getUsersEndpoint(action = '') {
        return this.getApiEndpoint(`/users${action ? `/${action}` : ''}`);
    }

    getSubmissionsEndpoint(action = '') {
        return this.getApiEndpoint(`/submissions${action ? `/${action}` : ''}`);
    }

    // Error handling for path resolution
    safeResolve(path, fallback = '/') {
        try {
            const resolved = this.resolve(path);
            return this.isValidPath(resolved) ? resolved : fallback;
        } catch (error) {
            console.warn(`Path resolution failed for "${path}":`, error);
            return fallback;
        }
    }
}

// Global instance
window.pathManager = new PathManager();

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PathManager;
}