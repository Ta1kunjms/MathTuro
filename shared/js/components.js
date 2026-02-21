/**
 * Component Manager - Reusable UI Components (Modals, Notifications, etc.)
 * Comprehensive component library for consistent UI elements
 */

class ComponentManager {
    constructor() {
        this.components = new Map();
        this.modals = new Map();
        this.notifications = new Queue();
        this.toasts = new Queue();
        this.componentRegistry = new Map();
        this.defaultConfigs = this.initializeDefaultConfigs();
        
        this.initializeComponentSystem();
        this.setupGlobalComponentStyles();
        this.bindComponentEvents();
    }

    initializeDefaultConfigs() {
        return {
            modal: {
                closeOnEscape: true,
                closeOnBackdrop: true,
                showBackdrop: true,
                animationDuration: 300,
                zIndex: 1000
            },
            notification: {
                autoHide: true,
                duration: 5000,
                position: 'top-right',
                animationDuration: 300,
                maxVisible: 5
            },
            toast: {
                autoHide: true,
                duration: 3000,
                position: 'bottom-right',
                animationDuration: 200
            },
            dropdown: {
                closeOnEscape: true,
                closeOnOutsideClick: true,
                animationDuration: 200
            },
            tooltip: {
                position: 'top',
                trigger: 'hover',
                delay: 300,
                duration: 200
            }
        };
    }

    initializeComponentSystem() {
        this.createComponentContainer();
        this.initializeModalSystem();
        this.initializeNotificationSystem();
        this.initializeToastSystem();
    }

    // Modal System
    initializeModalSystem() {
        this.modalContainer = this.createModalContainer();
    }

    createModalContainer() {
        let container = document.getElementById('modal-container');
        
        if (!container) {
            container = document.createElement('div');
            container.id = 'modal-container';
            container.className = 'modal-container';
            document.body.appendChild(container);
        }
        
        return container;
    }

    showModal(options = {}) {
        const config = { ...this.defaultConfigs.modal, ...options };
        const modalId = this.generateId('modal');
        
        const modal = this.createModal(modalId, config);
        this.modals.set(modalId, { modal, config });
        
        this.modalContainer.appendChild(modal);
        
        // Show modal with animation
        requestAnimationFrame(() => {
            modal.classList.add('show');
            this.trapFocus(modal);
        });
        
        // Auto-bind close events
        this.bindModalEvents(modalId, config);
        
        return modalId;
    }

    createModal(id, config) {
        const modal = document.createElement('div');
        modal.id = id;
        modal.className = 'modal';
        modal.setAttribute('role', 'dialog');
        modal.setAttribute('aria-modal', 'true');
        modal.setAttribute('aria-labelledby', `${id}-title`);
        modal.setAttribute('aria-describedby', `${id}-description`);
        
        modal.innerHTML = `
            ${config.showBackdrop ? '<div class="modal-backdrop"></div>' : ''}
            <div class="modal-content">
                <div class="modal-header">
                    <h2 id="${id}-title" class="modal-title">${config.title || ''}</h2>
                    <button class="modal-close" aria-label="Close modal">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div id="${id}-description" class="modal-body">
                    ${config.content || ''}
                </div>
                ${config.footer ? `
                    <div class="modal-footer">
                        ${config.footer}
                    </div>
                ` : ''}
            </div>
        `;
        
        return modal;
    }

    bindModalEvents(modalId, config) {
        const modalElement = document.getElementById(modalId);
        
        // Close button
        const closeBtn = modalElement.querySelector('.modal-close');
        if (closeBtn) {
            closeBtn.addEventListener('click', () => this.hideModal(modalId));
        }
        
        // Backdrop click
        if (config.closeOnBackdrop) {
            const backdrop = modalElement.querySelector('.modal-backdrop');
            if (backdrop) {
                backdrop.addEventListener('click', () => this.hideModal(modalId));
            }
        }
        
        // Escape key
        if (config.closeOnEscape) {
            const handleEscape = (event) => {
                if (event.key === 'Escape') {
                    this.hideModal(modalId);
                    document.removeEventListener('keydown', handleEscape);
                }
            };
            document.addEventListener('keydown', handleEscape);
        }
    }

