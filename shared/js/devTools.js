/**
 * Development Tools - Advanced Development Dashboard
 * Comprehensive debugging and development utilities
 */

class DevTools {
    constructor() {
        this.config = this.initializeConfig();
        this.metrics = new Map();
        this.logs = [];
        this.panels = new Map();
        this.isEnabled = false;
        this.shortcutKey = 'Ctrl+Shift+D';
        
        this.initializeDevTools();
        this.setupKeyboardShortcut();
        this.bindDevToolsEvents();
    }

    initializeConfig() {
        return {
            enableInProduction: false,
            maxLogEntries: 1000,
            updateInterval: 1000,
            enableComponentInspector: true,
            enableNetworkMonitor: true,
            enablePerformanceMonitor: true,
            enableStateInspector: true
        };
    }

    initializeDevTools() {
        // Check if dev tools should be enabled
        if (!this.shouldEnable()) return;
        
        this.isEnabled = true;
        this.createDevToolsUI();
        this.initializePanels();
        this.startMetricsCollection();
    }

    shouldEnable() {
        if (this.config.enableInProduction) return true;
        
        // Enable in development
        if (window.pathManager?.isDevelopment) return true;
        
        // Enable via localStorage
        return localStorage.getItem('devToolsEnabled') === 'true';
    }

    createDevToolsUI() {
        if (document.getElementById('dev-tools')) return;
        
        const devTools = document.createElement('div');
        devTools.id = 'dev-tools';
        devTools.innerHTML = `
            <div class="dev-tools-container">
                <div class="dev-tools-header">
                    <div class="dev-tools-title">MathTuro DevTools</div>
                    <div class="dev-tools-controls">
                        <button class="dev-tools-btn dev-tools-minimize" title="Minimize">−</button>
                        <button class="dev-tools-btn dev-tools-close" title="Close">×</button>
                    </div>
                </div>
                <div class="dev-tools-tabs">
                    <button class="dev-tools-tab active" data-panel="dashboard">Dashboard</button>
                    <button class="dev-tools-tab" data-panel="console">Console</button>
                    <button class="dev-tools-tab" data-panel="network">Network</button>
                    <button class="dev-tools-tab" data-panel="performance">Performance</button>
                    <button class="dev-tools-tab" data-panel="components">Components</button>
                    <button class="dev-tools-tab" data-panel="storage">Storage</button>
                    <button class="dev-tools-tab" data-panel="auth">Auth</button>
                </div>
                <div class="dev-tools-panels">
                    <div id="dev-dashboard" class="dev-tools-panel active"></div>
                    <div id="dev-console" class="dev-tools-panel"></div>
                    <div id="dev-network" class="dev-tools-panel"></div>
                    <div id="dev-performance" class="dev-tools-panel"></div>
                    <div id="dev-components" class="dev-tools-panel"></div>
                    <div id="dev-storage" class="dev-tools-panel"></div>
                    <div id="dev-auth" class="dev-tools-panel"></div>
                </div>
            </div>
            <div class="dev-tools-toggle" title="Toggle DevTools (Ctrl+Shift+D)">🔧</div>
        `;
        
        document.body.appendChild(devTools);
        this.setupDevToolsEvents();
    }

    setupDevToolsEvents() {
        const devTools = document.getElementById('dev-tools');
        const toggle = devTools.querySelector('.dev-tools-toggle');
        const minimize = devTools.querySelector('.dev-tools-minimize');
        const closeBtn = devTools.querySelector('.dev-tools-close');
        const tabs = devTools.querySelectorAll('.dev-tools-tab');
        
        toggle.addEventListener('click', () => this.toggleDevTools());
        
        minimize.addEventListener('click', () => {
            devTools.classList.toggle('minimized');
        });
        
        closeBtn.addEventListener('click', () => {
            this.hideDevTools();
        });
        
        tabs.forEach(tab => {
            tab.addEventListener('click', () => {
                this.switchPanel(tab.dataset.panel);
            });
        });
    }

    initializePanels() {
        this.initializeDashboard();
        this.initializeConsole();
        this.initializeNetwork();
        this.initializePerformance();
        this.initializeComponents();
        this.initializeStorage();
        this.initializeAuth();
    }

