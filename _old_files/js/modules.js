/*
  File: modules.js
  Purpose:
  - Handles all module and lesson-related functionality
  - Manages module and lesson data retrieval
  - Provides functions for CRUD operations on modules and lessons
  - Used by both students (viewing) and teachers (managing)

  Dependencies:
  - supabase.js - for Supabase client connection
  - auth.js - for authentication checks
*/

/*
  Function Name: getModules
  Purpose:
  - Retrieves all modules from the database
  - Optional filter by active status
  - Returns modules sorted by order

  When it runs:
  - Called when student views modules page
  - Called when teacher views modules management page
  - Called when admin views modules management page

  Who can use it:
  - Student / Teacher / Admin

  Backend interaction:
  - Reads from modules table
  - Orders by order ascending
  - Optional filter by is_active column

  Error handling:
  - Returns empty array if no modules found
  - Logs errors to console
*/
async function getModules(activeOnly = true) {
  try {
    let query = getSupabase()
      .from('modules')
      .select('*')
      .order('order_index', { ascending: true });

    if (activeOnly) {
      query = query.eq('status', 'published');
    }

    const { data, error } = await query;

    if (error) {
      console.error('Error loading modules:', error);
      return [];
    }

    return data;

  } catch (error) {
    console.error('Error getting modules:', error);
    return [];
  }
}

/*
  Function Name: getModuleById
  Purpose:
  - Retrieves a single module by ID
  - Returns module with all associated lessons

  When it runs:
  - Called when student views module details page
  - Called when teacher edits a module
  - Called when admin views module details

  Who can use it:
  - Student / Teacher / Admin

  Backend interaction:
  - Reads from modules table by ID
  - Reads associated lessons from lessons table
  - Orders lessons by order ascending

  Error handling:
  - Returns null if module not found
  - Logs errors to console
*/
async function getModuleById(moduleId) {
  try {
    // Get module details
    const { data: module, error: moduleError } = await getSupabase()
      .from('modules')
      .select('*')
      .eq('id', moduleId)
      .single();

    if (moduleError) {
      if (moduleError.code === 'PGRST116') { // No rows returned
        return null;
      }
      console.error('Error loading module:', moduleError);
      return null;
    }

    // Get associated lessons
    const { data: lessons, error: lessonsError } = await getSupabase()
      .from('lessons')
      .select('*')
      .eq('module_id', moduleId)
      .order('order_index', { ascending: true });

    if (lessonsError) {
      console.error('Error loading lessons:', lessonsError);
      return null;
    }

    return {
      ...module,
      lessons: lessons
    };

  } catch (error) {
    console.error('Error getting module by ID:', error);
    return null;
  }
}

/*
  Function Name: getLessonById
  Purpose:
  - Retrieves a single lesson by ID
  - Returns lesson with associated module information

  When it runs:
  - Called when student views lesson details page
  - Called when teacher edits a lesson
  - Called when admin views lesson details

  Who can use it:
  - Student / Teacher / Admin

  Backend interaction:
  - Reads from lessons table by ID
  - Joins with modules table to get module details

  Error handling:
  - Returns null if lesson not found
  - Logs errors to console
*/
async function getLessonById(lessonId) {
  try {
    const { data, error } = await getSupabase()
      .from('lessons')
      .select('*, modules(title)')
      .eq('id', lessonId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') { // No rows returned
        return null;
      }
      console.error('Error loading lesson:', error);
      return null;
    }

    return data;

  } catch (error) {
    console.error('Error getting lesson by ID:', error);
    return null;
  }
}

