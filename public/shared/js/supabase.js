/*
  File: supabase.js
  Purpose:
  - Initializes the Supabase client
  - Provides access to the Supabase client throughout the application

  Dependencies:
  - config.js - for Supabase URL and anonymous key
  - Supabase JS CDN library must be loaded before this file
*/

// Initialize supabaseClient as null, will be set when ready
let supabaseClient = null;

// Initialize Supabase when called
function initSupabase() {
  if (supabaseClient) return supabaseClient;
  
  // Check if the Supabase library is loaded
  if (!window.supabase || typeof window.supabase.createClient !== 'function') {
    console.error('Supabase library is not loaded. Please check your CDN script include.');
    return null;
  }

  // Check if config is loaded
  if (typeof CONFIG === 'undefined' || !CONFIG.SUPABASE_URL || !CONFIG.SUPABASE_ANON_KEY) {
    console.error('Configuration not loaded. Please ensure config.js is loaded before supabase.js');
    return null;
  }

  supabaseClient = window.supabase.createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);
  return supabaseClient;
}

function getSupabase() {
  if (!supabaseClient) {
    supabaseClient = initSupabase();
  }
  return supabaseClient;
}

// Try to initialize immediately
try {
  initSupabase();
} catch (e) {
  console.warn('Supabase initialization delayed:', e.message);
}