    hideModal(modalId) {
        const modalData = this.modals.get(modalId);
        if (!modalData) return;
        
        const { modal, config } = modalData;
        modal.classList.remove('show');
        
        setTimeout(() => {
            modal.remove();
            this.modals.delete(modalId);
        }, config.animationDuration);
    }

    hideAllModals() {
        this.modals.forEach((_, modalId) => {
            this.hideModal(modalId);
        });
    }

    // Notification System
    initializeNotificationSystem() {
        this.notificationContainer = this.createNotificationContainer();
    }

    createNotificationContainer() {
        const positions = ['top-left', 'top-right', 'bottom-left', 'bottom-right', 'top-center', 'bottom-center'];
        const containers = {};
        
        positions.forEach(position => {
            let container = document.getElementById(`notification-container-${position}`);
            
            if (!container) {
                container = document.createElement('div');
                container.id = `notification-container-${position}`;
                container.className = `notification-container notification-container-${position}`;
                document.body.appendChild(container);
            }
            
            containers[position] = container;
        });
        
        return containers;
    }

    showNotification(options = {}) {
        const config = { ...this.defaultConfigs.notification, ...options };
        const notificationId = this.generateId('notification');
        
        const notification = this.createNotification(notificationId, config);
        this.notifications.enqueue({ id: notificationId, notification, config });
        
        const container = this.notificationContainer[config.position];
        container.appendChild(notification);
        
        // Show with animation
        requestAnimationFrame(() => {
            notification.classList.add('show');
        });
        
        // Auto-hide
        if (config.autoHide) {
            setTimeout(() => {
                this.hideNotification(notificationId);
            }, config.duration);
        }
        
        // Limit visible notifications
        this.limitVisibleNotifications(config.position, config.maxVisible);
        
        return notificationId;
    }

    createNotification(id, config) {
        const notification = document.createElement('div');
        notification.id = id;
        notification.className = `notification notification-${config.type || 'info'}`;
        notification.setAttribute('role', 'alert');
        
        notification.innerHTML = `
            <div class="notification-content">
                ${config.icon ? `<div class="notification-icon">${this.getIcon(config.icon)}</div>` : ''}
                <div class="notification-message">
                    <div class="notification-title">${config.title || ''}</div>
                    <div class="notification-text">${config.message || ''}</div>
                </div>
                <button class="notification-close" aria-label="Close notification">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            ${config.progress ? '<div class="notification-progress"></div>' : ''}
        `;
        
        // Bind close event
        const closeBtn = notification.querySelector('.notification-close');
        if (closeBtn) {
            closeBtn.addEventListener('click', () => this.hideNotification(id));
        }
        
        return notification;
    }

    hideNotification(notificationId) {
        const notificationElement = document.getElementById(notificationId);
        if (!notificationElement) return;
        
        notificationElement.classList.remove('show');
        
        setTimeout(() => {
            notificationElement.remove();
            this.notifications.dequeue(item => item.id === notificationId);
        }, this.defaultConfigs.notification.animationDuration);
    }

    limitVisibleNotifications(position, maxVisible) {
        const container = this.notificationContainer[position];
        const notifications = container.querySelectorAll('.notification');
        
        if (notifications.length > maxVisible) {
            const excessCount = notifications.length - maxVisible;
            for (let i = 0; i < excessCount; i++) {
                const oldNotification = notifications[i];
                oldNotification.classList.remove('show');
                setTimeout(() => oldNotification.remove(), 300);
            }
        }
    }

    // Toast System
    initializeToastSystem() {
        this.toastContainer = this.createToastContainer();
    }

    createToastContainer() {
        let container = document.getElementById('toast-container');
        
        if (!container) {
            container = document.createElement('div');
            container.id = 'toast-container';
            container.className = 'toast-container';
            document.body.appendChild(container);
        }
        
        return container;
    }

