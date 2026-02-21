/**
 * Performance Manager - Resource Monitoring, Lazy Loading, and Performance Optimization
 * Comprehensive performance management system for web applications
 */

class PerformanceManager {
    constructor() {
        this.config = this.initializeConfig();
        this.metrics = new Map();
        this.observers = new Map();
        this.resourceQueue = [];
        this.isProcessingQueue = false;
        
        this.initializePerformanceMonitoring();
        this.setupLazyLoading();
        this.initializeResourceOptimization();
        this.bindPerformanceEvents();
    }

    initializeConfig() {
        return {
            enableMetrics: true,
            enableLazyLoading: true,
            enableResourceOptimization: true,
            maxResourceSize: 5 * 1024 * 1024, // 5MB
            maxConcurrentRequests: 6,
            lazyLoadingThreshold: 200, // pixels
            performanceCheckInterval: 5000, // 5 seconds
            enableServiceWorker: true,
            enableCaching: true,
            enableCompression: true
        };
    }

    // Performance Monitoring
    initializePerformanceMonitoring() {
        if (!this.config.enableMetrics) return;

        // Monitor page load
        this.measurePageLoad();
        
        // Monitor resource loading
        this.monitorResourceLoading();
        
        // Monitor user interactions
        this.monitorUserInteractions();
        
        // Monitor memory usage
        this.monitorMemoryUsage();
        
        // Start periodic performance checks
        this.startPeriodicChecks();
    }

    measurePageLoad() {
        window.addEventListener('load', () => {
            const navigation = performance.getEntriesByType('navigation')[0];
            
            const metrics = {
                domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
                loadComplete: navigation.loadEventEnd - navigation.loadEventStart,
                firstPaint: this.getFirstPaint(),
                firstContentfulPaint: this.getFirstContentfulPaint(),
                totalLoadTime: navigation.loadEventEnd - navigation.fetchStart,
                dnsLookup: navigation.domainLookupEnd - navigation.domainLookupStart,
                tcpConnection: navigation.connectEnd - navigation.connectStart,
                serverResponse: navigation.responseEnd - navigation.requestStart
            };

            this.recordMetric('pageLoad', metrics);
            
            // Emit performance event
            window.dispatchEvent(new CustomEvent('performance:page-load', {
                detail: metrics
            }));
        });
    }

    getFirstPaint() {
        const paintEntries = performance.getEntriesByType('paint');
        const firstPaint = paintEntries.find(entry => entry.name === 'first-paint');
        return firstPaint ? firstPaint.startTime : 0;
    }

    getFirstContentfulPaint() {
        const paintEntries = performance.getEntriesByType('paint');
        const fcp = paintEntries.find(entry => entry.name === 'first-contentful-paint');
        return fcp ? fcp.startTime : 0;
    }

    monitorResourceLoading() {
        const observer = new PerformanceObserver((list) => {
            list.getEntries().forEach(entry => {
                if (entry.entryType === 'resource') {
                    this.recordMetric('resource', {
                        name: entry.name,
                        type: this.getResourceType(entry.name),
                        duration: entry.duration,
                        size: entry.transferSize || 0,
                        cached: entry.transferSize === 0 && entry.decodedBodySize > 0
                    });

                    // Check for large resources
                    if (entry.transferSize > this.config.maxResourceSize) {
                        this.warnLargeResource(entry);
                    }
                }
            });
        });

        observer.observe({ entryTypes: ['resource'] });
        this.observers.set('resource', observer);
    }

    getResourceType(url) {
        const extension = url.split('.').pop()?.toLowerCase();
        const typeMap = {
            'js': 'javascript',
            'css': 'stylesheet',
            'png': 'image',
            'jpg': 'image',
            'jpeg': 'image',
            'gif': 'image',
            'svg': 'image',
            'woff': 'font',
            'woff2': 'font',
            'ttf': 'font',
            'eot': 'font'
        };
        return typeMap[extension] || 'other';
    }