    initializeDashboard() {
        const panel = document.getElementById('dev-dashboard');
        panel.innerHTML = `
            <div class="dev-dashboard-grid">
                <div class="dev-card">
                    <h3>Application Info</h3>
                    <div id="app-info"></div>
                </div>
                <div class="dev-card">
                    <h3>Performance Metrics</h3>
                    <div id="perf-metrics"></div>
                </div>
                <div class="dev-card">
                    <h3>Error Summary</h3>
                    <div id="error-summary"></div>
                </div>
                <div class="dev-card">
                    <h3>Quick Actions</h3>
                    <div id="quick-actions"></div>
                </div>
            </div>
        `;
        
        this.updateDashboard();
    }

    initializeConsole() {
        const panel = document.getElementById('dev-console');
        panel.innerHTML = `
            <div class="dev-console-header">
                <select id="log-level-filter">
                    <option value="all">All Levels</option>
                    <option value="error">Errors</option>
                    <option value="warn">Warnings</option>
                    <option value="info">Info</option>
                    <option value="debug">Debug</option>
                </select>
                <button class="dev-btn" onclick="devTools.clearConsole()">Clear</button>
                <button class="dev-btn" onclick="devTools.exportLogs()">Export</button>
            </div>
            <div class="dev-console-output" id="console-output"></div>
            <div class="dev-console-input">
                <input type="text" id="console-command" placeholder="Enter JavaScript command...">
                <button onclick="devTools.executeCommand()">Run</button>
            </div>
        `;
    }

    initializeNetwork() {
        const panel = document.getElementById('dev-network');
        panel.innerHTML = `
            <div class="dev-network-header">
                <button class="dev-btn" onclick="devTools.clearNetwork()">Clear</button>
                <button class="dev-btn" onclick="devTools.exportNetwork()">Export</button>
                <label>
                    <input type="checkbox" id="network-realtime"> Real-time
                </label>
            </div>
            <div class="dev-network-table">
                <table>
                    <thead>
                        <tr>
                            <th>Method</th>
                            <th>URL</th>
                            <th>Status</th>
                            <th>Time</th>
                            <th>Size</th>
                        </tr>
                    </thead>
                    <tbody id="network-requests"></tbody>
                </table>
            </div>
        `;
        
        this.setupNetworkMonitoring();
    }

    initializePerformance() {
        const panel = document.getElementById('dev-performance');
        panel.innerHTML = `
            <div class="dev-performance-header">
                <button class="dev-btn" onclick="devTools.runPerformanceTest()">Run Test</button>
                <button class="dev-btn" onclick="devTools.clearPerformance()">Clear</button>
            </div>
            <div class="dev-performance-content">
                <div class="dev-card">
                    <h4>Page Load Metrics</h4>
                    <div id="page-load-metrics"></div>
                </div>
                <div class="dev-card">
                    <h4>Resource Timing</h4>
                    <div id="resource-timing"></div>
                </div>
                <div class="dev-card">
                    <h4>Memory Usage</h4>
                    <div id="memory-usage"></div>
                </div>
            </div>
        `;
    }

    initializeComponents() {
        const panel = document.getElementById('dev-components');
        panel.innerHTML = `
            <div class="dev-components-header">
                <input type="text" id="component-search" placeholder="Search components...">
                <button class="dev-btn" onclick="devTools.refreshComponents()">Refresh</button>
            </div>
            <div class="dev-components-tree" id="components-tree"></div>
            <div class="dev-component-details" id="component-details"></div>
        `;
        
        this.setupComponentInspector();
    }

    initializeStorage() {
        const panel = document.getElementById('dev-storage');
        panel.innerHTML = `
            <div class="dev-storage-tabs">
                <button class="dev-storage-tab active" data-storage="localStorage">Local Storage</button>
                <button class="dev-storage-tab" data-storage="sessionStorage">Session Storage</button>
                <button class="dev-storage-tab" data-storage="cookies">Cookies</button>
            </div>
            <div class="dev-storage-content">
                <div class="dev-storage-controls">
                    <input type="text" id="storage-key" placeholder="Key">
                    <input type="text" id="storage-value" placeholder="Value">
                    <button onclick="devTools.setStorageItem()">Set</button>
                    <button onclick="devTools.clearStorage()">Clear All</button>
                </div>
                <div class="dev-storage-list" id="storage-list"></div>
            </div>
        `;
        
        this.setupStorageInspector();
    }