    showToast(options = {}) {
        const config = { ...this.defaultConfigs.toast, ...options };
        const toastId = this.generateId('toast');
        
        const toast = this.createToast(toastId, config);
        this.toasts.enqueue({ id: toastId, toast, config });
        
        this.toastContainer.appendChild(toast);
        
        // Show with animation
        requestAnimationFrame(() => {
            toast.classList.add('show');
        });
        
        // Auto-hide
        if (config.autoHide) {
            setTimeout(() => {
                this.hideToast(toastId);
            }, config.duration);
        }
        
        return toastId;
    }

    createToast(id, config) {
        const toast = document.createElement('div');
        toast.id = id;
        toast.className = `toast toast-${config.type || 'info'}`;
        toast.setAttribute('role', 'status');
        toast.setAttribute('aria-live', 'polite');
        
        toast.innerHTML = `
            <div class="toast-content">
                ${config.icon ? `<div class="toast-icon">${this.getIcon(config.icon)}</div>` : ''}
                <div class="toast-message">${config.message || ''}</div>
                ${config.closable ? '<button class="toast-close" aria-label="Close toast">&times;</button>' : ''}
            </div>
        `;
        
        // Bind close event if closable
        if (config.closable) {
            const closeBtn = toast.querySelector('.toast-close');
            if (closeBtn) {
                closeBtn.addEventListener('click', () => this.hideToast(id));
            }
        }
        
        return toast;
    }

    hideToast(toastId) {
        const toastElement = document.getElementById(toastId);
        if (!toastElement) return;
        
        toastElement.classList.remove('show');
        
        setTimeout(() => {
            toastElement.remove();
            this.toasts.dequeue(item => item.id === toastId);
        }, this.defaultConfigs.toast.animationDuration);
    }

    // Dropdown System
    createDropdown(options = {}) {
        const config = { ...this.defaultConfigs.dropdown, ...options };
        const dropdownId = this.generateId('dropdown');
        
        const dropdown = document.createElement('div');
        dropdown.id = dropdownId;
        dropdown.className = 'dropdown';
        
        const trigger = document.createElement('button');
        trigger.className = 'dropdown-trigger';
        trigger.innerHTML = config.triggerText || 'Dropdown';
        trigger.setAttribute('aria-haspopup', 'true');
        trigger.setAttribute('aria-expanded', 'false');
        
        const menu = document.createElement('div');
        menu.className = 'dropdown-menu';
        menu.setAttribute('role', 'menu');
        menu.innerHTML = config.menuContent || '';
        
        dropdown.appendChild(trigger);
        dropdown.appendChild(menu);
        
        // Bind events
        this.bindDropdownEvents(dropdownId, config);
        
        return dropdownId;
    }

    bindDropdownEvents(dropdownId, config) {
        const dropdown = document.getElementById(dropdownId);
        const trigger = dropdown.querySelector('.dropdown-trigger');
        const menu = dropdown.querySelector('.dropdown-menu');
        
        const toggleDropdown = () => {
            const isOpen = menu.classList.contains('show');
            
            if (isOpen) {
                this.closeDropdown(dropdownId);
            } else {
                this.openDropdown(dropdownId);
            }
        };
        
        trigger.addEventListener('click', toggleDropdown);
        
        // Close on outside click
        if (config.closeOnOutsideClick) {
            document.addEventListener('click', (event) => {
                if (!dropdown.contains(event.target)) {
                    this.closeDropdown(dropdownId);
                }
            });
        }
        
        // Close on escape
        if (config.closeOnEscape) {
            document.addEventListener('keydown', (event) => {
                if (event.key === 'Escape') {
                    this.closeDropdown(dropdownId);
                }
            });
        }
    }

    openDropdown(dropdownId) {
        const dropdown = document.getElementById(dropdownId);
        const menu = dropdown.querySelector('.dropdown-menu');
        const trigger = dropdown.querySelector('.dropdown-trigger');
        
        menu.classList.add('show');
        trigger.setAttribute('aria-expanded', 'true');
    }