/*
  Function Name: createModule
  Purpose:
  - Creates a new module in the database
  - Sets initial order based on existing modules
  - Requires teacher or admin role

  When it runs:
  - Called when teacher creates a new module
  - Called when admin creates a new module

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Inserts into modules table
  - Sets default values for is_active and created_at

  Error handling:
  - Validates user role
  - Validates module data
  - Handles database insertion errors
  - Shows alert for errors
*/
async function createModule(moduleData) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      if (typeof showToast === 'function') showToast('You do not have permission to create modules', 'error');
      return null;
    }

    // Validate module data
    if (!moduleData.title || !moduleData.description) {
      if (typeof showToast === 'function') showToast('Module title and description are required', 'error');
      return null;
    }

    // Get next order number
    const { data: modules, error: countError } = await getSupabase()
      .from('modules')
      .select('order_index')
      .order('order_index', { ascending: false })
      .limit(1);

    if (countError) {
      console.error('Error getting module count:', countError);
      return null;
    }

    const nextOrder = modules.length > 0 ? modules[0].order_index + 1 : 1;

    // Create module
    const { data, error } = await getSupabase()
      .from('modules')
      .insert({
        title: moduleData.title,
        description: moduleData.description,
        order_index: nextOrder,
        status: 'draft',
        teacher_id: user.id,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select('*')
      .single();

    if (error) {
      console.error('Error creating module:', error);
      if (typeof showToast === 'function') showToast('Failed to create module: ' + error.message, 'error');
      return null;
    }

    return data;

  } catch (error) {
    console.error('Error creating module:', error);
    if (typeof showToast === 'function') showToast('Failed to create module. Please try again.', 'error');
    return null;
  }
}

/*
  Function Name: updateModule
  Purpose:
  - Updates an existing module
  - Requires teacher or admin role

  When it runs:
  - Called when teacher edits a module
  - Called when admin edits a module

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Updates existing module record in modules table
  - Sets updated_at timestamp

  Error handling:
  - Validates user role
  - Validates module data
  - Handles database update errors
  - Shows alert for errors
*/
async function updateModule(moduleId, moduleData) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      if (typeof showToast === 'function') showToast('You do not have permission to update modules', 'error');
      return false;
    }

    // Validate module data
    if (!moduleData.title || !moduleData.description) {
      if (typeof showToast === 'function') showToast('Module title and description are required', 'error');
      return false;
    }

    // Update module
    const { error } = await getSupabase()
      .from('modules')
      .update({
        title: moduleData.title,
        description: moduleData.description,
        status: moduleData.status ?? 'draft',
        order_index: moduleData.order_index,
        updated_at: new Date().toISOString()
      })
      .eq('id', moduleId);

    if (error) {
      console.error('Error updating module:', error);
      if (typeof showToast === 'function') showToast('Failed to update module: ' + error.message, 'error');
      return false;
    }

    return true;

  } catch (error) {
    console.error('Error updating module:', error);
    if (typeof showToast === 'function') showToast('Failed to update module. Please try again.', 'error');
    return false;
  }
}

/*
  Function Name: deleteModule
  Purpose:
  - Deletes a module from the database
  - Requires teacher or admin role

  When it runs:
  - Called when teacher deletes a module
  - Called when admin deletes a module

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Deletes module from modules table
  - Also deletes all associated lessons from lessons table

  Error handling:
  - Validates user role
  - Handles database deletion errors
  - Shows alert for errors
*/
async function deleteModule(moduleId) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      if (typeof showToast === 'function') showToast('You do not have permission to delete modules', 'error');
      return false;
    }

    // Delete associated lessons first (cascade delete)
    const { error: lessonsError } = await getSupabase()
      .from('lessons')
      .delete()
      .eq('module_id', moduleId);

    if (lessonsError) {
      console.error('Error deleting lessons:', lessonsError);
      if (typeof showToast === 'function') showToast('Failed to delete module: ' + lessonsError.message, 'error');
      return false;
    }

    // Delete module
    const { error: moduleError } = await getSupabase()
      .from('modules')
      .delete()
      .eq('id', moduleId);

    if (moduleError) {
      console.error('Error deleting module:', moduleError);
      if (typeof showToast === 'function') showToast('Failed to delete module: ' + moduleError.message, 'error');
      return false;
    }

    return true;

  } catch (error) {
    console.error('Error deleting module:', error);
    if (typeof showToast === 'function') showToast('Failed to delete module. Please try again.', 'error');
    return false;
  }
}

