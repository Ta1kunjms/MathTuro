/**
 * Security Module - CSRF Protection, Input Sanitization, and Security Monitoring
 * Comprehensive security utilities for web application protection
 */

class SecurityManager {
    constructor() {
        this.csrfToken = null;
        this.securityConfig = this.initializeConfig();
        this.securityEvents = [];
        this.rateLimiter = new Map();
        this.securityHeaders = this.generateSecurityHeaders();
        
        this.initializeCSRF();
        this.setupSecurityMonitoring();
        this.bindSecurityEvents();
    }

    initializeConfig() {
        return {
            maxSecurityEvents: 1000,
            rateLimitWindow: 60000, // 1 minute
            rateLimitMax: 100, // 100 requests per minute
            allowedOrigins: [
                window.location.origin,
                'https://mathturo.com',
                'https://www.mathturo.com'
            ],
            sanitizeHTML: true,
            preventXSS: true,
            enableCSRF: true,
            logSecurityEvents: true
        };
    }

    // CSRF Protection
    initializeCSRF() {
        if (!this.securityConfig.enableCSRF) return;
        
        this.csrfToken = this.generateCSRFToken();
        this.storeCSRFToken();
        this.setupCSRFHeaders();
    }

    generateCSRFToken() {
        const array = new Uint8Array(32);
        crypto.getRandomValues(array);
        return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
    }

    storeCSRFToken() {
        localStorage.setItem('csrfToken', this.csrfToken);
        sessionStorage.setItem('csrfToken', this.csrfToken);
    }

    getCSRFToken() {
        return this.csrfToken || 
               localStorage.getItem('csrfToken') || 
               sessionStorage.getItem('csrfToken');
    }

    setupCSRFHeaders() {
        // Add CSRF token to all form submissions
        document.addEventListener('submit', (event) => {
            const form = event.target;
            if (form.tagName === 'FORM') {
                const csrfInput = form.querySelector('input[name="csrf_token"]') ||
                                document.createElement('input');
                csrfInput.type = 'hidden';
                csrfInput.name = 'csrf_token';
                csrfInput.value = this.getCSRFToken();
                
                if (!form.contains(csrfInput)) {
                    form.appendChild(csrfInput);
                }
            }
        });
    }

    validateCSRFToken(token) {
        const storedToken = this.getCSRFToken();
        return token && storedToken && token === storedToken;
    }

    // Input Sanitization
    sanitizeInput(input, type = 'text') {
        if (typeof input !== 'string') {
            return input;
        }

        let sanitized = input.trim();

        switch (type) {
            case 'html':
                sanitized = this.sanitizeHTML(sanitized);
                break;
            case 'script':
                sanitized = this.sanitizeScript(sanitized);
                break;
            case 'url':
                sanitized = this.sanitizeURL(sanitized);
                break;
            case 'email':
                sanitized = this.sanitizeEmail(sanitized);
                break;
            case 'number':
                sanitized = this.sanitizeNumber(sanitized);
                break;
            case 'alphanumeric':
                sanitized = this.sanitizeAlphanumeric(sanitized);
                break;
            default:
                sanitized = this.sanitizeText(sanitized);
        }

        return sanitized;
    }

    sanitizeHTML(html) {
        if (!this.securityConfig.sanitizeHTML) return html;

        const temp = document.createElement('div');
        temp.textContent = html;
        return temp.innerHTML;
    }

    sanitizeScript(script) {
        // Remove all JavaScript content
        return script.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
                   .replace(/javascript:/gi, '')
                   .replace(/on\w+\s*=/gi, '');
    }

    sanitizeURL(url) {
        try {
            const parsed = new URL(url, window.location.origin);
            
            // Check if allowed origin
            const isAllowed = this.securityConfig.allowedOrigins.some(origin => 
                parsed.origin === origin || origin === '*'
            );
            
            if (!isAllowed) {
                throw new Error('URL origin not allowed');
            }
            
            // Remove dangerous protocols
            if (['javascript:', 'data:', 'vbscript:'].includes(parsed.protocol)) {
                throw new Error('Dangerous protocol detected');
            }
            
            return parsed.toString();
        } catch (error) {
            this.logSecurityEvent('URL_SANITIZATION_FAILED', { url, error: error.message });
            return '#';
        }
    }

    sanitizeEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        const sanitized = email.toLowerCase().trim();
        
        if (!emailRegex.test(sanitized)) {
            this.logSecurityEvent('INVALID_EMAIL', { email });
            return '';
        }
        
        return sanitized;
    }

    sanitizeNumber(input) {
        const number = parseFloat(input);
        return isNaN(number) ? 0 : number;
    }

    sanitizeAlphanumeric(input) {
        return input.replace(/[^a-zA-Z0-9]/g, '');
    }

    sanitizeText(text) {
        return text
            .replace(/[<>]/g, '') // Remove potential HTML tags
            .replace(/[\x00-\x1F\x7F-\x9F]/g, '') // Remove control characters
            .trim();
    }

    // XSS Protection
    preventXSS() {
        if (!this.securityConfig.preventXSS) return;

        // Prevent eval() usage
        const originalEval = window.eval;
        window.eval = function(code) {
            throw new Error('eval() is disabled for security reasons');
        };

        // Prevent dynamic script insertion
        const observer = new MutationObserver((mutations) => {
            mutations.forEach(mutation => {
                mutation.addedNodes.forEach(node => {
                    if (node.tagName === 'SCRIPT') {
                        this.checkScriptContent(node);
                    }
                });
            });
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    checkScriptContent(script) {
        const content = script.textContent || script.src;
        
        // Check for dangerous patterns
        const dangerousPatterns = [
            /eval\s*\(/,
            /Function\s*\(/,
            /setTimeout\s*\(/,
            /setInterval\s*\(/,
            /document\.write/,
            /innerHTML\s*=/,
            /outerHTML\s*=/
        ];

        const isDangerous = dangerousPatterns.some(pattern => pattern.test(content));
        
        if (isDangerous) {
            this.logSecurityEvent('DANGEROUS_SCRIPT_DETECTED', { content });
            script.remove();
        }
    }

    // Rate Limiting
    checkRateLimit(identifier = 'global') {
        const now = Date.now();
        const window = this.securityConfig.rateLimitWindow;
        const maxRequests = this.securityConfig.rateLimitMax;

        if (!this.rateLimiter.has(identifier)) {
            this.rateLimiter.set(identifier, []);
        }

        const requests = this.rateLimiter.get(identifier);
        
        // Remove old requests outside the window
        const validRequests = requests.filter(time => now - time < window);
        this.rateLimiter.set(identifier, validRequests);

        if (validRequests.length >= maxRequests) {
            this.logSecurityEvent('RATE_LIMIT_EXCEEDED', { identifier, count: validRequests.length });
            return false;
        }

        validRequests.push(now);
        return true;
    }

    // Security Headers
    generateSecurityHeaders() {
        return {
            'X-Content-Type-Options': 'nosniff',
            'X-Frame-Options': 'DENY',
            'X-XSS-Protection': '1; mode=block',
            'Referrer-Policy': 'strict-origin-when-cross-origin',
            'Content-Security-Policy': this.generateCSP(),
            'Permissions-Policy': this.generatePermissionsPolicy()
        };
    }

    generateCSP() {
        return [
            "default-src 'self'",
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.tailwindcss.com https://unpkg.com",
            "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
            "font-src 'self' https://fonts.gstatic.com",
            "img-src 'self' data: https:",
            "connect-src 'self' https://api.supabase.co",
            "frame-src 'none'",
            "object-src 'none'"
        ].join('; ');
    }

    generatePermissionsPolicy() {
        return [
            'camera=()',
            'microphone=()',
            'geolocation=()',
            'payment=()',
            'usb=()',
            'magnetometer=()',
            'gyroscope=()',
            'accelerometer=()'
        ].join(', ');
    }

    // Security Monitoring
    setupSecurityMonitoring() {
        // Monitor failed login attempts
        this.monitorFailedLogins();
        
        // Monitor suspicious activities
        this.monitorSuspiciousActivities();
        
        // Monitor network requests
        this.monitorNetworkRequests();
    }

    monitorFailedLogins() {
        let failedAttempts = 0;
        let lockoutTime = 0;

        window.addEventListener('security:login-failed', () => {
            failedAttempts++;
            
            if (failedAttempts >= 5) {
                lockoutTime = Date.now() + 15 * 60 * 1000; // 15 minutes
                this.logSecurityEvent('ACCOUNT_LOCKOUT', { failedAttempts });
                
                // Emit lockout event
                window.dispatchEvent(new CustomEvent('security:account-locked', {
                    detail: { lockoutTime }
                }));
            }
        });

        window.addEventListener('security:login-success', () => {
            failedAttempts = 0;
            lockoutTime = 0;
        });
    }

    monitorSuspiciousActivities() {
        // Monitor rapid form submissions
        let lastSubmissionTime = 0;
        
        document.addEventListener('submit', (event) => {
            const now = Date.now();
            
            if (now - lastSubmissionTime < 1000) { // Less than 1 second between submissions
                this.logSecurityEvent('RAPID_FORM_SUBMISSION', {
                    form: event.target.action,
                    interval: now - lastSubmissionTime
                });
            }
            
            lastSubmissionTime = now;
        });

        // Monitor suspicious input patterns
        document.addEventListener('input', (event) => {
            const value = event.target.value;
            const suspiciousPatterns = [
                /<script/i,
                /javascript:/i,
                /on\w+\s*=/i,
                /data:application\/javascript/i
            ];

            if (suspiciousPatterns.some(pattern => pattern.test(value))) {
                this.logSecurityEvent('SUSPICIOUS_INPUT', {
                    element: event.target.tagName,
                    value: value.substring(0, 100),
                    pattern: pattern.source
                });
            }
        });
    }

    monitorNetworkRequests() {
        const originalFetch = window.fetch;
        
        window.fetch = async function(url, options = {}) {
            // Log external requests
            if (typeof url === 'string' && !url.startsWith(window.location.origin)) {
                window.securityManager.logSecurityEvent('EXTERNAL_REQUEST', {
                    url,
                    method: options.method || 'GET'
                });
            }
            
            return originalFetch.apply(this, arguments);
        };
    }

    // Security Events
    logSecurityEvent(type, data = {}) {
        const event = {
            id: this.generateEventId(),
            type,
            timestamp: Date.now(),
            userAgent: navigator.userAgent,
            url: window.location.href,
            data
        };

        this.securityEvents.push(event);

        // Keep only recent events
        if (this.securityEvents.length > this.securityConfig.maxSecurityEvents) {
            this.securityEvents = this.securityEvents.slice(-this.securityConfig.maxSecurityEvents);
        }

        // Log to console in development
        if (this.securityConfig.logSecurityEvents && window.pathManager?.isDevelopment) {
            console.warn('Security Event:', event);
        }

        // Emit event for other components to handle
        window.dispatchEvent(new CustomEvent('security:event', {
            detail: event
        }));

        return event.id;
    }

    generateEventId() {
        return `sec_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    getSecurityEvents(type = null, limit = 50) {
        let events = this.securityEvents;
        
        if (type) {
            events = events.filter(event => event.type === type);
        }
        
        return events.slice(-limit);
    }

    clearSecurityEvents() {
        this.securityEvents = [];
    }

    // Validation methods
    validatePassword(password) {
        const minLength = 8;
        const hasUpperCase = /[A-Z]/.test(password);
        const hasLowerCase = /[a-z]/.test(password);
        const hasNumbers = /\d/.test(password);
        const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

        const issues = [];
        if (password.length < minLength) issues.push(`Must be at least ${minLength} characters`);
        if (!hasUpperCase) issues.push('Must contain uppercase letter');
        if (!hasLowerCase) issues.push('Must contain lowercase letter');
        if (!hasNumbers) issues.push('Must contain number');
        if (!hasSpecialChar) issues.push('Must contain special character');

        return {
            isValid: issues.length === 0,
            issues,
            score: this.calculatePasswordStrength(password)
        };
    }

    calculatePasswordStrength(password) {
        let strength = 0;
        
        // Length bonus
        strength += Math.min(password.length * 2, 20);
        
        // Character variety bonus
        strength += /[A-Z]/.test(password) ? 10 : 0;
        strength += /[a-z]/.test(password) ? 10 : 0;
        strength += /\d/.test(password) ? 10 : 0;
        strength += /[!@#$%^&*(),.?":{}|<>]/.test(password) ? 15 : 0;
        
        // Penalty for common patterns
        if (/^(.)\1+$/.test(password)) strength -= 30; // Repeated characters
        if (/123|abc|qwe/i.test(password)) strength -= 20; // Sequences
        
        return Math.max(0, Math.min(100, strength));
    }

    // Content Security
    validateContent(content, allowedTags = ['p', 'br', 'strong', 'em', 'u']) {
        const temp = document.createElement('div');
        temp.innerHTML = content;
        
        const elements = temp.querySelectorAll('*');
        let violations = [];
        
        elements.forEach(element => {
            if (!allowedTags.includes(element.tagName.toLowerCase())) {
                violations.push({
                    tag: element.tagName,
                    content: element.textContent.substring(0, 100)
                });
            }
        });
        
        return {
            isValid: violations.length === 0,
            violations,
            sanitized: this.sanitizeHTML(content)
        };
    }

    // Utility methods
    generateSecureToken(length = 32) {
        const array = new Uint8Array(length);
        crypto.getRandomValues(array);
        return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
    }

    hashData(data) {
        return crypto.subtle.digest('SHA-256', new TextEncoder().encode(data))
            .then(hash => Array.from(new Uint8Array(hash))
                .map(b => b.toString(16).padStart(2, '0'))
                .join(''));
    }

    // API Security
    secureAPIConfig() {
        return {
            headers: {
                'X-CSRF-Token': this.getCSRFToken(),
                'X-Requested-With': 'XMLHttpRequest',
                ...this.securityHeaders
            },
            credentials: 'same-origin',
            mode: 'cors'
        };
    }

    // Security status
    getSecurityStatus() {
        return {
            csrfEnabled: this.securityConfig.enableCSRF,
            csrfTokenPresent: !!this.getCSRFToken(),
            securityEventsCount: this.securityEvents.length,
            recentEvents: this.getSecurityEvents(null, 10),
            rateLimitStatus: Object.fromEntries(this.rateLimiter),
            onlineStatus: navigator.onLine
        };
    }

    // Event binding
    bindSecurityEvents() {
        // Prevent right-click in sensitive areas
        document.addEventListener('contextmenu', (event) => {
            if (event.target.closest('.secure-content')) {
                event.preventDefault();
                this.logSecurityEvent('RIGHT_CLICK_BLOCKED', {
                    element: event.target.tagName,
                    class: event.target.className
                });
            }
        });

        // Prevent text selection in sensitive areas
        document.addEventListener('selectstart', (event) => {
            if (event.target.closest('.secure-content')) {
                event.preventDefault();
                this.logSecurityEvent('TEXT_SELECTION_BLOCKED', {
                    element: event.target.tagName
                });
            }
        });

        // Prevent copy in sensitive areas
        document.addEventListener('copy', (event) => {
            if (event.target.closest('.secure-content')) {
                event.preventDefault();
                this.logSecurityEvent('COPY_BLOCKED', {
                    element: event.target.tagName
                });
            }
        });
    }
}

// Global security instance
window.securityManager = new SecurityManager();

// Auto-initialize security features
document.addEventListener('DOMContentLoaded', () => {
    window.securityManager.preventXSS();
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SecurityManager;
}