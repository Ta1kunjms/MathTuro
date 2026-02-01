/*
  File: utils.js
  Purpose:
  - Utility functions for the application
  - Toast notifications
  - Form validation
  - HTML sanitization
  - Caching
  - Session management
  - Pagination helpers

  Dependencies:
  - config.js - for configuration settings
*/

// ============================================
// TOAST NOTIFICATION SYSTEM
// ============================================

/*
  Toast notification container - will be created on first use
*/
let toastContainer = null;

/*
  Function Name: createToastContainer
  Purpose: Creates the container element for toast notifications
*/
function createToastContainer() {
  if (toastContainer) return toastContainer;

  toastContainer = document.createElement('div');
  toastContainer.id = 'toast-container';
  toastContainer.className = 'fixed top-4 right-4 z-50 flex flex-col gap-2';
  toastContainer.setAttribute('aria-live', 'polite');
  toastContainer.setAttribute('aria-label', 'Notifications');
  document.body.appendChild(toastContainer);

  return toastContainer;
}

/*
  Function Name: showToast
  Purpose: Displays a toast notification
  
  Parameters:
  - message: The message to display
  - type: 'success' | 'error' | 'warning' | 'info'
  - duration: How long to show the toast (default from config)
*/
function showToast(message, type = 'info', duration = CONFIG.TOAST_DURATION) {
  const container = createToastContainer();

  const toast = document.createElement('div');
  toast.className = `
    toast-notification px-4 py-3 rounded-lg shadow-lg flex items-center gap-3 
    transform transition-all duration-300 translate-x-full opacity-0
    ${getToastColorClass(type)}
  `;
  toast.setAttribute('role', 'alert');

  const icon = getToastIcon(type);
  
  toast.innerHTML = `
    <span class="text-xl" aria-hidden="true">${icon}</span>
    <span class="flex-1">${escapeHtml(message)}</span>
    <button class="text-lg opacity-70 hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-white rounded" 
            aria-label="Close notification" onclick="this.parentElement.remove()">×</button>
  `;

  container.appendChild(toast);

  // Trigger animation
  requestAnimationFrame(() => {
    toast.classList.remove('translate-x-full', 'opacity-0');
  });

  // Auto remove after duration
  if (duration > 0) {
    setTimeout(() => {
      toast.classList.add('translate-x-full', 'opacity-0');
      setTimeout(() => toast.remove(), 300);
    }, duration);
  }

  return toast;
}

function getToastColorClass(type) {
  switch (type) {
    case 'success': return 'bg-green-600 text-white';
    case 'error': return 'bg-red-600 text-white';
    case 'warning': return 'bg-yellow-500 text-white';
    case 'info': default: return 'bg-blue-600 text-white';
  }
}

function getToastIcon(type) {
  switch (type) {
    case 'success': return '✓';
    case 'error': return '✕';
    case 'warning': return '⚠';
    case 'info': default: return 'ℹ';
  }
}

// ============================================
// CONFIRMATION MODAL
// ============================================