    initializeAuth() {
        const panel = document.getElementById('dev-auth');
        panel.innerHTML = `
            <div class="dev-auth-content">
                <div class="dev-card">
                    <h4>Current User</h4>
                    <div id="current-user"></div>
                </div>
                <div class="dev-card">
                    <h4>Auth Token</h4>
                    <div id="auth-token"></div>
                </div>
                <div class="dev-card">
                    <h4>Auth Actions</h4>
                    <div id="auth-actions"></div>
                </div>
            </div>
        `;
        
        this.updateAuthPanel();
    }

    // Dashboard Updates
    updateDashboard() {
        this.updateAppInfo();
        this.updatePerformanceMetrics();
        this.updateErrorSummary();
        this.updateQuickActions();
    }

    updateAppInfo() {
        const container = document.getElementById('app-info');
        container.innerHTML = `
            <div class="dev-info-row">
                <span class="dev-label">URL:</span>
                <span class="dev-value">${window.location.href}</span>
            </div>
            <div class="dev-info-row">
                <span class="dev-label">User Agent:</span>
                <span class="dev-value">${navigator.userAgent}</span>
            </div>
            <div class="dev-info-row">
                <span class="dev-label">Environment:</span>
                <span class="dev-value">${window.pathManager?.isDevelopment ? 'Development' : 'Production'}</span>
            </div>
            <div class="dev-info-row">
                <span class="dev-label">Viewport:</span>
                <span class="dev-value">${window.innerWidth}x${window.innerHeight}</span>
            </div>
        `;
    }

    updatePerformanceMetrics() {
        const container = document.getElementById('perf-metrics');
        
        if (window.performanceManager) {
            const score = window.performanceManager.calculatePerformanceScore();
            const grade = window.performanceManager.getPerformanceGrade();
            
            container.innerHTML = `
                <div class="dev-metric">
                    <span class="dev-label">Performance Score:</span>
                    <span class="dev-value score-${grade.toLowerCase()}">${score} (${grade})</span>
                </div>
                <div class="dev-metric">
                    <span class="dev-label">Memory Usage:</span>
                    <span class="dev-value">${this.getMemoryUsage()}</span>
                </div>
                <div class="dev-metric">
                    <span class="dev-label">Active Components:</span>
                    <span class="dev-value">${this.countActiveComponents()}</span>
                </div>
            `;
        } else {
            container.innerHTML = '<span class="dev-value">Performance Manager not available</span>';
        }
    }

    updateErrorSummary() {
        const container = document.getElementById('error-summary');
        
        if (window.errorHandler) {
            const analytics = window.errorHandler.getErrorAnalytics();
            container.innerHTML = `
                <div class="dev-metric">
                    <span class="dev-label">Total Errors:</span>
                    <span class="dev-value">${analytics.totalErrors}</span>
                </div>
                <div class="dev-metric">
                    <span class="dev-label">Critical:</span>
                    <span class="dev-value error">${analytics.criticalErrors}</span>
                </div>
                <div class="dev-metric">
                    <span class="dev-label">Error Rate:</span>
                    <span class="dev-value">${analytics.errorRate.toFixed(2)}/min</span>
                </div>
            `;
        } else {
            container.innerHTML = '<span class="dev-value">Error Handler not available</span>';
        }
    }

    updateQuickActions() {
        const container = document.getElementById('quick-actions');
        container.innerHTML = `
            <div class="dev-quick-actions">
                <button class="dev-btn" onclick="devTools.reloadPage()">Reload Page</button>
                <button class="dev-btn" onclick="devTools.clearCache()">Clear Cache</button>
                <button class="dev-btn" onclick="devTools.runDiagnostics()">Run Diagnostics</button>
                <button class="dev-btn" onclick="devTools.exportData()">Export Data</button>
            </div>
        `;
    }