    closeDropdown(dropdownId) {
        const dropdown = document.getElementById(dropdownId);
        const menu = dropdown.querySelector('.dropdown-menu');
        const trigger = dropdown.querySelector('.dropdown-trigger');
        
        menu.classList.remove('show');
        trigger.setAttribute('aria-expanded', 'false');
    }

    // Tooltip System
    createTooltip(element, options = {}) {
        const config = { ...this.defaultConfigs.tooltip, ...options };
        
        const tooltip = document.createElement('div');
        tooltip.className = 'tooltip';
        tooltip.textContent = config.content || '';
        tooltip.setAttribute('role', 'tooltip');
        
        element.appendChild(tooltip);
        
        // Position tooltip
        this.positionTooltip(element, tooltip, config.position);
        
        // Bind events
        this.bindTooltipEvents(element, tooltip, config);
        
        return tooltip;
    }

    positionTooltip(element, tooltip, position) {
        const positions = {
            top: 'tooltip-top',
            bottom: 'tooltip-bottom',
            left: 'tooltip-left',
            right: 'tooltip-right'
        };
        
        tooltip.className = `tooltip ${positions[position] || positions.top}`;
    }

    bindTooltipEvents(element, tooltip, config) {
        let timeoutId;
        
        const showTooltip = () => {
            clearTimeout(timeoutId);
            timeoutId = setTimeout(() => {
                tooltip.classList.add('show');
            }, config.delay);
        };
        
        const hideTooltip = () => {
            clearTimeout(timeoutId);
            tooltip.classList.remove('show');
        };
        
        if (config.trigger === 'hover') {
            element.addEventListener('mouseenter', showTooltip);
            element.addEventListener('mouseleave', hideTooltip);
        } else if (config.trigger === 'click') {
            element.addEventListener('click', () => {
                const isShown = tooltip.classList.contains('show');
                if (isShown) {
                    hideTooltip();
                } else {
                    showTooltip();
                }
            });
        }
    }

    // Loading States
    showLoading(element, options = {}) {
        const config = {
            size: 'medium',
            text: 'Loading...',
            overlay: false,
            ...options
        };
        
        const loadingElement = document.createElement('div');
        loadingElement.className = `loading loading-${config.size}`;
        
        if (config.overlay) {
            loadingElement.classList.add('loading-overlay');
        }
        
        loadingElement.innerHTML = `
            <div class="loading-spinner"></div>
            ${config.text ? `<div class="loading-text">${config.text}</div>` : ''}
        `;
        
        // Store original content
        const originalContent = element.innerHTML;
        element.dataset.originalContent = originalContent;
        
        // Show loading
        element.innerHTML = '';
        element.appendChild(loadingElement);
        element.classList.add('loading-state');
        
        return loadingElement;
    }

    hideLoading(element) {
        if (element.dataset.originalContent) {
            element.innerHTML = element.dataset.originalContent;
            delete element.dataset.originalContent;
        }
        element.classList.remove('loading-state');
    }

