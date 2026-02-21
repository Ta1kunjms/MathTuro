/**
 * Advanced API Client - Comprehensive API communication with retry, queuing, and error handling
 * Provides robust API communication with advanced features for production use
 */

class ApiClient {
    constructor(options = {}) {
        this.baseURL = options.baseURL || window.pathManager?.getApiEndpoint('') || '/api';
        this.timeout = options.timeout || 10000;
        this.retryAttempts = options.retryAttempts || 3;
        this.retryDelay = options.retryDelay || 1000;
        this.enableQueue = options.enableQueue !== false;
        this.enableCache = options.enableCache !== false;
        
        this.queue = [];
        this.isProcessingQueue = false;
        this.cache = new Map();
        this.requestInterceptors = [];
        this.responseInterceptors = [];
        this.eventListeners = new Map();
        
        this.setupDefaultHeaders();
        this.setupEventListeners();
    }

    setupDefaultHeaders() {
        this.defaultHeaders = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
            'X-Client-Version': '1.0.0'
        };
    }

    setupEventListeners() {
        ['request', 'response', 'error', 'retry', 'queue'].forEach(event => {
            this.eventListeners.set(event, []);
        });
    }

    // Authentication management
    setAuthToken(token) {
        this.authToken = token;
        if (token) {
            this.defaultHeaders['Authorization'] = `Bearer ${token}`;
        } else {
            delete this.defaultHeaders['Authorization'];
        }
    }

    // Request interceptors
    addRequestInterceptor(interceptor) {
        this.requestInterceptors.push(interceptor);
    }

    // Response interceptors
    addResponseInterceptor(interceptor) {
        this.responseInterceptors.push(interceptor);
    }

    // Event system
    on(event, callback) {
        if (this.eventListeners.has(event)) {
            this.eventListeners.get(event).push(callback);
        }
    }

    emit(event, data) {
        if (this.eventListeners.has(event)) {
            this.eventListeners.get(event).forEach(callback => {
                try {
                    callback(data);
                } catch (error) {
                    console.error(`Event listener error for "${event}":`, error);
                }
            });
        }
    }

    // Core request method
    async request(method, endpoint, data = null, options = {}) {
        const config = {
            method: method.toUpperCase(),
            headers: { ...this.defaultHeaders, ...options.headers },
            timeout: options.timeout || this.timeout,
            cache: options.cache !== false && this.enableCache,
            retry: options.retry !== false,
            ...options
        };

        // Check cache for GET requests
        if (config.cache && method.toUpperCase() === 'GET') {
            const cached = this.getFromCache(endpoint, config);
            if (cached) {
                this.emit('response', { endpoint, data: cached, cached: true });
                return cached;
            }
        }

        // Apply request interceptors
        for (const interceptor of this.requestInterceptors) {
            const result = await interceptor(config);
            if (result) {
                Object.assign(config, result);
            }
        }

        const url = this.buildURL(endpoint);
        
        this.emit('request', { method: config.method, endpoint, url, config });

        let attempt = 0;
        let lastError;

        while (attempt < (config.retry ? this.retryAttempts : 1)) {
            try {
                const response = await this.executeRequest(url, config);
                const processedResponse = await this.processResponse(response, config);
                
                // Cache successful GET requests
                if (config.cache && method.toUpperCase() === 'GET') {
                    this.setCache(endpoint, processedResponse, config);
                }

                this.emit('response', { endpoint, data: processedResponse, cached: false });
                return processedResponse;

            } catch (error) {
                lastError = error;
                attempt++;

                if (config.retry && attempt < this.retryAttempts) {
                    this.emit('retry', { endpoint, attempt, error });
                    await this.delay(this.retryDelay * Math.pow(2, attempt - 1)); // Exponential backoff
                }
            }
        }

        this.emit('error', { endpoint, error: lastError, attempts: attempt });
        throw lastError;
    }

    buildURL(endpoint) {
        if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
            return endpoint;
        }
        
        const baseURL = this.baseURL.endsWith('/') ? this.baseURL.slice(0, -1) : this.baseURL;
        const cleanEndpoint = endpoint.startsWith('/') ? endpoint.slice(1) : endpoint;
        
        return `${baseURL}/${cleanEndpoint}`;
    }

    async executeRequest(url, config) {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), config.timeout);

        try {
            const response = await fetch(url, {
                ...config,
                signal: controller.signal,
                body: config.body ? JSON.stringify(config.body) : null
            });

            clearTimeout(timeoutId);

            if (!response.ok) {
                throw new ApiError(response.status, response.statusText, await response.text());
            }

            return response;

        } catch (error) {
            clearTimeout(timeoutId);
            
            if (error.name === 'AbortError') {
                throw new ApiError(408, 'Request Timeout', 'The request timed out');
            }
            
            throw error;
        }
    }

    async processResponse(response, config) {
        let data;
        const contentType = response.headers.get('content-type');

        if (contentType && contentType.includes('application/json')) {
            data = await response.json();
        } else {
            data = await response.text();
        }

        // Apply response interceptors
        for (const interceptor of this.responseInterceptors) {
            const result = await interceptor(data, response);
            if (result !== undefined) {
                data = result;
            }
        }

        return data;
    }

    // Cache management
    getCacheKey(endpoint, config) {
        return `${endpoint}:${JSON.stringify(config.params || {})}`;
    }

    getFromCache(endpoint, config) {
        const key = this.getCacheKey(endpoint, config);
        const cached = this.cache.get(key);
        
        if (cached && Date.now() < cached.expires) {
            return cached.data;
        }
        
        if (cached) {
            this.cache.delete(key);
        }
        
        return null;
    }

    setCache(endpoint, data, config, ttl = 300000) { // 5 minutes default
        const key = this.getCacheKey(endpoint, config);
        this.cache.set(key, {
            data,
            expires: Date.now() + ttl
        });
    }

    clearCache(endpoint = null) {
        if (endpoint) {
            this.cache.delete(endpoint);
        } else {
            this.cache.clear();
        }
    }

    // Request queue
    addToQueue(method, endpoint, data, options, resolve, reject) {
        this.queue.push({ method, endpoint, data, options, resolve, reject });
        this.emit('queue', { action: 'add', size: this.queue.length });
        
        if (!this.isProcessingQueue) {
            this.processQueue();
        }
    }

    async processQueue() {
        if (this.isProcessingQueue || this.queue.length === 0) {
            return;
        }

        this.isProcessingQueue = true;

        while (this.queue.length > 0) {
            const { method, endpoint, data, options, resolve, reject } = this.queue.shift();
            
            try {
                const result = await this.request(method, endpoint, data, options);
                resolve(result);
            } catch (error) {
                reject(error);
            }
        }

        this.isProcessingQueue = false;
        this.emit('queue', { action: 'processed', size: this.queue.length });
    }

    // Convenience methods
    async get(endpoint, params = null, options = {}) {
        if (params) {
            const url = new URL(endpoint, this.baseURL);
            Object.keys(params).forEach(key => {
                url.searchParams.append(key, params[key]);
            });
            endpoint = url.pathname + url.search;
        }
        
        if (this.enableQueue && options.queue) {
            return new Promise((resolve, reject) => {
                this.addToQueue('GET', endpoint, null, options, resolve, reject);
            });
        }
        
        return this.request('GET', endpoint, null, options);
    }

    async post(endpoint, data = null, options = {}) {
        const config = { ...options, body: data };
        
        if (this.enableQueue && options.queue) {
            return new Promise((resolve, reject) => {
                this.addToQueue('POST', endpoint, data, config, resolve, reject);
            });
        }
        
        return this.request('POST', endpoint, data, config);
    }

    async put(endpoint, data = null, options = {}) {
        const config = { ...options, body: data };
        
        if (this.enableQueue && options.queue) {
            return new Promise((resolve, reject) => {
                this.addToQueue('PUT', endpoint, data, config, resolve, reject);
            });
        }
        
        return this.request('PUT', endpoint, data, config);
    }

    async patch(endpoint, data = null, options = {}) {
        const config = { ...options, body: data };
        
        if (this.enableQueue && options.queue) {
            return new Promise((resolve, reject) => {
                this.addToQueue('PATCH', endpoint, data, config, resolve, reject);
            });
        }
        
        return this.request('PATCH', endpoint, data, config);
    }

    async delete(endpoint, options = {}) {
        if (this.enableQueue && options.queue) {
            return new Promise((resolve, reject) => {
                this.addToQueue('DELETE', endpoint, null, options, resolve, reject);
            });
        }
        
        return this.request('DELETE', endpoint, null, options);
    }

    // File upload
    async upload(endpoint, file, options = {}) {
        const formData = new FormData();
        
        if (file instanceof File) {
            formData.append('file', file);
        } else if (typeof file === 'object') {
            Object.keys(file).forEach(key => {
                formData.append(key, file[key]);
            });
        } else {
            throw new Error('Invalid file data provided');
        }

        const config = {
            ...options,
            headers: {
                ...this.defaultHeaders,
                ...options.headers,
                'Content-Type': 'multipart/form-data'
            },
            body: formData,
            timeout: options.timeout || 30000 // Longer timeout for uploads
        };

        // Remove Content-Type header to let browser set it with boundary
        delete config.headers['Content-Type'];

        return this.request('POST', endpoint, null, config);
    }

    // Batch requests
    async batch(requests) {
        const batchId = this.generateBatchId();
        const batchEndpoint = `/batch/${batchId}`;
        
        return this.post(batchEndpoint, { requests });
    }

    generateBatchId() {
        return `batch_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    // Utility methods
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    isOnline() {
        return navigator.onLine;
    }

    // Status and health checks
    async healthCheck() {
        try {
            const response = await this.get('/health', null, { timeout: 5000 });
            return { status: 'healthy', data: response };
        } catch (error) {
            return { status: 'unhealthy', error: error.message };
        }
    }

    async getStatus() {
        return {
            queueSize: this.queue.length,
            cacheSize: this.cache.size,
            isOnline: this.isOnline(),
            baseURL: this.baseURL
        };
    }
}

// Custom error class
class ApiError extends Error {
    constructor(status, message, details = null) {
        super(message);
        this.name = 'ApiError';
        this.status = status;
        this.details = details;
    }

    isClientError() {
        return this.status >= 400 && this.status < 500;
    }

    isServerError() {
        return this.status >= 500;
    }

    isNetworkError() {
        return this.status === 0 || this.status === 408;
    }
}

// Global instance with default configuration
window.apiClient = new ApiClient({
    baseURL: window.pathManager?.getApiEndpoint(''),
    timeout: 10000,
    retryAttempts: 3,
    enableQueue: true,
    enableCache: true
});

// Auto-setup auth token from localStorage
const authToken = localStorage.getItem('authToken');
if (authToken) {
    window.apiClient.setAuthToken(authToken);
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { ApiClient, ApiError };
}