    // Console Functions
    log(level, message, data = null) {
        if (!this.isEnabled) return;
        
        const entry = {
            timestamp: Date.now(),
            level,
            message,
            data,
            id: this.generateId()
        };
        
        this.logs.push(entry);
        
        if (this.logs.length > this.config.maxLogEntries) {
            this.logs = this.logs.slice(-this.config.maxLogEntries);
        }
        
        this.updateConsole();
    }

    updateConsole() {
        const output = document.getElementById('console-output');
        const filter = document.getElementById('log-level-filter')?.value || 'all';
        
        const filteredLogs = filter === 'all' ? 
            this.logs : 
            this.logs.filter(log => log.level === filter);
        
        output.innerHTML = filteredLogs.map(log => `
            <div class="dev-console-entry dev-${log.level}">
                <span class="dev-timestamp">${new Date(log.timestamp).toLocaleTimeString()}</span>
                <span class="dev-level">[${log.level.toUpperCase()}]</span>
                <span class="dev-message">${log.message}</span>
                ${log.data ? `<pre class="dev-data">${JSON.stringify(log.data, null, 2)}</pre>` : ''}
            </div>
        `).join('');
        
        output.scrollTop = output.scrollHeight;
    }

    executeCommand() {
        const input = document.getElementById('console-command');
        const command = input.value.trim();
        
        if (!command) return;
        
        try {
            const result = eval(command);
            this.log('info', `> ${command}`, result);
        } catch (error) {
            this.log('error', `> ${command}`, error.message);
        }
        
        input.value = '';
    }

    clearConsole() {
        this.logs = [];
        this.updateConsole();
    }

    // Network Monitoring
    setupNetworkMonitoring() {
        if (!this.config.enableNetworkMonitor) return;
        
        // Override fetch to monitor requests
        const originalFetch = window.fetch;
        window.fetch = async (...args) => {
            const startTime = performance.now();
            const url = args[0];
            const options = args[1] || {};
            
            try {
                const response = await originalFetch(...args);
                const endTime = performance.now();
                
                this.logNetworkRequest({
                    method: options.method || 'GET',
                    url: typeof url === 'string' ? url : url.url,
                    status: response.status,
                    duration: endTime - startTime,
                    size: response.headers.get('content-length') || 0,
                    success: response.ok
                });
                
                return response;
            } catch (error) {
                const endTime = performance.now();
                
                this.logNetworkRequest({
                    method: options.method || 'GET',
                    url: typeof url === 'string' ? url : url.url,
                    status: 0,
                    duration: endTime - startTime,
                    size: 0,
                    success: false,
                    error: error.message
                });
                
                throw error;
            }
        };
    }

    logNetworkRequest(request) {
        const tbody = document.getElementById('network-requests');
        if (!tbody) return;
        
        const row = document.createElement('tr');
        row.className = request.success ? 'dev-network-success' : 'dev-network-error';
        row.innerHTML = `
            <td>${request.method}</td>
            <td class="dev-url">${request.url}</td>
            <td>${request.status}</td>
            <td>${request.duration.toFixed(2)}ms</td>
            <td>${this.formatSize(request.size)}</td>
        `;
        
        tbody.insertBefore(row, tbody.firstChild);
        
        // Limit number of entries
        while (tbody.children.length > 100) {
            tbody.removeChild(tbody.lastChild);
        }
    }

    // Component Inspector
    setupComponentInspector() {
        if (!this.config.enableComponentInspector) return;
        
        document.addEventListener('mouseover', (event) => {
            if (event.shiftKey) {
                this.inspectElement(event.target);
            }
        });
        
        this.refreshComponents();
    }

    inspectElement(element) {
        const details = document.getElementById('component-details');
        if (!details) return;
        
        details.innerHTML = `
            <div class="dev-component-info">
                <h4>${element.tagName.toLowerCase()}</h4>
                <div class="dev-info-row">
                    <span class="dev-label">ID:</span>
                    <span class="dev-value">${element.id || 'none'}</span>
                </div>
                <div class="dev-info-row">
                    <span class="dev-label">Classes:</span>
                    <span class="dev-value">${element.className || 'none'}</span>
                </div>
                <div class="dev-info-row">
                    <span class="dev-label">Component:</span>
                    <span class="dev-value">${element.dataset.component || 'none'}</span>
                </div>
                <div class="dev-info-row">
                    <span class="dev-label">Event Listeners:</span>
                    <span class="dev-value">${this.getEventListenersCount(element)}</span>
                </div>
            </div>
        `;
    }