/*
  Function Name: createLesson
  Purpose:
  - Creates a new lesson in a specific module
  - Requires teacher or admin role

  When it runs:
  - Called when teacher creates a new lesson
  - Called when admin creates a new lesson

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Inserts into lessons table
  - Sets default values for created_at and updated_at

  Error handling:
  - Validates user role
  - Validates lesson data
  - Handles database insertion errors
  - Shows alert for errors
*/
async function createLesson(moduleId, lessonData) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      if (typeof showToast === 'function') showToast('You do not have permission to create lessons', 'error');
      return null;
    }

    // Validate lesson data
    if (!lessonData.title || !lessonData.content) {
      if (typeof showToast === 'function') showToast('Lesson title and content are required', 'error');
      return null;
    }

    // Get next order number for the module
    const { data: lessons, error: countError } = await getSupabase()
      .from('lessons')
      .select('order_index')
      .eq('module_id', moduleId)
      .order('order_index', { ascending: false })
      .limit(1);

    if (countError) {
      console.error('Error getting lesson count:', countError);
      return null;
    }

    const nextOrder = lessons.length > 0 ? lessons[0].order_index + 1 : 1;

    // Create lesson
    const { data, error } = await getSupabase()
      .from('lessons')
      .insert({
        module_id: moduleId,
        title: lessonData.title,
        content: lessonData.content,
        order_index: nextOrder,
        video_url: lessonData.video_url,
        has_quiz: lessonData.has_quiz || false,
        quiz_data: lessonData.quiz_data || null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select('*')
      .single();

    if (error) {
      console.error('Error creating lesson:', error);
      if (typeof showToast === 'function') showToast('Failed to create lesson: ' + error.message, 'error');
      return null;
    }

    return data;

  } catch (error) {
    console.error('Error creating lesson:', error);
    if (typeof showToast === 'function') showToast('Failed to create lesson. Please try again.', 'error');
    return null;
  }
}

/*
  Function Name: updateLesson
  Purpose:
  - Updates an existing lesson
  - Requires teacher or admin role

  When it runs:
  - Called when teacher edits a lesson
  - Called when admin edits a lesson

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Updates existing lesson record in lessons table
  - Sets updated_at timestamp

  Error handling:
  - Validates user role
  - Validates lesson data
  - Handles database update errors
  - Shows alert for errors
*/
async function updateLesson(lessonId, lessonData) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      if (typeof showToast === 'function') showToast('You do not have permission to update lessons', 'error');
      return false;
    }

    // Validate lesson data
    if (!lessonData.title || !lessonData.content) {
      if (typeof showToast === 'function') showToast('Lesson title and content are required', 'error');
      return false;
    }

    // Update lesson
    const { error } = await getSupabase()
      .from('lessons')
      .update({
        title: lessonData.title,
        content: lessonData.content,
        video_url: lessonData.video_url,
        has_quiz: lessonData.has_quiz,
        quiz_data: lessonData.quiz_data,
        order_index: lessonData.order_index,
        updated_at: new Date().toISOString()
      })
      .eq('id', lessonId);

    if (error) {
      console.error('Error updating lesson:', error);
      if (typeof showToast === 'function') showToast('Failed to update lesson: ' + error.message, 'error');
      return false;
    }

    return true;

  } catch (error) {
    console.error('Error updating lesson:', error);
    if (typeof showToast === 'function') showToast('Failed to update lesson. Please try again.', 'error');
    return false;
  }
}

/*
  Function Name: deleteLesson
  Purpose:
  - Deletes a lesson from the database
  - Requires teacher or admin role

  When it runs:
  - Called when teacher deletes a lesson
  - Called when admin deletes a lesson

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Deletes lesson from lessons table
  - Also deletes associated lesson_progress and quiz_submissions

  Error handling:
  - Validates user role
  - Handles database deletion errors
  - Shows alert for errors
*/
async function deleteLesson(lessonId) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      if (typeof showToast === 'function') showToast('You do not have permission to delete lessons', 'error');
      return false;
    }

    // Delete associated lesson progress
    const { error: progressError } = await getSupabase()
      .from('lesson_progress')
      .delete()
      .eq('lesson_id', lessonId);

    if (progressError) {
      console.error('Error deleting lesson progress:', progressError);
    }

    // Delete associated quiz submissions
    const { error: submissionsError } = await getSupabase()
      .from('quiz_submissions')
      .delete()
      .eq('lesson_id', lessonId);

    if (submissionsError) {
      console.error('Error deleting quiz submissions:', submissionsError);
    }

    // Delete lesson
    const { error: lessonError } = await getSupabase()
      .from('lessons')
      .delete()
      .eq('id', lessonId);

    if (lessonError) {
      console.error('Error deleting lesson:', lessonError);
      if (typeof showToast === 'function') showToast('Failed to delete lesson: ' + lessonError.message, 'error');
      return false;
    }

    return true;

  } catch (error) {
    console.error('Error deleting lesson:', error);
    if (typeof showToast === 'function') showToast('Failed to delete lesson. Please try again.', 'error');
    return false;
  }
}