/*
  Function Name: showConfirmModal
  Purpose: Shows a confirmation modal instead of browser confirm()
  Returns: Promise that resolves to true (confirmed) or false (cancelled)
*/
function showConfirmModal(title, message, confirmText = 'Confirm', cancelText = 'Cancel', type = 'warning') {
  return new Promise((resolve) => {
    // Create modal overlay
    const overlay = document.createElement('div');
    overlay.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50';
    overlay.setAttribute('role', 'dialog');
    overlay.setAttribute('aria-modal', 'true');
    overlay.setAttribute('aria-labelledby', 'confirm-modal-title');

    const colorClass = type === 'danger' ? 'bg-red-600 hover:bg-red-700' : 'bg-blue-600 hover:bg-blue-700';

    overlay.innerHTML = `
      <div class="bg-white rounded-lg shadow-xl max-w-md w-full mx-4 overflow-hidden">
        <div class="p-6">
          <h3 id="confirm-modal-title" class="text-lg font-semibold text-gray-800 mb-2">${escapeHtml(title)}</h3>
          <p class="text-gray-600">${escapeHtml(message)}</p>
        </div>
        <div class="bg-gray-50 px-6 py-3 flex justify-end gap-3">
          <button id="confirmModalCancel" class="px-4 py-2 text-gray-700 border border-gray-300 rounded-md hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-500">
            ${escapeHtml(cancelText)}
          </button>
          <button id="confirmModalConfirm" class="px-4 py-2 text-white rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 ${colorClass}">
            ${escapeHtml(confirmText)}
          </button>
        </div>
      </div>
    `;

    document.body.appendChild(overlay);

    // Focus management
    const confirmBtn = overlay.querySelector('#confirmModalConfirm');
    const cancelBtn = overlay.querySelector('#confirmModalCancel');
    confirmBtn.focus();

    // Handle keyboard
    overlay.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        overlay.remove();
        resolve(false);
      }
      if (e.key === 'Tab') {
        // Trap focus within modal
        const focusableElements = overlay.querySelectorAll('button');
        const firstElement = focusableElements[0];
        const lastElement = focusableElements[focusableElements.length - 1];

        if (e.shiftKey && document.activeElement === firstElement) {
          e.preventDefault();
          lastElement.focus();
        } else if (!e.shiftKey && document.activeElement === lastElement) {
          e.preventDefault();
          firstElement.focus();
        }
      }
    });

    // Handle clicks
    cancelBtn.addEventListener('click', () => {
      overlay.remove();
      resolve(false);
    });

    confirmBtn.addEventListener('click', () => {
      overlay.remove();
      resolve(true);
    });

    // Click outside to cancel
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        overlay.remove();
        resolve(false);
      }
    });
  });
}

// ============================================
// HTML SANITIZATION
// ============================================