    refreshComponents() {
        const tree = document.getElementById('components-tree');
        if (!tree) return;
        
        const components = document.querySelectorAll('[data-component]');
        tree.innerHTML = Array.from(components).map(comp => `
            <div class="dev-component-item" onclick="devTools.inspectElement(document.querySelector('[data-component=\"${comp.dataset.component}\"]'))">
                <span class="dev-component-name">${comp.dataset.component}</span>
                <span class="dev-component-tag">${comp.tagName.toLowerCase()}</span>
            </div>
        `).join('');
    }

    // Storage Inspector
    setupStorageInspector() {
        this.updateStorageDisplay();
        
        // Storage tab switching
        document.querySelectorAll('.dev-storage-tab').forEach(tab => {
            tab.addEventListener('click', () => {
                document.querySelectorAll('.dev-storage-tab').forEach(t => t.classList.remove('active'));
                tab.classList.add('active');
                this.updateStorageDisplay(tab.dataset.storage);
            });
        });
    }

    updateStorageDisplay(type = 'localStorage') {
        const list = document.getElementById('storage-list');
        if (!list) return;
        
        const storage = window[type];
        const items = [];
        
        for (let i = 0; i < storage.length; i++) {
            const key = storage.key(i);
            const value = storage.getItem(key);
            items.push({ key, value });
        }
        
        list.innerHTML = items.map(item => `
            <div class="dev-storage-item">
                <div class="dev-storage-key">${item.key}</div>
                <div class="dev-storage-value">${item.value}</div>
                <button class="dev-btn dev-btn-small" onclick="devTools.deleteStorageItem('${type}', '${item.key}')">Delete</button>
            </div>
        `).join('');
    }

    setStorageItem() {
        const keyInput = document.getElementById('storage-key');
        const valueInput = document.getElementById('storage-value');
        const activeTab = document.querySelector('.dev-storage-tab.active');
        
        if (!keyInput.value || !valueInput.value) return;
        
        window[activeTab.dataset.storage].setItem(keyInput.value, valueInput.value);
        this.updateStorageDisplay(activeTab.dataset.storage);
        
        keyInput.value = '';
        valueInput.value = '';
    }

    deleteStorageItem(type, key) {
        window[type].removeItem(key);
        this.updateStorageDisplay(type);
    }

    clearStorage() {
        const activeTab = document.querySelector('.dev-storage-tab.active');
        if (activeTab.dataset.storage === 'cookies') {
            document.cookie.split(';').forEach(cookie => {
                document.cookie = cookie.replace(/^ +/, '').replace(/=.*/, '=;expires=' + new Date().toUTCString() + ';path=/');
            });
        } else {
            window[activeTab.dataset.storage].clear();
        }
        this.updateStorageDisplay(activeTab.dataset.storage);
    }

    // Auth Panel
    updateAuthPanel() {
        const currentUser = document.getElementById('current-user');
        const authToken = document.getElementById('auth-token');
        const authActions = document.getElementById('auth-actions');
        
        if (window.authManager) {
            const user = window.authManager.getUser();
            currentUser.innerHTML = user ? `
                <div class="dev-info-row">
                    <span class="dev-label">Name:</span>
                    <span class="dev-value">${user.name || 'N/A'}</span>
                </div>
                <div class="dev-info-row">
                    <span class="dev-label">Email:</span>
                    <span class="dev-value">${user.email || 'N/A'}</span>
                </div>
                <div class="dev-info-row">
                    <span class="dev-label">Role:</span>
                    <span class="dev-value">${user.role || 'N/A'}</span>
                </div>
            ` : '<span class="dev-value">Not logged in</span>';
            
            const token = localStorage.getItem('authToken');
            authToken.innerHTML = token ? `
                <div class="dev-token-display">
                    <code>${token.substring(0, 50)}...</code>
                    <button class="dev-btn dev-btn-small" onclick="devTools.copyAuthToken()">Copy</button>
                </div>
            ` : '<span class="dev-value">No token</span>';
            
            authActions.innerHTML = user ? `
                <button class="dev-btn" onclick="devTools.logout()">Logout</button>
                <button class="dev-btn" onclick="devTools.refreshToken()">Refresh Token</button>
            ` : `
                <button class="dev-btn" onclick="devTools.showLoginDialog()">Test Login</button>
            `;
        } else {
            currentUser.innerHTML = '<span class="dev-value">Auth Manager not available</span>';
            authToken.innerHTML = '<span class="dev-value">N/A</span>';
            authActions.innerHTML = '';
        }
    }

