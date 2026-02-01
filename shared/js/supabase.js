/*
  File: supabase.js
  Purpose:
  - Initializes the Supabase client
  - Provides access to the Supabase client throughout the application

  Dependencies:
  - config.js - for Supabase URL and anonymous key
  - Supabase JS CDN library must be loaded before this file
*/

// Defensive: Check if the Supabase library is loaded
if (!window.supabase || typeof window.supabase.createClient !== 'function') {
  console.error('Supabase library is not loaded. Please check your CDN script include.');
  throw new Error('Supabase library is not loaded.');
}

// Defensive: Check if config is loaded
if (typeof CONFIG === 'undefined' || !CONFIG.SUPABASE_URL || !CONFIG.SUPABASE_ANON_KEY) {
  console.error('Configuration not loaded. Please ensure config.js is loaded before supabase.js');
  throw new Error('Configuration not loaded.');
}

// Use a different variable name to avoid redeclaration
const supabaseClient = window.supabase.createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

function getSupabase() {
  return supabaseClient;
}
