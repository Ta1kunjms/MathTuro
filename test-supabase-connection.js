// Test script to verify Supabase connection and table access
async function testSupabaseConnection() {
    console.log('=== Testing Supabase Connection ===');
    
    try {
        // Check if Supabase library is loaded
        if (!window.supabase || typeof window.supabase.createClient !== 'function') {
            console.error('❌ Supabase library not loaded');
            return;
        }
        
        // Check if config is loaded
        if (typeof CONFIG === 'undefined') {
            console.error('❌ Configuration not loaded');
            return;
        }
        
        console.log('✅ Supabase library and configuration loaded');
        
        // Initialize Supabase client
        const supabase = window.supabase.createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);
        console.log('✅ Supabase client created successfully');
        
        // Test connection by fetching some data with error handling
        console.log('\\n=== Testing Table Access ===');
        
        const tablesToCheck = ['users', 'modules', 'lessons', 'quiz_submissions'];
        
        for (const tableName of tablesToCheck) {
            try {
                console.log(`\\nChecking ${tableName} table...`);
                
                const { data, error, status } = await supabase
                    .from(tableName)
                    .select('*')
                    .limit(1);
                
                if (error) {
                    console.error(`❌ Error accessing ${tableName}:`, error.message);
                    console.error(`Status code: ${status}`);
                    
                    if (error.message.includes('permission denied')) {
                        console.error('🔒 This is likely an RLS policy issue. Check your table permissions.');
                    } else if (error.message.includes('does not exist')) {
                        console.error('📥 Table does not exist in the database.');
                    }
                } else {
                    console.log(`✅ Successfully accessed ${tableName}`);
                    if (data) {
                        console.log(`🔍 Found ${data.length} record(s)`);
                    }
                }
            } catch (err) {
                console.error(`❌ Exception accessing ${tableName}:`, err.message);
            }
        }
        
        console.log('\\n=== Connection Test Complete ===');
        
    } catch (error) {
        console.error('❌ Fatal error:', error.message);
    }
}

// Run the test
testSupabaseConnection();