/*
  Function Name: escapeHtml
  Purpose: Escapes HTML special characters to prevent XSS
*/
function escapeHtml(text) {
  if (typeof text !== 'string') return text;
  
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

/*
  Function Name: sanitizeHtml
  Purpose: Sanitizes HTML content, allowing only safe tags
*/
function sanitizeHtml(html) {
  if (typeof html !== 'string') return html;

  // Create a temporary element
  const temp = document.createElement('div');
  temp.innerHTML = html;

  // Remove dangerous elements
  const dangerousTags = ['script', 'iframe', 'object', 'embed', 'form', 'input', 'button'];
  dangerousTags.forEach(tag => {
    const elements = temp.querySelectorAll(tag);
    elements.forEach(el => el.remove());
  });

  // Remove dangerous attributes
  const allElements = temp.querySelectorAll('*');
  allElements.forEach(el => {
    // Remove event handlers
    Array.from(el.attributes).forEach(attr => {
      if (attr.name.startsWith('on') || attr.name === 'href' && attr.value.startsWith('javascript:')) {
        el.removeAttribute(attr.name);
      }
    });
  });

  return temp.innerHTML;
}

// ============================================
// FORM VALIDATION
// ============================================

/*
  Function Name: validateEmail
  Purpose: Validates email format
*/
function validateEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/*
  Function Name: validatePassword
  Purpose: Validates password strength
  Returns: { valid: boolean, errors: string[] }
*/
function validatePassword(password) {
  const errors = [];
  
  if (password.length < CONFIG.MIN_PASSWORD_LENGTH) {
    errors.push(`Password must be at least ${CONFIG.MIN_PASSWORD_LENGTH} characters`);
  }
  
  return {
    valid: errors.length === 0,
    errors
  };
}

/*
  Function Name: validateRequired
  Purpose: Validates that a field is not empty
*/
function validateRequired(value, fieldName) {
  if (!value || (typeof value === 'string' && value.trim() === '')) {
    return { valid: false, error: `${fieldName} is required` };
  }
  return { valid: true };
}

/*
  Function Name: validateMaxLength
  Purpose: Validates that a field doesn't exceed max length
*/
function validateMaxLength(value, maxLength, fieldName) {
  if (typeof value === 'string' && value.length > maxLength) {
    return { valid: false, error: `${fieldName} must be less than ${maxLength} characters` };
  }
  return { valid: true };
}

/*
  Function Name: validateForm
  Purpose: Validates a form based on rules
  
  Parameters:
  - formData: Object with field values
  - rules: Object with validation rules per field
  
  Returns: { valid: boolean, errors: { [field]: string[] } }
*/
function validateForm(formData, rules) {
  const errors = {};
  
  for (const [field, fieldRules] of Object.entries(rules)) {
    const value = formData[field];
    errors[field] = [];
    
    for (const rule of fieldRules) {
      if (rule.required) {
        const result = validateRequired(value, rule.label || field);
        if (!result.valid) errors[field].push(result.error);
      }
      
      if (rule.email && value) {
        if (!validateEmail(value)) {
          errors[field].push('Please enter a valid email address');
        }
      }
      
      if (rule.minLength && value) {
        if (value.length < rule.minLength) {
          errors[field].push(`${rule.label || field} must be at least ${rule.minLength} characters`);
        }
      }
      
      if (rule.maxLength && value) {
        if (value.length > rule.maxLength) {
          errors[field].push(`${rule.label || field} must be less than ${rule.maxLength} characters`);
        }
      }
      
      if (rule.pattern && value) {
        if (!rule.pattern.test(value)) {
          errors[field].push(rule.message || `${rule.label || field} is invalid`);
        }
      }
      
      if (rule.custom && value) {
        const result = rule.custom(value, formData);
        if (!result.valid) {
          errors[field].push(result.error);
        }
      }
    }
    
    // Remove empty error arrays
    if (errors[field].length === 0) {
      delete errors[field];
    }
  }
  
  return {
    valid: Object.keys(errors).length === 0,
    errors
  };
}

/*
  Function Name: showFieldError
  Purpose: Shows validation error for a form field
*/
function showFieldError(fieldId, message) {
  const field = document.getElementById(fieldId);
  if (!field) return;

  // Add error styling
  field.classList.add('border-red-500', 'focus:ring-red-500');
  field.classList.remove('border-gray-300', 'focus:ring-blue-500');

  // Add or update error message
  let errorEl = document.getElementById(`${fieldId}-error`);
  if (!errorEl) {
    errorEl = document.createElement('p');
    errorEl.id = `${fieldId}-error`;
    errorEl.className = 'text-sm text-red-600 mt-1';
    errorEl.setAttribute('role', 'alert');
    field.parentNode.appendChild(errorEl);
  }
  errorEl.textContent = message;
  field.setAttribute('aria-invalid', 'true');
  field.setAttribute('aria-describedby', `${fieldId}-error`);
}

/*
  Function Name: clearFieldError
  Purpose: Clears validation error for a form field
*/
function clearFieldError(fieldId) {
  const field = document.getElementById(fieldId);
  if (!field) return;

  // Remove error styling
  field.classList.remove('border-red-500', 'focus:ring-red-500');
  field.classList.add('border-gray-300', 'focus:ring-blue-500');

  // Remove error message
  const errorEl = document.getElementById(`${fieldId}-error`);
  if (errorEl) {
    errorEl.remove();
  }
  field.removeAttribute('aria-invalid');
  field.removeAttribute('aria-describedby');
}

/*
  Function Name: clearAllFieldErrors
  Purpose: Clears all validation errors in a form
*/
function clearAllFieldErrors(formId) {
  const form = document.getElementById(formId);
  if (!form) return;

  const errorMessages = form.querySelectorAll('[id$="-error"]');
  errorMessages.forEach(el => el.remove());

  const errorFields = form.querySelectorAll('.border-red-500');
  errorFields.forEach(field => {
    field.classList.remove('border-red-500', 'focus:ring-red-500');
    field.classList.add('border-gray-300', 'focus:ring-blue-500');
    field.removeAttribute('aria-invalid');
    field.removeAttribute('aria-describedby');
  });
}

// ============================================
// CACHING SYSTEM
// ============================================

const cache = new Map();

/*
  Function Name: getCached
  Purpose: Gets a cached value if it exists and isn't expired
*/
function getCached(key) {
  if (!CONFIG.CACHE_ENABLED) return null;
  
  const cached = cache.get(key);
  if (!cached) return null;
  
  if (Date.now() > cached.expiry) {
    cache.delete(key);
    return null;
  }
  
  return cached.data;
}

/*
  Function Name: setCache
  Purpose: Sets a value in the cache with TTL
*/
function setCache(key, data, ttl = CONFIG.CACHE_TTL) {
  if (!CONFIG.CACHE_ENABLED) return;
  
  cache.set(key, {
    data,
    expiry: Date.now() + ttl
  });
}

/*
  Function Name: clearCache
  Purpose: Clears specific cache key or all cache
*/
function clearCache(key = null) {
  if (key) {
    cache.delete(key);
  } else {
    cache.clear();
  }
}

// ============================================
// SESSION MANAGEMENT
// ============================================

let sessionCheckInterval = null;

/*
  Function Name: startSessionMonitor
  Purpose: Starts monitoring the session for expiry
*/
function startSessionMonitor() {
  if (sessionCheckInterval) return;

  sessionCheckInterval = setInterval(async () => {
    try {
      const { data: { session }, error } = await getSupabase().auth.getSession();
      
      if (error || !session) {
        handleSessionExpired();
        return;
      }

      // Check if session is about to expire
      const expiresAt = session.expires_at * 1000; // Convert to milliseconds
      const timeUntilExpiry = expiresAt - Date.now();

      if (timeUntilExpiry < CONFIG.SESSION_WARNING_BEFORE_EXPIRY && timeUntilExpiry > 0) {
        showToast('Your session will expire soon. Please save your work.', 'warning');
      }

      // Try to refresh if session is close to expiry
      if (timeUntilExpiry < CONFIG.SESSION_WARNING_BEFORE_EXPIRY) {
        const { error: refreshError } = await getSupabase().auth.refreshSession();
        if (refreshError) {
          console.error('Failed to refresh session:', refreshError);
        }
      }
    } catch (error) {
      console.error('Session check error:', error);
    }
  }, CONFIG.SESSION_CHECK_INTERVAL);
}

/*
  Function Name: stopSessionMonitor
  Purpose: Stops the session monitor
*/
function stopSessionMonitor() {
  if (sessionCheckInterval) {
    clearInterval(sessionCheckInterval);
    sessionCheckInterval = null;
  }
}

/*
  Function Name: handleSessionExpired
  Purpose: Handles session expiration
*/
function handleSessionExpired() {
  stopSessionMonitor();
  localStorage.removeItem('user');
  clearCache();
  
  showToast('Your session has expired. Please log in again.', 'warning');
  
  setTimeout(() => {
    window.location.href = 'login.html';
  }, 2000);
}

// ============================================
// PAGINATION HELPERS
// ============================================

/*
  Function Name: createPagination
  Purpose: Creates pagination UI and handles page changes
  
  Parameters:
  - containerId: ID of the container element
  - totalItems: Total number of items
  - currentPage: Current page number (1-indexed)
  - pageSize: Items per page
  - onPageChange: Callback function(pageNumber)
*/
function createPagination(containerId, totalItems, currentPage, pageSize, onPageChange) {
  const container = document.getElementById(containerId);
  if (!container) return;

  const totalPages = Math.ceil(totalItems / pageSize);
  
  if (totalPages <= 1) {
    container.innerHTML = '';
    return;
  }

  const startItem = (currentPage - 1) * pageSize + 1;
  const endItem = Math.min(currentPage * pageSize, totalItems);

  let html = `
    <div class="flex items-center justify-between px-4 py-3 bg-white border-t">
      <div class="text-sm text-gray-700">
        Showing <span class="font-medium">${startItem}</span> to <span class="font-medium">${endItem}</span> of <span class="font-medium">${totalItems}</span> results
      </div>
      <nav class="flex items-center gap-1" role="navigation" aria-label="Pagination">
  `;

  // Previous button
  html += `
    <button 
      ${currentPage === 1 ? 'disabled' : ''}
      onclick="window.paginationCallback_${containerId}(${currentPage - 1})"
      class="px-3 py-1 rounded-md ${currentPage === 1 ? 'text-gray-400 cursor-not-allowed' : 'text-gray-700 hover:bg-gray-100'}"
      aria-label="Previous page"
    >
      ← Previous
    </button>
  `;

  // Page numbers
  const maxVisiblePages = 5;
  let startPage = Math.max(1, currentPage - Math.floor(maxVisiblePages / 2));
  let endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);
  
  if (endPage - startPage + 1 < maxVisiblePages) {
    startPage = Math.max(1, endPage - maxVisiblePages + 1);
  }

  if (startPage > 1) {
    html += `<button onclick="window.paginationCallback_${containerId}(1)" class="px-3 py-1 rounded-md text-gray-700 hover:bg-gray-100">1</button>`;
    if (startPage > 2) {
      html += `<span class="px-2 text-gray-400">...</span>`;
    }
  }

  for (let i = startPage; i <= endPage; i++) {
    html += `
      <button 
        onclick="window.paginationCallback_${containerId}(${i})"
        class="px-3 py-1 rounded-md ${i === currentPage ? 'bg-blue-600 text-white' : 'text-gray-700 hover:bg-gray-100'}"
        ${i === currentPage ? 'aria-current="page"' : ''}
      >
        ${i}
      </button>
    `;
  }

  if (endPage < totalPages) {
    if (endPage < totalPages - 1) {
      html += `<span class="px-2 text-gray-400">...</span>`;
    }
    html += `<button onclick="window.paginationCallback_${containerId}(${totalPages})" class="px-3 py-1 rounded-md text-gray-700 hover:bg-gray-100">${totalPages}</button>`;
  }

  // Next button
  html += `
    <button 
      ${currentPage === totalPages ? 'disabled' : ''}
      onclick="window.paginationCallback_${containerId}(${currentPage + 1})"
      class="px-3 py-1 rounded-md ${currentPage === totalPages ? 'text-gray-400 cursor-not-allowed' : 'text-gray-700 hover:bg-gray-100'}"
      aria-label="Next page"
    >
      Next →
    </button>
  `;

  html += `</nav></div>`;

  container.innerHTML = html;

  // Store callback in window for button onclick
  window[`paginationCallback_${containerId}`] = onPageChange;
}