    // Utility Methods
    generateId(prefix) {
        return `${prefix}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    }

    getIcon(iconName) {
        const icons = {
            success: '<svg viewBox="0 0 24 24"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z"/></svg>',
            error: '<svg viewBox="0 0 24 24"><path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/></svg>',
            warning: '<svg viewBox="0 0 24 24"><path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>',
            info: '<svg viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/></svg>'
        };
        
        return icons[iconName] || icons.info;
    }

    trapFocus(element) {
        const focusableElements = element.querySelectorAll(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );
        const firstElement = focusableElements[0];
        const lastElement = focusableElements[focusableElements.length - 1];
        
        const handleTabKey = (e) => {
            if (e.key === 'Tab') {
                if (e.shiftKey) {
                    if (document.activeElement === firstElement) {
                        lastElement.focus();
                        e.preventDefault();
                    }
                } else {
                    if (document.activeElement === lastElement) {
                        firstElement.focus();
                        e.preventDefault();
                    }
                }
            }
            
            if (e.key === 'Escape') {
                // Find the closest modal and close it
                const modal = e.target.closest('.modal');
                if (modal) {
                    const modalId = modal.id;
                    this.hideModal(modalId);
                }
            }
        };
        
        element.addEventListener('keydown', handleTabKey);
        firstElement.focus();
        
        // Store cleanup function
        element._focusTrapCleanup = () => {
            element.removeEventListener('keydown', handleTabKey);
        };
    }

    setupGlobalComponentStyles() {
        if (document.getElementById('component-styles')) return;
        
        const style = document.createElement('style');
        style.id = 'component-styles';
        style.textContent = this.getComponentStyles();
        document.head.appendChild(style);
    }

    getComponentStyles() {
        return `
            /* Modal Styles */
            .modal {
                display: none;
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                z-index: 1000;
            }
            
            .modal.show {
                display: flex;
                align-items: center;
                justify-content: center;
            }
            
            .modal-backdrop {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.5);
            }
            
            .modal-content {
                position: relative;
                background: white;
                border-radius: 8px;
                max-width: 90vw;
                max-height: 90vh;
                overflow: auto;
                box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
                z-index: 1001;
            }
            