    warnLargeResource(entry) {
        console.warn(`Large resource detected: ${entry.name} (${(entry.transferSize / 1024 / 1024).toFixed(2)}MB)`);
        
        window.dispatchEvent(new CustomEvent('performance:large-resource', {
            detail: {
                name: entry.name,
                size: entry.transferSize,
                type: this.getResourceType(entry.name)
            }
        }));
    }

    monitorUserInteractions() {
        let lastInteractionTime = 0;
        
        ['click', 'scroll', 'keydown', 'touchstart'].forEach(eventType => {
            document.addEventListener(eventType, (event) => {
                const now = performance.now();
                const responseTime = now - lastInteractionTime;
                
                if (lastInteractionTime > 0) {
                    this.recordMetric('interaction', {
                        type: eventType,
                        responseTime,
                        target: event.target.tagName
                    });
                }
                
                lastInteractionTime = now;
            });
        });
    }

    monitorMemoryUsage() {
        if ('memory' in performance) {
            setInterval(() => {
                const memory = performance.memory;
                this.recordMetric('memory', {
                    used: memory.usedJSHeapSize,
                    total: memory.totalJSHeapSize,
                    limit: memory.jsHeapSizeLimit,
                    usage: (memory.usedJSHeapSize / memory.jsHeapSizeLimit) * 100
                });

                // Warn about high memory usage
                if (memory.usedJSHeapSize / memory.jsHeapSizeLimit > 0.8) {
                    console.warn('High memory usage detected:', {
                        used: `${(memory.usedJSHeapSize / 1024 / 1024).toFixed(2)}MB`,
                        limit: `${(memory.jsHeapSizeLimit / 1024 / 1024).toFixed(2)}MB`
                    });
                }
            }, 30000); // Check every 30 seconds
        }
    }

    startPeriodicChecks() {
        setInterval(() => {
            this.checkPerformanceHealth();
        }, this.config.performanceCheckInterval);
    }

    checkPerformanceHealth() {
        const metrics = this.getPerformanceMetrics();
        
        // Check for performance issues
        const issues = [];
        
        if (metrics.pageLoad?.totalLoadTime > 3000) {
            issues.push('Slow page load time');
        }
        
        if (metrics.memory?.usage > 80) {
            issues.push('High memory usage');
        }
        
        if (metrics.interaction?.responseTime > 100) {
            issues.push('Slow interaction response');
        }
        
        if (issues.length > 0) {
            window.dispatchEvent(new CustomEvent('performance:issues-detected', {
                detail: { issues, metrics }
            }));
        }
    }