/*
  Function Name: paginateArray
  Purpose: Returns a slice of an array for the current page
*/
function paginateArray(array, page, pageSize = CONFIG.DEFAULT_PAGE_SIZE) {
  const start = (page - 1) * pageSize;
  return array.slice(start, start + pageSize);
}

// ============================================
// LOADING STATE HELPERS
// ============================================

/*
  Function Name: setButtonLoading
  Purpose: Sets a button to loading state
*/
function setButtonLoading(buttonId, loading = true, loadingText = 'Loading...') {
  const button = document.getElementById(buttonId);
  if (!button) return;

  if (loading) {
    button.dataset.originalText = button.innerHTML;
    button.disabled = true;
    button.innerHTML = `
      <span class="inline-flex items-center gap-2">
        <svg class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        ${loadingText}
      </span>
    `;
  } else {
    button.disabled = false;
    if (button.dataset.originalText) {
      button.innerHTML = button.dataset.originalText;
    }
  }
}

// ============================================
// ACCESSIBILITY HELPERS
// ============================================

/*
  Function Name: announceToScreenReader
  Purpose: Announces a message to screen readers
*/
function announceToScreenReader(message, priority = 'polite') {
  const announcement = document.createElement('div');
  announcement.setAttribute('aria-live', priority);
  announcement.setAttribute('aria-atomic', 'true');
  announcement.className = 'sr-only';
  announcement.textContent = message;
  
  document.body.appendChild(announcement);
  
  setTimeout(() => announcement.remove(), 1000);
}

