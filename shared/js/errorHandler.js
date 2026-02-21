/**
 * Error Handler - Global Error Handling with User-Friendly Messages
 * Comprehensive error management system for web applications
 */

class ErrorHandler {
    constructor() {
        this.config = this.initializeConfig();
        this.errorLog = [];
        this.errorListeners = new Map();
        this.retryAttempts = new Map();
        this.criticalErrors = new Set();
        
        this.initializeErrorHandling();
        this.bindErrorEvents();
        this.setupErrorReporting();
    }

    initializeConfig() {
        return {
            maxErrorLogSize: 1000,
            enableErrorReporting: true,
            enableUserNotifications: true,
            retryMaxAttempts: 3,
            retryDelay: 1000,
            enablePerformanceErrors: true,
            enableNetworkErrors: true,
            userFriendlyMessages: true,
            logToConsole: true,
            enableErrorAnalytics: true
        };
    }

    initializeErrorHandling() {
        // Setup global error handlers
        this.setupGlobalErrorHandlers();
        
        // Setup unhandled promise rejection handler
        this.setupPromiseRejectionHandler();
        
        // Setup resource error handler
        this.setupResourceErrorHandler();
    }

    setupGlobalErrorHandlers() {
        window.addEventListener('error', (event) => {
            this.handleError({
                type: 'javascript',
                message: event.message,
                filename: event.filename,
                lineno: event.lineno,
                colno: event.colno,
                stack: event.error?.stack,
                timestamp: Date.now(),
                userAgent: navigator.userAgent,
                url: window.location.href
            });
        });
    }

    setupPromiseRejectionHandler() {
        window.addEventListener('unhandledrejection', (event) => {
            this.handleError({
                type: 'promise',
                message: event.reason?.message || 'Unhandled Promise Rejection',
                stack: event.reason?.stack,
                timestamp: Date.now(),
                userAgent: navigator.userAgent,
                url: window.location.href,
                promise: event.promise
            });
        });
    }

    setupResourceErrorHandler() {
        window.addEventListener('error', (event) => {
            if (event.target !== window) {
                this.handleError({
                    type: 'resource',
                    message: `Failed to load resource: ${event.target.src || event.target.href}`,
                    element: event.target.tagName,
                    source: event.target.src || event.target.href,
                    timestamp: Date.now(),
                    userAgent: navigator.userAgent,
                    url: window.location.href
                });
            }
        }, true);
    }

    bindErrorEvents() {
        // API errors
        window.addEventListener('api:error', (event) => {
            this.handleError({
                type: 'api',
                message: event.detail.message,
                status: event.detail.status,
                endpoint: event.detail.endpoint,
                timestamp: Date.now(),
                userAgent: navigator.userAgent,
                url: window.location.href
            });
        });

        // Performance errors
        if (this.config.enablePerformanceErrors) {
            window.addEventListener('performance:issues-detected', (event) => {
                this.handleError({
                    type: 'performance',
                    message: 'Performance issues detected',
                    issues: event.detail.issues,
                    metrics: event.detail.metrics,
                    timestamp: Date.now(),
                    userAgent: navigator.userAgent,
                    url: window.location.href
                });
            });
        }

        // Security errors
        window.addEventListener('security:event', (event) => {
            if (event.detail.type === 'SECURITY_VIOLATION') {
                this.handleError({
                    type: 'security',
                    message: 'Security violation detected',
                    violation: event.detail.data,
                    timestamp: Date.now(),
                    userAgent: navigator.userAgent,
                    url: window.location.href
                });
            }
        });
    }

    setupErrorReporting() {
        if (this.config.enableErrorReporting) {
            // Setup periodic error reporting
            setInterval(() => {
                this.reportErrors();
            }, 60000); // Report every minute
        }
    }