    // Lazy Loading
    setupLazyLoading() {
        if (!this.config.enableLazyLoading) return;

        // Setup Intersection Observer for images
        const imageObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    this.loadImage(entry.target);
                    imageObserver.unobserve(entry.target);
                }
            });
        }, {
            rootMargin: `${this.config.lazyLoadingThreshold}px`
        });

        // Observe all images with data-src
        document.querySelectorAll('img[data-src]').forEach(img => {
            imageObserver.observe(img);
        });

        this.observers.set('image', imageObserver);

        // Setup lazy loading for components
        this.setupComponentLazyLoading();
    }

    loadImage(img) {
        const src = img.dataset.src;
        if (!src) return;

        img.src = src;
        img.classList.add('loaded');
        
        // Load complete handler
        img.onload = () => {
            img.classList.add('fully-loaded');
            this.recordMetric('imageLoad', {
                src: src,
                loadTime: performance.now()
            });
        };
    }

    setupComponentLazyLoading() {
        const componentObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    this.loadComponent(entry.target);
                    componentObserver.unobserve(entry.target);
                }
            });
        }, {
            rootMargin: `${this.config.lazyLoadingThreshold}px`
        });

        // Observe components with data-component
        document.querySelectorAll('[data-component]').forEach(component => {
            componentObserver.observe(component);
        });

        this.observers.set('component', componentObserver);
    }

    async loadComponent(element) {
        const componentName = element.dataset.component;
        
        try {
            this.recordMetric('componentLoad', {
                name: componentName,
                startTime: performance.now()
            });

            // Dynamically load component
            await this.dynamicImport(componentName, element);
            
            this.recordMetric('componentLoad', {
                name: componentName,
                loadTime: performance.now()
            });

        } catch (error) {
            console.error(`Failed to load component ${componentName}:`, error);
            element.classList.add('component-error');
        }
    }

    async dynamicImport(componentName, element) {
        // This would be implemented based on your component system
        // For now, just emit an event
        window.dispatchEvent(new CustomEvent('component:load', {
            detail: { componentName, element }
        }));
    }

    // Resource Optimization
    initializeResourceOptimization() {
        if (!this.config.enableResourceOptimization) return;

        this.optimizeImageLoading();
        this.optimizeScriptLoading();
        this.optimizeStyleLoading();
        this.setupServiceWorker();
    }

    optimizeImageLoading() {
        // Add loading="lazy" to all images without it
        document.querySelectorAll('img:not([loading])').forEach(img => {
            img.loading = 'lazy';
        });

        // Convert images to WebP if supported
        if (this.supportsWebP()) {
            this.convertToWebP();
        }
    }

    supportsWebP() {
        const canvas = document.createElement('canvas');
        return canvas.toDataURL('image/webp').indexOf('data:image/webp') === 0;
    }

    convertToWebP() {
        document.querySelectorAll('img[data-webp]').forEach(img => {
            const webpSrc = img.dataset.webp;
            if (webpSrc) {
                img.src = webpSrc;
            }
        });
    }

    optimizeScriptLoading() {
        // Add defer to scripts without async or defer
        document.querySelectorAll('script:not([async]):not([defer])').forEach(script => {
            if (!script.src.includes('critical')) {
                script.defer = true;
            }
        });
    }

    optimizeStyleLoading() {
        // Preload critical CSS
        const criticalCSS = document.querySelectorAll('link[rel="stylesheet"][data-critical]');
        criticalCSS.forEach(link => {
            const preload = document.createElement('link');
            preload.rel = 'preload';
            preload.as = 'style';
            preload.href = link.href;
            link.parentNode.insertBefore(preload, link);
        });
    }

    setupServiceWorker() {
        if (!this.config.enableServiceWorker || !('serviceWorker' in navigator)) {
            return;
        }

        navigator.serviceWorker.register('/sw.js')
            .then(registration => {
                console.log('Service Worker registered:', registration);
                this.recordMetric('serviceWorker', { status: 'registered' });
            })
            .catch(error => {
                console.error('Service Worker registration failed:', error);
                this.recordMetric('serviceWorker', { status: 'failed', error });
            });
    }

    // Metrics Collection
    recordMetric(type, data) {
        if (!this.config.enableMetrics) return;

        const timestamp = Date.now();
        
        if (!this.metrics.has(type)) {
            this.metrics.set(type, []);
        }

        this.metrics.get(type).push({
            timestamp,
            ...data
        });

        // Keep only recent metrics (last 100 entries)
        const typeMetrics = this.metrics.get(type);
        if (typeMetrics.length > 100) {
            this.metrics.set(type, typeMetrics.slice(-100));
        }

        // Emit metric event
        window.dispatchEvent(new CustomEvent('performance:metric', {
            detail: { type, data, timestamp }
        }));
    }

    getMetrics(type = null, limit = 50) {
        if (type) {
            return this.metrics.get(type) || [];
        }
        
        const allMetrics = {};
        this.metrics.forEach((values, key) => {
            allMetrics[key] = values.slice(-limit);
        });
        return allMetrics;
    }

    getPerformanceMetrics() {
        const metrics = {};
        
        this.metrics.forEach((values, type) => {
            if (values.length > 0) {
                const latest = values[values.length - 1];
                metrics[type] = latest;
            }
        });

        return metrics;
    }

    // Resource Management
    preloadResources(resources) {
        resources.forEach(resource => {
            const link = document.createElement('link');
            link.rel = 'preload';
            link.href = resource.url;
            link.as = resource.type || 'script';
            
            if (resource.type === 'image' && resource.media) {
                link.media = resource.media;
            }
            
            document.head.appendChild(link);
        });
    }

    prefetchResources(resources) {
        resources.forEach(resource => {
            const link = document.createElement('link');
            link.rel = 'prefetch';
            link.href = resource.url;
            document.head.appendChild(link);
        });
    }

    // Performance Optimization
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    throttle(func, limit) {
        let inThrottle;
        return function() {
            const args = arguments;
            const context = this;
            if (!inThrottle) {
                func.apply(context, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    }

    // Memory Management
    cleanup() {
        // Clear observers
        this.observers.forEach(observer => observer.disconnect());
        this.observers.clear();
        
        // Clear metrics
        this.metrics.clear();
        
        // Clear resource queue
        this.resourceQueue = [];
    }

    // Performance Recommendations
    getPerformanceRecommendations() {
        const metrics = this.getPerformanceMetrics();
        const recommendations = [];

        // Page load recommendations
        if (metrics.pageLoad?.totalLoadTime > 3000) {
            recommendations.push({
                type: 'page-load',
                severity: 'high',
                message: 'Page load time is slow. Consider optimizing resources.',
                details: `Current: ${metrics.pageLoad.totalLoadTime}ms`
            });
        }

        // Memory recommendations
        if (metrics.memory?.usage > 80) {
            recommendations.push({
                type: 'memory',
                severity: 'medium',
                message: 'High memory usage detected. Consider memory cleanup.',
                details: `Current: ${metrics.memory.usage.toFixed(2)}%`
            });
        }

        // Resource recommendations
        const resources = this.getMetrics('resource');
        const slowResources = resources.filter(r => r.duration > 1000);
        if (slowResources.length > 0) {
            recommendations.push({
                type: 'resources',
                severity: 'medium',
                message: `${slowResources.length} slow resources detected.`,
                details: slowResources.map(r => `${r.name}: ${r.duration}ms`)
            });
        }

        return recommendations;
    }

    // Event binding
    bindPerformanceEvents() {
        // Monitor visibility changes
        document.addEventListener('visibilitychange', () => {
            this.recordMetric('visibility', {
                hidden: document.hidden,
                timestamp: performance.now()
            });
        });

        // Monitor online/offline status
        window.addEventListener('online', () => {
            this.recordMetric('connection', { status: 'online' });
        });

        window.addEventListener('offline', () => {
            this.recordMetric('connection', { status: 'offline' });
        });
    }

    // Performance Scores
    calculatePerformanceScore() {
        const metrics = this.getPerformanceMetrics();
        let score = 100;

        // Deduct points for poor metrics
        if (metrics.pageLoad?.totalLoadTime > 3000) score -= 20;
        if (metrics.memory?.usage > 80) score -= 15;
        if (metrics.interaction?.responseTime > 100) score -= 10;

        // Bonus points for good metrics
        if (metrics.pageLoad?.totalLoadTime < 1500) score += 10;
        if (metrics.memory?.usage < 50) score += 10;

        return Math.max(0, Math.min(100, score));
    }

    getPerformanceGrade() {
        const score = this.calculatePerformanceScore();
        
        if (score >= 90) return 'A';
        if (score >= 80) return 'B';
        if (score >= 70) return 'C';
        if (score >= 60) return 'D';
        return 'F';
    }
}

// Global performance manager instance
window.performanceManager = new PerformanceManager();

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    // Additional initialization can go here
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PerformanceManager;
}