/*
  Function Name: trapFocus
  Purpose: Traps focus within an element (for modals)
*/
function trapFocus(element) {
  const focusableElements = element.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  );
  const firstElement = focusableElements[0];
  const lastElement = focusableElements[focusableElements.length - 1];

  element.addEventListener('keydown', (e) => {
    if (e.key !== 'Tab') return;

    if (e.shiftKey) {
      if (document.activeElement === firstElement) {
        e.preventDefault();
        lastElement.focus();
      }
    } else {
      if (document.activeElement === lastElement) {
        e.preventDefault();
        firstElement.focus();
      }
    }
  });

  // Focus first element
  firstElement?.focus();
}

// ============================================
// NETWORK ERROR HANDLING
// ============================================

/*
  Function Name: handleNetworkError
  Purpose: Handles network errors with user-friendly messages
*/
function handleNetworkError(error) {
  console.error('Network error:', error);

  if (!navigator.onLine) {
    showToast('You appear to be offline. Please check your internet connection.', 'error');
    return;
  }

  if (error.message?.includes('Failed to fetch') || error.message?.includes('NetworkError')) {
    showToast('Unable to connect to the server. Please try again later.', 'error');
    return;
  }

  if (error.message?.includes('timeout')) {
    showToast('The request timed out. Please try again.', 'error');
    return;
  }

  showToast(error.message || 'An unexpected error occurred. Please try again.', 'error');
}

// Add CSS for screen reader only class
const srOnlyStyle = document.createElement('style');
srOnlyStyle.textContent = `
  .sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border-width: 0;
  }
`;
document.head.appendChild(srOnlyStyle);