    // Utility Functions
    generateId() {
        return Math.random().toString(36).substr(2, 9);
    }

    formatSize(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    getMemoryUsage() {
        if ('memory' in performance) {
            const used = performance.memory.usedJSHeapSize;
            const total = performance.memory.totalJSHeapSize;
            return `${this.formatSize(used)} / ${this.formatSize(total)}`;
        }
        return 'N/A';
    }

    countActiveComponents() {
        return document.querySelectorAll('[data-component]').length;
    }

    getEventListenersCount(element) {
        // This is a simplified count - actual implementation would require more complex tracking
        return 'N/A';
    }

    // Quick Actions
    reloadPage() {
        window.location.reload();
    }

    clearCache() {
        if ('caches' in window) {
            caches.keys().then(names => {
                names.forEach(name => caches.delete(name));
            });
        }
        this.log('info', 'Cache cleared');
    }

    runDiagnostics() {
        const diagnostics = {
            performance: window.performanceManager?.getPerformanceMetrics(),
            errors: window.errorHandler?.getErrorAnalytics(),
            auth: window.authManager?.getUser(),
            api: window.apiClient?.getStatus()
        };
        
        this.log('info', 'Diagnostics completed', diagnostics);
    }

    exportData() {
        const data = {
            timestamp: Date.now(),
            url: window.location.href,
            logs: this.logs,
            diagnostics: {
                performance: window.performanceManager?.getPerformanceMetrics(),
                errors: window.errorHandler?.getErrorAnalytics()
            }
        };
        
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `devtools-export-${Date.now()}.json`;
        a.click();
        URL.revokeObjectURL(url);
    }

    exportLogs() {
        const blob = new Blob([JSON.stringify(this.logs, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `console-logs-${Date.now()}.json`;
        a.click();
        URL.revokeObjectURL(url);
    }

    copyAuthToken() {
        const token = localStorage.getItem('authToken');
        if (token) {
            navigator.clipboard.writeText(token);
            this.log('info', 'Auth token copied to clipboard');
        }
    }

    logout() {
        if (window.authManager) {
            window.authManager.logout();
        }
    }

    refreshToken() {
        this.log('info', 'Token refresh requested');
    }

    showLoginDialog() {
        if (window.componentManager) {
            window.componentManager.showModal({
                title: 'Test Login',
                content: `
                    <div class="dev-login-form">
                        <input type="email" id="test-email" placeholder="Email" value="test@example.com">
                        <input type="password" id="test-password" placeholder="Password" value="password">
                        <button onclick="devTools.testLogin()">Test Login</button>
                    </div>
                `
            });
        }
    }

    testLogin() {
        const email = document.getElementById('test-email').value;
        const password = document.getElementById('test-password').value;
        
        this.log('info', 'Test login attempt', { email });
        
        // Simulate login
        setTimeout(() => {
            const mockUser = {
                id: 'test-user',
                email,
                name: 'Test User',
                role: 'student'
            };
            
            localStorage.setItem('authToken', 'mock-token-' + Date.now());
            localStorage.setItem('user', JSON.stringify(mockUser));
            localStorage.setItem('userRole', mockUser.role);
            
            this.log('info', 'Test login successful', mockUser);
            this.updateAuthPanel();
            
            if (window.componentManager) {
                window.componentManager.hideAllModals();
            }
        }, 1000);
    }

    // UI Controls
    toggleDevTools() {
        const devTools = document.getElementById('dev-tools');
        const isVisible = devTools.classList.contains('visible');
        
        if (isVisible) {
            this.hideDevTools();
        } else {
            this.showDevTools();
        }
    }

    showDevTools() {
        const devTools = document.getElementById('dev-tools');
        devTools.classList.add('visible');
        this.updateDashboard();
        this.startMetricsCollection();
    }

    hideDevTools() {
        const devTools = document.getElementById('dev-tools');
        devTools.classList.remove('visible');
        this.stopMetricsCollection();
    }

    switchPanel(panelName) {
        // Update tabs
        document.querySelectorAll('.dev-tools-tab').forEach(tab => {
            tab.classList.remove('active');
        });
        document.querySelector(`[data-panel="${panelName}"]`).classList.add('active');
        
        // Update panels
        document.querySelectorAll('.dev-tools-panel').forEach(panel => {
            panel.classList.remove('active');
        });
        document.getElementById(`dev-${panelName}`).classList.add('active');
        
        // Update panel content
        this.updatePanel(panelName);
    }

    updatePanel(panelName) {
        switch (panelName) {
            case 'dashboard':
                this.updateDashboard();
                break;
            case 'auth':
                this.updateAuthPanel();
                break;
            case 'components':
                this.refreshComponents();
                break;
            case 'storage':
                this.updateStorageDisplay();
                break;
        }
    }

    setupKeyboardShortcut() {
        document.addEventListener('keydown', (event) => {
            const combo = this.getKeyboardCombo(event);
            if (combo === this.shortcutKey) {
                event.preventDefault();
                this.toggleDevTools();
            }
        });
    }

    getKeyboardCombo(event) {
        const parts = [];
        
        if (event.ctrlKey) parts.push('Ctrl');
        if (event.shiftKey) parts.push('Shift');
        if (event.altKey) parts.push('Alt');
        if (event.metaKey) parts.push('Meta');
        
        parts.push(event.key);
        
        return parts.join('+');
    }

    bindDevToolsEvents() {
        // Listen to other managers' events
        if (window.performanceManager) {
            window.addEventListener('performance:metric', (event) => {
                this.log('debug', 'Performance metric', event.detail);
            });
        }
        
        if (window.errorHandler) {
            window.addEventListener('error:handled', (event) => {
                this.log('error', 'Error handled', event.detail);
            });
        }
        
        if (window.apiClient) {
            window.addEventListener('api:request', (event) => {
                this.log('debug', 'API request', event.detail);
            });
        }
    }

    startMetricsCollection() {
        if (this.metricsInterval) return;
        
        this.metricsInterval = setInterval(() => {
            this.collectMetrics();
        }, this.config.updateInterval);
    }

    stopMetricsCollection() {
        if (this.metricsInterval) {
            clearInterval(this.metricsInterval);
            this.metricsInterval = null;
        }
    }

    collectMetrics() {
        // Collect periodic metrics
        this.metrics.set('timestamp', Date.now());
        
        if ('memory' in performance) {
            this.metrics.set('memory', {
                used: performance.memory.usedJSHeapSize,
                total: performance.memory.totalJSHeapSize,
                limit: performance.memory.jsHeapSizeLimit
            });
        }
        
        // Update UI if visible
        if (document.getElementById('dev-tools').classList.contains('visible')) {
            this.updatePerformanceMetrics();
        }
    }
}

// Create global instance
window.devTools = new DevTools();

// Override console methods to capture logs
if (window.devTools.isEnabled) {
    const originalConsole = {
        log: console.log,
        info: console.info,
        warn: console.warn,
        error: console.error,
        debug: console.debug
    };
    
    console.log = function(...args) {
        originalConsole.log.apply(console, args);
        window.devTools.log('info', args.join(' '), args.length > 1 ? args[1] : null);
    };
    
    console.info = function(...args) {
        originalConsole.info.apply(console, args);
        window.devTools.log('info', args.join(' '), args.length > 1 ? args[1] : null);
    };
    
    console.warn = function(...args) {
        originalConsole.warn.apply(console, args);
        window.devTools.log('warn', args.join(' '), args.length > 1 ? args[1] : null);
    };
    
    console.error = function(...args) {
        originalConsole.error.apply(console, args);
        window.devTools.log('error', args.join(' '), args.length > 1 ? args[1] : null);
    };
    
    console.debug = function(...args) {
        originalConsole.debug.apply(console, args);
        window.devTools.log('debug', args.join(' '), args.length > 1 ? args[1] : null);
    };
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = DevTools;
}