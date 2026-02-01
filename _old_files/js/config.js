/*
  File: config.js
  Purpose:
  - Centralized configuration for the application
  - Supabase credentials and settings
  - Environment-specific configurations

  Note: In production, these values should be loaded from environment variables
  or a secure configuration service. For client-side apps, the anon key is safe
  to expose as it's designed for public access with RLS policies.
*/

const CONFIG = {
  // Supabase Configuration
  // Replace these with your actual Supabase project credentials
  SUPABASE_URL: 'https://ynkzcybctsstpqxdoweq.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlua3pjeWJjdHNzdHBxeGRvd2VxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk4NzI1NjAsImV4cCI6MjA4NTQ0ODU2MH0.ZXdFcLmSmgaikZrA9MpP6d9enp4rjz_9nuiTpwm9n2k',

  // Application Settings
  APP_NAME: 'Learning Management System',
  APP_VERSION: '1.0.0',

  // Session Settings
  SESSION_CHECK_INTERVAL: 5 * 60 * 1000, // Check session every 5 minutes
  SESSION_WARNING_BEFORE_EXPIRY: 5 * 60 * 1000, // Warn 5 minutes before expiry

  // Pagination Settings
  DEFAULT_PAGE_SIZE: 10,
  MAX_PAGE_SIZE: 100,

  // File Upload Settings
  MAX_SCREENSHOT_SIZE: 5 * 1024 * 1024, // 5MB
  MAX_MATERIAL_SIZE: 10 * 1024 * 1024, // 10MB
  ALLOWED_IMAGE_TYPES: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
  ALLOWED_DOCUMENT_TYPES: [
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain'
  ],

  // Cache Settings
  CACHE_TTL: 5 * 60 * 1000, // 5 minutes
  CACHE_ENABLED: true,

  // Validation Settings
  MIN_PASSWORD_LENGTH: 6,
  MAX_NAME_LENGTH: 100,
  MAX_TITLE_LENGTH: 200,
  MAX_DESCRIPTION_LENGTH: 2000,
  MAX_CONTENT_LENGTH: 50000,

  // Toast Notification Settings
  TOAST_DURATION: 5000, // 5 seconds
  TOAST_POSITION: 'top-right'
};

// Freeze the config object to prevent modifications
Object.freeze(CONFIG);
