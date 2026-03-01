// Test script to check Supabase connection and grade levels/sections
// Run this with: node test-supabase.js

const { createClient } = require('@supabase/supabase-js');

// Configuration
const SUPABASE_URL = 'https://ynkzcybctsstpqxdoweq.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlua3pjeWJjdHNzdHBxeGRvd2VxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk4NzI1NjAsImV4cCI6MjA4NTQ0ODU2MH0.ZXdFcLmSmgaikZrA9MpP6d9enp4rjz_9nuiTpwm9n2k';

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testConnection() {
    console.log('Testing Supabase connection...');
    try {
        const { data, error } = await supabase
            .from('grade_levels')
            .select('*')
            .order('name');

        if (error) {
            console.error('❌ Error connecting to Supabase:', error);
            return false;
        }

        console.log(`✅ Connected successfully! Found ${data.length} grade levels.`);
        return true;
    } catch (error) {
        console.error('❌ Connection error:', error);
        return false;
    }
}

async function testSectionsQuery() {
    console.log('\nTesting sections query...');
    try {
        const { data, error } = await supabase
            .from('sections')
            .select(`
                *,
                grade_levels!sections_grade_level_id_fkey (
                    id,
                    name
                )
            `)
            .order('name');

        if (error) {
            console.error('❌ Error fetching sections:', error);
            return false;
        }

        console.log(`✅ Found ${data.length} sections.`);
        
        // Log section details
        data.forEach(section => {
            console.log(`  - ${section.name} (Grade: ${section.grade_levels?.name || 'N/A'})`);
        });

        return true;
    } catch (error) {
        console.error('❌ Sections query error:', error);
        return false;
    }
}

async function main() {
    console.log('=== MathTuro LMS - Grade Levels & Sections Test ===\n');

    const connected = await testConnection();
    if (!connected) {
        console.error('❌ Failed to connect to Supabase');
        process.exit(1);
    }

    const sectionsFound = await testSectionsQuery();
    if (!sectionsFound) {
        console.error('❌ Failed to fetch sections');
        process.exit(1);
    }

    console.log('\n✅ All tests passed!');
}

main().catch(error => {
    console.error('❌ Uncaught error:', error);
    process.exit(1);
});