            .modal-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 1.5rem;
                border-bottom: 1px solid #e5e7eb;
            }
            
            .modal-body {
                padding: 1.5rem;
            }
            
            .modal-footer {
                padding: 1rem 1.5rem;
                border-top: 1px solid #e5e7eb;
                display: flex;
                justify-content: flex-end;
                gap: 0.5rem;
            }
            
            .modal-close {
                background: none;
                border: none;
                font-size: 1.5rem;
                cursor: pointer;
                padding: 0;
                width: 2rem;
                height: 2rem;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            
            /* Notification Styles */
            .notification-container {
                position: fixed;
                z-index: 2000;
                pointer-events: none;
            }
            
            .notification-container-top-right {
                top: 1rem;
                right: 1rem;
            }
            
            .notification {
                background: white;
                border-radius: 8px;
                box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
                margin-bottom: 0.5rem;
                pointer-events: auto;
                transform: translateX(100%);
                transition: transform 0.3s ease;
                min-width: 300px;
                max-width: 400px;
            }
            
            .notification.show {
                transform: translateX(0);
            }
            
            .notification-content {
                display: flex;
                align-items: flex-start;
                padding: 1rem;
            }
            
            .notification-icon {
                margin-right: 0.75rem;
                flex-shrink: 0;
            }
            
            .notification-message {
                flex: 1;
            }
            
            .notification-title {
                font-weight: 600;
                margin-bottom: 0.25rem;
            }
            
            .notification-close {
                background: none;
                border: none;
                font-size: 1.25rem;
                cursor: pointer;
                padding: 0;
                margin-left: 0.5rem;
            }
            
            .notification-success { border-left: 4px solid #10b981; }
            .notification-error { border-left: 4px solid #ef4444; }
            .notification-warning { border-left: 4px solid #f59e0b; }
            .notification-info { border-left: 4px solid #3b82f6; }
            
            /* Toast Styles */
            .toast-container {
                position: fixed;
                bottom: 1rem;
                right: 1rem;
                z-index: 2000;
            }
            
            .toast {
                background: #1f2937;
                color: white;
                border-radius: 6px;
                box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
                margin-bottom: 0.5rem;
                transform: translateY(100%);
                transition: transform 0.2s ease;
                min-width: 250px;
            }
            
            .toast.show {
                transform: translateY(0);
            }
            
            .toast-content {
                display: flex;
                align-items: center;
                padding: 0.75rem 1rem;
            }
            
            .toast-close {
                background: none;
                border: none;
                color: white;
                font-size: 1.25rem;
                cursor: pointer;
                padding: 0;
                margin-left: 0.5rem;
                opacity: 0.7;
            }
            
            /* Loading Styles */
            .loading {
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                padding: 2rem;
            }
            
            .loading-overlay {
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(255, 255, 255, 0.9);
                z-index: 10;
            }
            
            .loading-spinner {
                border: 3px solid #f3f4f6;
                border-top: 3px solid #3b82f6;
                border-radius: 50%;
                width: 2rem;
                height: 2rem;
                animation: spin 1s linear infinite;
            }
            
            .loading-small .loading-spinner { width: 1rem; height: 1rem; }
            .loading-large .loading-spinner { width: 3rem; height: 3rem; }
            
            .loading-text {
                margin-top: 0.5rem;
                color: #6b7280;
            }
            
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
            
            /* Dropdown Styles */
            .dropdown {
                position: relative;
                display: inline-block;
            }
            
            .dropdown-menu {
                position: absolute;
                top: 100%;
                left: 0;
                background: white;
                border: 1px solid #e5e7eb;
                border-radius: 6px;
                box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
                z-index: 100;
                opacity: 0;
                visibility: hidden;
                transform: translateY(-10px);
                transition: all 0.2s ease;
            }
            
            .dropdown-menu.show {
                opacity: 1;
                visibility: visible;
                transform: translateY(0);
            }
            
            /* Tooltip Styles */
            .tooltip {
                position: absolute;
                background: #1f2937;
                color: white;
                padding: 0.5rem 0.75rem;
                border-radius: 4px;
                font-size: 0.875rem;
                white-space: nowrap;
                z-index: 50;
                opacity: 0;
                transition: opacity 0.2s ease;
                pointer-events: none;
            }
            
            .tooltip.show {
                opacity: 1;
            }
            
            .tooltip-top { bottom: 100%; left: 50%; transform: translateX(-50%) translateY(-0.5rem); }
            .tooltip-bottom { top: 100%; left: 50%; transform: translateX(-50%) translateY(0.5rem); }
            .tooltip-left { right: 100%; top: 50%; transform: translateY(-50%) translateX(-0.5rem); }
            .tooltip-right { left: 100%; top: 50%; transform: translateY(-50%) translateX(0.5rem); }
        `;
    }

    bindComponentEvents() {
        // Global component event handlers
        document.addEventListener('click', (event) => {
            // Handle data-component attributes
            const component = event.target.closest('[data-component]');
            if (component) {
                this.handleComponentAction(component, event);
            }
        });
    }

    handleComponentAction(element, event) {
        const componentName = element.dataset.component;
        const action = element.dataset.action;
        
        if (this.componentRegistry.has(componentName)) {
            const componentConfig = this.componentRegistry.get(componentName);
            if (componentConfig[action]) {
                componentConfig[action](element, event);
            }
        }
    }

    // Component Registry
    registerComponent(name, config) {
        this.componentRegistry.set(name, config);
    }

    // Queue implementation for notifications/toasts
    enqueue(item) {
        this.items.push(item);
    }

    dequeue(predicate) {
        const index = this.items.findIndex(predicate);
        if (index !== -1) {
            return this.items.splice(index, 1)[0];
        }
        return null;
    }
}

// Simple Queue implementation
class Queue {
    constructor() {
        this.items = [];
    }

    enqueue(item) {
        this.items.push(item);
    }

    dequeue() {
        if (this.items.length === 0) return null;
        return this.items.shift();
    }

    peek() {
        if (this.items.length === 0) return null;
        return this.items[0];
    }

    isEmpty() {
        return this.items.length === 0;
    }

    size() {
        return this.items.length;
    }

    find(predicate) {
        return this.items.find(predicate);
    }

    filter(predicate) {
        return this.items.filter(predicate);
    }
}

// Global component manager instance
window.componentManager = new ComponentManager();

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    // Initialize data-component elements
    document.querySelectorAll('[data-component]').forEach(element => {
        const componentName = element.dataset.component;
        // Auto-initialize common components
    });
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { ComponentManager, Queue };
}