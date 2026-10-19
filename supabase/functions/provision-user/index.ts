import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

function response(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return response({ error: 'Method not allowed' }, 405);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const authorization = request.headers.get('Authorization');

  if (!supabaseUrl || !serviceRoleKey || !authorization) {
    return response({ error: 'Provisioning service is not configured' }, 500);
  }

  const userClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY') ?? '', {
    global: { headers: { Authorization: authorization } }
  });
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  const { data: { user: requester }, error: requesterError } = await userClient.auth.getUser();
  if (requesterError || !requester) {
    return response({ error: 'Authentication required' }, 401);
  }

  const { data: requesterProfile, error: profileError } = await adminClient
    .from('users')
    .select('role, is_active, approval_status')
    .eq('id', requester.id)
    .single();

  if (profileError || requesterProfile?.role !== 'admin' || !requesterProfile.is_active || requesterProfile.approval_status !== 'approved') {
    return response({ error: 'Only active administrators may provision accounts' }, 403);
  }

  let input: Record<string, string>;
  try {
    input = await request.json();
  } catch {
    return response({ error: 'Invalid JSON request body' }, 400);
  }

  const email = String(input.email || '').trim().toLowerCase();
  const password = String(input.password || '');
  const role = String(input.role || '');
  const firstName = String(input.first_name || '').trim();
  const lastName = String(input.last_name || '').trim();
  const lrn = String(input.lrn || '').trim();
  const schoolYear = String(input.school_year || '').trim();
  const gender = String(input.gender || '').trim();
  const gradeLevelId = input.grade_level_id || null;
  const sectionId = input.section_id || null;

  if (!email || !password || password.length < 6 || !['student', 'teacher'].includes(role)) {
    return response({ error: 'Valid email, password, and student/teacher role are required' }, 400);
  }
  if (!firstName || !lastName || !/^\d{12}$/.test(lrn) || !/^S\.Y\. 20\d{2}-20\d{2}$/.test(schoolYear) || !['Male', 'Female'].includes(gender)) {
    return response({ error: 'First name, last name, 12-digit LRN, school year, and gender are required' }, 400);
  }

  const { data: createdAuth, error: authError } = await adminClient.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: {
      first_name: firstName,
      last_name: lastName,
      full_name: `${firstName} ${lastName}`,
      lrn,
      school_year: schoolYear,
      gender,
      grade_level_id: gradeLevelId,
      section_id: sectionId
    }
  });

  if (authError || !createdAuth.user) {
    return response({ error: authError?.message || 'Failed to create Auth user' }, 400);
  }

  const { data: profile, error: upsertError } = await adminClient
    .from('users')
    .upsert({
      id: createdAuth.user.id,
      email,
      first_name: firstName,
      last_name: lastName,
      full_name: `${firstName} ${lastName}`,
      role,
      lrn,
      school_year: schoolYear,
      gender,
      grade_level_id: gradeLevelId,
      section_id: sectionId,
      approval_status: 'approved',
      is_active: true,
      approved_at: new Date().toISOString(),
      approved_by: requester.id,
      updated_at: new Date().toISOString()
    }, { onConflict: 'id' })
    .select('id, email, first_name, last_name, role, approval_status, is_active')
    .single();

  if (upsertError || !profile) {
    await adminClient.auth.admin.deleteUser(createdAuth.user.id);
    return response({ error: upsertError?.message || 'Failed to create approved profile' }, 500);
  }

  await adminClient.from('activity_log').insert({
    user_id: requester.id,
    action: 'provision_account',
    entity_type: 'user',
    entity_id: createdAuth.user.id,
    details: { role, email }
  });

  return response({ user: profile }, 201);
});