    // Core Error Handling
    handleError(error) {
        // Add unique ID to error
        error.id = this.generateErrorId();
        
        // Categorize error
        error.category = this.categorizeError(error);
        error.severity = this.determineSeverity(error);
        
        // Add to error log
        this.logError(error);
        
        // Show user notification if needed
        if (this.config.enableUserNotifications && error.severity >= 3) {
            this.showUserNotification(error);
        }
        
        // Log to console
        if (this.config.logToConsole) {
            this.logToConsole(error);
        }
        
        // Emit error event
        this.emitErrorEvent(error);
        
        // Check if critical error
        if (error.severity >= 4) {
            this.handleCriticalError(error);
        }
        
        return error.id;
    }

    generateErrorId() {
        return `err_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    categorizeError(error) {
        const categories = {
            'javascript': 'client',
            'promise': 'client',
            'resource': 'resource',
            'api': 'network',
            'performance': 'performance',
            'security': 'security'
        };
        
        return categories[error.type] || 'unknown';
    }

    determineSeverity(error) {
        // Severity levels: 1=Info, 2=Warning, 3=Error, 4=Critical, 5=Fatal
        
        if (error.type === 'security') return 4;
        if (error.type === 'critical') return 5;
        
        if (error.type === 'api' && error.status >= 500) return 4;
        if (error.type === 'api' && error.status >= 400) return 3;
        
        if (error.type === 'resource') return 2;
        if (error.type === 'performance') return 2;
        
        if (error.type === 'javascript' || error.type === 'promise') return 3;
        
        return 2;
    }

    logError(error) {
        this.errorLog.push(error);
        
        // Limit log size
        if (this.errorLog.length > this.config.maxErrorLogSize) {
            this.errorLog = this.errorLog.slice(-this.config.maxErrorLogSize);
        }
    }

    showUserNotification(error) {
        const message = this.getUserFriendlyMessage(error);
        const type = this.getNotificationType(error.severity);
        
        if (window.componentManager) {
            window.componentManager.showNotification({
                type,
                title: error.category === 'network' ? 'Network Error' : 'Application Error',
                message,
                duration: error.severity >= 4 ? 10000 : 5000
            });
        } else {
            // Fallback notification
            console.warn('Error:', message);
        }
    }

    getUserFriendlyMessage(error) {
        if (!this.config.userFriendlyMessages) {
            return error.message;
        }

        const messages = {
            'network': 'Unable to connect to the server. Please check your internet connection and try again.',
            'api': 'Unable to complete the requested action. Please try again later.',
            'resource': 'Some resources failed to load. The page may not work correctly.',
            'javascript': 'An unexpected error occurred. Please refresh the page and try again.',
            'performance': 'The application is running slowly. Some features may be affected.',
            'security': 'A security issue was detected and has been resolved.',
            'unknown': 'An unexpected error occurred. Please try again.'
        };

        return messages[error.category] || messages.unknown;
    }

    getNotificationType(severity) {
        if (severity >= 4) return 'error';
        if (severity >= 3) return 'warning';
        return 'info';
    }

    logToConsole(error) {
        const method = error.severity >= 3 ? 'error' : 'warn';
        console[method](`[${error.type.toUpperCase()}] ${error.message}`, error);
    }

    emitErrorEvent(error) {
        window.dispatchEvent(new CustomEvent('error:handled', {
            detail: error
        }));
    }

    handleCriticalError(error) {
        if (this.criticalErrors.has(error.id)) return;
        
        this.criticalErrors.add(error.id);
        
        // Attempt recovery
        this.attemptErrorRecovery(error);
        
        // Report critical error immediately
        this.reportCriticalError(error);
    }

    attemptErrorRecovery(error) {
        switch (error.type) {
            case 'api':
                this.attemptAPIRecovery(error);
                break;
            case 'resource':
                this.attemptResourceRecovery(error);
                break;
            case 'javascript':
                this.attemptJavaScriptRecovery(error);
                break;
        }
    }

    attemptAPIRecovery(error) {
        const endpoint = error.endpoint;
        const attempts = this.retryAttempts.get(endpoint) || 0;
        
        if (attempts < this.config.retryMaxAttempts) {
            this.retryAttempts.set(endpoint, attempts + 1);
            
            setTimeout(() => {
                window.dispatchEvent(new CustomEvent('api:retry', {
                    detail: { endpoint, attempts: attempts + 1 }
                }));
            }, this.config.retryDelay * Math.pow(2, attempts));
        }
    }

    attemptResourceRecovery(error) {
        // Attempt to reload failed resources
        if (error.source) {
            const resource = document.querySelector(`[src="${error.source}"], [href="${error.source}"]`);
            if (resource) {
                // Add cache-busting parameter
                const separator = error.source.includes('?') ? '&' : '?';
                const newSource = `${error.source}${separator}_retry=${Date.now()}`;
                
                if (resource.tagName === 'IMG') {
                    resource.src = newSource;
                } else if (resource.tagName === 'LINK') {
                    resource.href = newSource;
                }
            }
        }
    }

    attemptJavaScriptRecovery(error) {
        // Clear problematic state
        if (window.location.reload) {
            // Show recovery dialog
            this.showRecoveryDialog(error);
        }
    }

    showRecoveryDialog(error) {
        if (window.componentManager) {
            const modalId = window.componentManager.showModal({
                title: 'Application Error',
                content: `
                    <div class="error-recovery">
                        <p>The application encountered an error and needs to be refreshed.</p>
                        <details>
                            <summary>Error Details</summary>
                            <pre>${error.message}</pre>
                        </details>
                    </div>
                `,
                footer: `
                    <button class="btn btn-primary" onclick="window.location.reload()">
                        Refresh Page
                    </button>
                    <button class="btn btn-secondary" onclick="window.componentManager.hideModal('${modalId}')">
                        Continue Anyway
                    </button>
                `,
                closeOnBackdrop: false,
                closeOnEscape: false
            });
        }
    }

    // Error Reporting
    reportErrors() {
        if (!this.config.enableErrorReporting || this.errorLog.length === 0) {
            return;
        }

        const unreportedErrors = this.errorLog.filter(error => !error.reported);
        
        if (unreportedErrors.length === 0) return;

        const errorReport = {
            errors: unreportedErrors,
            userAgent: navigator.userAgent,
            url: window.location.href,
            timestamp: Date.now(),
            sessionId: this.getSessionId()
        };

        // Send error report
        this.sendErrorReport(errorReport)
            .then(() => {
                // Mark errors as reported
                unreportedErrors.forEach(error => error.reported = true);
            })
            .catch(err => {
                console.warn('Failed to send error report:', err);
            });
    }

    reportCriticalError(error) {
        const errorReport = {
            errors: [error],
            userAgent: navigator.userAgent,
            url: window.location.href,
            timestamp: Date.now(),
            sessionId: this.getSessionId(),
            critical: true
        };

        this.sendErrorReport(errorReport);
    }

    async sendErrorReport(report) {
        // Send to error tracking service
        if (window.apiClient) {
            try {
                await window.apiClient.post('/errors/report', report);
            } catch (err) {
                console.warn('Failed to send error report:', err);
            }
        }
        
        // Log to console in development
        if (window.pathManager?.isDevelopment) {
            console.log('Error Report:', report);
        }
    }

    getSessionId() {
        let sessionId = sessionStorage.getItem('errorSessionId');
        if (!sessionId) {
            sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            sessionStorage.setItem('errorSessionId', sessionId);
        }
        return sessionId;
    }

    // Error Analytics
    getErrorAnalytics() {
        const analytics = {
            totalErrors: this.errorLog.length,
            errorsByType: {},
            errorsByCategory: {},
            errorsBySeverity: {},
            recentErrors: this.getRecentErrors(24), // Last 24 hours
            criticalErrors: Array.from(this.criticalErrors).length,
            errorRate: this.calculateErrorRate()
        };

        this.errorLog.forEach(error => {
            analytics.errorsByType[error.type] = (analytics.errorsByType[error.type] || 0) + 1;
            analytics.errorsByCategory[error.category] = (analytics.errorsByCategory[error.category] || 0) + 1;
            analytics.errorsBySeverity[error.severity] = (analytics.errorsBySeverity[error.severity] || 0) + 1;
        });

        return analytics;
    }

    getRecentErrors(hours = 24) {
        const cutoff = Date.now() - (hours * 60 * 60 * 1000);
        return this.errorLog.filter(error => error.timestamp > cutoff);
    }

    calculateErrorRate() {
        const sessionStart = this.getSessionStartTime();
        const sessionDuration = Date.now() - sessionStart;
        const errorsInSession = this.errorLog.filter(error => error.timestamp >= sessionStart);
        
        return sessionDuration > 0 ? (errorsInSession.length / (sessionDuration / 1000 / 60)) : 0; // errors per minute
    }

    getSessionStartTime() {
        let startTime = sessionStorage.getItem('sessionStartTime');
        if (!startTime) {
            startTime = Date.now();
            sessionStorage.setItem('sessionStartTime', startTime);
        }
        return parseInt(startTime);
    }

    // Public API
    getErrors(type = null, category = null, limit = 50) {
        let errors = this.errorLog;
        
        if (type) {
            errors = errors.filter(error => error.type === type);
        }
        
        if (category) {
            errors = errors.filter(error => error.category === category);
        }
        
        return errors.slice(-limit);
    }

    getErrorById(errorId) {
        return this.errorLog.find(error => error.id === errorId);
    }

    clearErrors() {
        this.errorLog = [];
        this.criticalErrors.clear();
        this.retryAttempts.clear();
    }

    clearErrorsBefore(timestamp) {
        this.errorLog = this.errorLog.filter(error => error.timestamp > timestamp);
    }

    // Event Listener Management
    onError(listener) {
        const id = this.generateListenerId();
        this.errorListeners.set(id, listener);
        return id;
    }

    offError(id) {
        return this.errorListeners.delete(id);
    }

    generateListenerId() {
        return `listener_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    notifyListeners(error) {
        this.errorListeners.forEach(listener => {
            try {
                listener(error);
            } catch (err) {
                console.error('Error in error listener:', err);
            }
        });
    }

    // Debugging
    enableDebugMode() {
        this.config.logToConsole = true;
        this.config.userFriendlyMessages = false;
    }

    disableDebugMode() {
        this.config.logToConsole = false;
        this.config.userFriendlyMessages = true;
    }

    // Health Check
    getHealthStatus() {
        const analytics = this.getErrorAnalytics();
        
        return {
            status: this.calculateHealthStatus(analytics),
            analytics,
            recommendations: this.generateHealthRecommendations(analytics)
        };
    }

    calculateHealthStatus(analytics) {
        if (analytics.criticalErrors > 0) return 'critical';
        if (analytics.errorRate > 5) return 'warning';
        if (analytics.totalErrors > 100) return 'warning';
        return 'healthy';
    }

    generateHealthRecommendations(analytics) {
        const recommendations = [];
        
        if (analytics.criticalErrors > 0) {
            recommendations.push('Address critical errors immediately');
        }
        
        if (analytics.errorRate > 5) {
            recommendations.push('High error rate detected - investigate application stability');
        }
        
        if (analytics.errorsByType.api > analytics.totalErrors * 0.5) {
            recommendations.push('High number of API errors - check backend connectivity');
        }
        
        if (analytics.errorsByType.javascript > analytics.totalErrors * 0.3) {
            recommendations.push('JavaScript errors detected - review client-side code');
        }
        
        return recommendations;
    }
}

// Global error handler instance
window.errorHandler = new ErrorHandler();

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ErrorHandler;
}