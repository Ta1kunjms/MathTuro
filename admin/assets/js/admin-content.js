/*
  File: admin-content.js
  Purpose:
  - Contains all admin-specific content management functionality
  - Manages modules, videos, quizzes, and lesson plans
  - Provides access to all content regardless of owner
  - Handles content creation, editing, deletion, and archiving

  Dependencies:
  - supabase.js - for Supabase client connection
  - auth.js - for authentication checks
  - utils.js - for utility functions (showNotification, uploadFile)
*/

/*
  ADMIN-SPECIFIC CONTENT MANAGEMENT FUNCTIONS
  These functions allow admin to view and manage ALL content,
  regardless of which teacher created it.
*/

// ============================================
// MODULE MANAGEMENT
// ============================================

async function getAllModules() {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to access this content', 'error');
      return [];
    }

    const { data, error } = await getSupabase()
      .from('modules')
      .select(`
        *,
        teacher:teacher_id (id, full_name)
      `)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error loading modules:', error);
      showNotification('Failed to load modules', 'error');
      return [];
    }

    return data;

  } catch (error) {
    console.error('Error getting all modules:', error);
    showNotification('Failed to load modules', 'error');
    return [];
  }
}

async function createModule(moduleData) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to create modules', 'error');
      return null;
    }

    const { data, error } = await getSupabase()
      .from('modules')
      .insert({
        ...moduleData,
        created_by: user.id,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      console.error('Error creating module:', error);
      showNotification('Failed to create module', 'error');
      return null;
    }

    showNotification('Module created successfully', 'success');
    return data;

  } catch (error) {
    console.error('Error creating module:', error);
    showNotification('Failed to create module', 'error');
    return null;
  }
}

async function updateModule(moduleId, updates) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to update modules', 'error');
      return null;
    }

    const { data, error } = await getSupabase()
      .from('modules')
      .update({
        ...updates,
        updated_at: new Date().toISOString()
      })
      .eq('id', moduleId)
      .select()
      .single();

    if (error) {
      console.error('Error updating module:', error);
      showNotification('Failed to update module', 'error');
      return null;
    }

    showNotification('Module updated successfully', 'success');
    return data;

  } catch (error) {
    console.error('Error updating module:', error);
    showNotification('Failed to update module', 'error');
    return null;
  }
}

async function deleteModule(moduleId) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to delete modules', 'error');
      return false;
    }

    const { error } = await getSupabase()
      .from('modules')
      .delete()
      .eq('id', moduleId);

    if (error) {
      console.error('Error deleting module:', error);
      showNotification('Failed to delete module', 'error');
      return false;
    }

    showNotification('Module deleted successfully', 'success');
    return true;

  } catch (error) {
    console.error('Error deleting module:', error);
    showNotification('Failed to delete module', 'error');
    return false;
  }
}

// ============================================
// VIDEO MANAGEMENT
// ============================================

async function getAllVideos() {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to access this content', 'error');
      return [];
    }

    const { data, error } = await getSupabase()
      .from('videos')
      .select(`
        *,
        teacher:teacher_id (id, full_name),
        module:module_id (id, title)
      `)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error loading videos:', error);
      showNotification('Failed to load videos', 'error');
      return [];
    }

    return data;

  } catch (error) {
    console.error('Error getting all videos:', error);
    showNotification('Failed to load videos', 'error');
    return [];
  }
}

async function createVideo(videoData) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to create videos', 'error');
      return null;
    }

    const { data, error } = await getSupabase()
      .from('videos')
      .insert({
        ...videoData,
        created_by: user.id,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      console.error('Error creating video:', error);
      showNotification('Failed to create video', 'error');
      return null;
    }

    showNotification('Video created successfully', 'success');
    return data;

  } catch (error) {
    console.error('Error creating video:', error);
    showNotification('Failed to create video', 'error');
    return null;
  }
}

async function updateVideo(videoId, updates) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to update videos', 'error');
      return null;
    }

    const { data, error } = await getSupabase()
      .from('videos')
      .update({
        ...updates,
        updated_at: new Date().toISOString()
      })
      .eq('id', videoId)
      .select()
      .single();

    if (error) {
      console.error('Error updating video:', error);
      showNotification('Failed to update video', 'error');
      return null;
    }

    showNotification('Video updated successfully', 'success');
    return data;

  } catch (error) {
    console.error('Error updating video:', error);
    showNotification('Failed to update video', 'error');
    return null;
  }
}

async function deleteVideo(videoId) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to delete videos', 'error');
      return false;
    }

    const { error } = await getSupabase()
      .from('videos')
      .delete()
      .eq('id', videoId);

    if (error) {
      console.error('Error deleting video:', error);
      showNotification('Failed to delete video', 'error');
      return false;
    }

    showNotification('Video deleted successfully', 'success');
    return true;

  } catch (error) {
    console.error('Error deleting video:', error);
    showNotification('Failed to delete video', 'error');
    return false;
  }
}

// ============================================
// QUIZ MANAGEMENT
// ============================================

async function getAllQuizzes() {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to access this content', 'error');
      return [];
    }

    const { data, error } = await getSupabase()
      .from('quizzes')
      .select(`
        *,
        teacher:teacher_id (id, full_name),
        module:module_id (id, title),
        video:video_id (id, title)
      `)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error loading quizzes:', error);
      showNotification('Failed to load quizzes', 'error');
      return [];
    }

    return data;

  } catch (error) {
    console.error('Error getting all quizzes:', error);
    showNotification('Failed to load quizzes', 'error');
    return [];
  }
}

async function createQuiz(quizData) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to create quizzes', 'error');
      return null;
    }

    const { data, error } = await getSupabase()
      .from('quizzes')
      .insert({
        ...quizData,
        created_by: user.id,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      console.error('Error creating quiz:', error);
      showNotification('Failed to create quiz', 'error');
      return null;
    }

    showNotification('Quiz created successfully', 'success');
    return data;

  } catch (error) {
    console.error('Error creating quiz:', error);
    showNotification('Failed to create quiz', 'error');
    return null;
  }
}

async function updateQuiz(quizId, updates) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to update quizzes', 'error');
      return null;
    }

    const { data, error } = await getSupabase()
      .from('quizzes')
      .update({
        ...updates,
        updated_at: new Date().toISOString()
      })
      .eq('id', quizId)
      .select()
      .single();

    if (error) {
      console.error('Error updating quiz:', error);
      showNotification('Failed to update quiz', 'error');
      return null;
    }

    showNotification('Quiz updated successfully', 'success');
    return data;

  } catch (error) {
    console.error('Error updating quiz:', error);
    showNotification('Failed to update quiz', 'error');
    return null;
  }
}

async function deleteQuiz(quizId) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to delete quizzes', 'error');
      return false;
    }

    const { error } = await getSupabase()
      .from('quizzes')
      .delete()
      .eq('id', quizId);

    if (error) {
      console.error('Error deleting quiz:', error);
      showNotification('Failed to delete quiz', 'error');
      return false;
    }

    showNotification('Quiz deleted successfully', 'success');
    return true;

  } catch (error) {
    console.error('Error deleting quiz:', error);
    showNotification('Failed to delete quiz', 'error');
    return false;
  }
}

// ============================================
// LESSON PLAN MANAGEMENT
// ============================================

const LESSON_PLAN_TABLE = 'lesson_plan_files';
const LESSON_PLAN_BUCKET = 'lesson-plans';

function normalizeLessonPlanRow(row) {
  if (!row) return null;

  return {
    ...row,
    title: row.file_name,
    teacher_id: row.user_id,
    teacher: row.teacher || row.uploader || null,
    status: 'active',
    created_at: row.uploaded_at,
    updated_at: row.uploaded_at,
    grade_level: row.grade_level || null
  };
}

async function getAllLessonPlans() {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to access this content', 'error');
      return [];
    }

    const { data, error } = await getSupabase()
      .from(LESSON_PLAN_TABLE)
      .select(`
        id,
        user_id,
        file_name,
        file_path,
        file_url,
        file_type,
        file_size,
        description,
        module_name,
        lesson_name,
        period_type,
        period_value,
        uploaded_at,
        teacher:user_id (id, full_name, email)
      `)
      .order('uploaded_at', { ascending: false });

    if (error) {
      console.error('Error loading lesson plans:', error);
      showNotification('Failed to load lesson plans', 'error');
      return [];
    }

    return (data || []).map(normalizeLessonPlanRow);

  } catch (error) {
    console.error('Error getting all lesson plans:', error);
    showNotification('Failed to load lesson plans', 'error');
    return [];
  }
}

async function createLessonPlan(lessonPlanData) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to create lesson plans', 'error');
      return null;
    }

    const payload = {
      user_id: lessonPlanData.user_id || lessonPlanData.teacher_id || user.id,
      file_name: lessonPlanData.file_name || lessonPlanData.title,
      file_path: lessonPlanData.file_path,
      file_url: lessonPlanData.file_url,
      file_type: lessonPlanData.file_type || null,
      file_size: lessonPlanData.file_size || null,
      description: lessonPlanData.description || '',
      module_name: lessonPlanData.module_name || null,
      lesson_name: lessonPlanData.lesson_name || null,
      period_type: lessonPlanData.period_type || null,
      period_value: lessonPlanData.period_value || null,
      uploaded_at: new Date().toISOString()
    };

    if (!payload.file_name || !payload.file_path || !payload.file_url) {
      showNotification('Lesson plan file name, path, and URL are required', 'error');
      return null;
    }

    const { data, error } = await getSupabase()
      .from(LESSON_PLAN_TABLE)
      .insert(payload)
      .select()
      .single();

    if (error) {
      console.error('Error creating lesson plan:', error);
      showNotification('Failed to create lesson plan', 'error');
      return null;
    }

    showNotification('Lesson plan created successfully', 'success');
    return normalizeLessonPlanRow(data);

  } catch (error) {
    console.error('Error creating lesson plan:', error);
    showNotification('Failed to create lesson plan', 'error');
    return null;
  }
}

async function updateLessonPlan(lessonPlanId, updates) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to update lesson plans', 'error');
      return null;
    }

    const mappedUpdates = {};

    if (typeof updates.title !== 'undefined') mappedUpdates.file_name = updates.title;
    if (typeof updates.file_name !== 'undefined') mappedUpdates.file_name = updates.file_name;
    if (typeof updates.description !== 'undefined') mappedUpdates.description = updates.description;
    if (typeof updates.module_name !== 'undefined') mappedUpdates.module_name = updates.module_name;
    if (typeof updates.lesson_name !== 'undefined') mappedUpdates.lesson_name = updates.lesson_name;
    if (typeof updates.period_type !== 'undefined') mappedUpdates.period_type = updates.period_type;
    if (typeof updates.period_value !== 'undefined') mappedUpdates.period_value = updates.period_value;
    if (typeof updates.file_path !== 'undefined') mappedUpdates.file_path = updates.file_path;
    if (typeof updates.file_url !== 'undefined') mappedUpdates.file_url = updates.file_url;
    if (typeof updates.file_type !== 'undefined') mappedUpdates.file_type = updates.file_type;
    if (typeof updates.file_size !== 'undefined') mappedUpdates.file_size = updates.file_size;
    if (typeof updates.teacher_id !== 'undefined') mappedUpdates.user_id = updates.teacher_id;
    if (typeof updates.user_id !== 'undefined') mappedUpdates.user_id = updates.user_id;

    if (Object.keys(mappedUpdates).length === 0) {
      showNotification('No valid lesson plan fields to update', 'warning');
      return null;
    }

    const { data, error } = await getSupabase()
      .from(LESSON_PLAN_TABLE)
      .update(mappedUpdates)
      .eq('id', lessonPlanId)
      .select()
      .single();

    if (error) {
      console.error('Error updating lesson plan:', error);
      showNotification('Failed to update lesson plan', 'error');
      return null;
    }

    showNotification('Lesson plan updated successfully', 'success');
    return normalizeLessonPlanRow(data);

  } catch (error) {
    console.error('Error updating lesson plan:', error);
    showNotification('Failed to update lesson plan', 'error');
    return null;
  }
}

async function deleteLessonPlan(lessonPlanId) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to delete lesson plans', 'error');
      return false;
    }

    const { data: lessonPlan, error: fetchError } = await getSupabase()
      .from(LESSON_PLAN_TABLE)
      .select('file_path')
      .eq('id', lessonPlanId)
      .single();

    if (fetchError) {
      console.error('Error fetching lesson plan:', fetchError);
      return false;
    }

    if (lessonPlan.file_path) {
      const { error: storageError } = await getSupabase()
        .storage
        .from(LESSON_PLAN_BUCKET)
        .remove([lessonPlan.file_path]);
      
      if (storageError) {
        console.warn('Failed to delete storage file:', storageError);
      }
    }

    const { error: deleteError } = await getSupabase()
      .from(LESSON_PLAN_TABLE)
      .delete()
      .eq('id', lessonPlanId);

    if (deleteError) {
      console.error('Error deleting lesson plan:', deleteError);
      showNotification('Failed to delete lesson plan', 'error');
      return false;
    }

    showNotification('Lesson plan deleted successfully', 'success');
    return true;

  } catch (error) {
    console.error('Error deleting lesson plan:', error);
    showNotification('Failed to delete lesson plan', 'error');
    return false;
  }
}

// ============================================
// CONTENT ARCHIVING (SOFT DELETE)
// ============================================

async function archiveModule(moduleId) {
  return updateModule(moduleId, { status: 'archived' });
}

async function archiveVideo(videoId) {
  return updateVideo(videoId, { status: 'archived' });
}

async function archiveQuiz(quizId) {
  return updateQuiz(quizId, { status: 'archived' });
}

async function archiveLessonPlan(lessonPlanId) {
  showNotification('Lesson plan archive is not supported for file-based lesson plans', 'info');
  return false;
}

// ============================================
// CONTENT STATISTICS
// ============================================

async function getContentStatistics() {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      return null;
    }

    const [modules, videos, quizzes, lessonPlans] = await Promise.all([
      getSupabase().from('modules').select('status').then(res => res.data),
      getSupabase().from('videos').select('status').then(res => res.data),
      getSupabase().from('quizzes').select('status').then(res => res.data),
      getSupabase().from(LESSON_PLAN_TABLE).select('id').then(res => res.data)
    ]);

    return {
      modules: {
        active: modules.filter(m => m.status === 'active').length,
        archived: modules.filter(m => m.status === 'archived').length,
        total: modules.length
      },
      videos: {
        active: videos.filter(v => v.status === 'active').length,
        archived: videos.filter(v => v.status === 'archived').length,
        total: videos.length
      },
      quizzes: {
        active: quizzes.filter(q => q.status === 'active').length,
        archived: quizzes.filter(q => q.status === 'archived').length,
        total: quizzes.length
      },
      lessonPlans: {
        active: lessonPlans.length,
        archived: 0,
        total: lessonPlans.length
      }
    };

  } catch (error) {
    console.error('Error getting content statistics:', error);
    return null;
  }
}

// ============================================
// CONTENT FILTERING
// ============================================

async function filterContent(filterOptions) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to filter content', 'error');
      return {
        modules: [],
        videos: [],
        quizzes: [],
        lessonPlans: []
      };
    }

    let queryModules = getSupabase().from('modules').select(`
      *,
      teacher:teacher_id (id, full_name)
    `);

    let queryVideos = getSupabase().from('videos').select(`
      *,
      teacher:teacher_id (id, full_name),
      module:module_id (id, title)
    `);

    let queryQuizzes = getSupabase().from('quizzes').select(`
      *,
      teacher:teacher_id (id, full_name),
      module:module_id (id, title),
      video:video_id (id, title)
    `);

    let queryLessonPlans = getSupabase().from(LESSON_PLAN_TABLE).select(`
      id,
      user_id,
      file_name,
      file_path,
      file_url,
      file_type,
      file_size,
      description,
      module_name,
      lesson_name,
      period_type,
      period_value,
      uploaded_at,
      teacher:user_id (id, full_name, email)
    `);

    // Apply filters
    if (filterOptions.gradeLevel) {
      queryModules = queryModules.eq('grade_level', filterOptions.gradeLevel);
      queryVideos = queryVideos.eq('grade_level', filterOptions.gradeLevel);
      queryQuizzes = queryQuizzes.eq('grade_level', filterOptions.gradeLevel);
      // lesson_plan_files table does not have grade_level
    }

    if (filterOptions.teacherId) {
      queryModules = queryModules.eq('teacher_id', filterOptions.teacherId);
      queryVideos = queryVideos.eq('teacher_id', filterOptions.teacherId);
      queryQuizzes = queryQuizzes.eq('teacher_id', filterOptions.teacherId);
      queryLessonPlans = queryLessonPlans.eq('user_id', filterOptions.teacherId);
    }

    if (filterOptions.status) {
      queryModules = queryModules.eq('status', filterOptions.status);
      queryVideos = queryVideos.eq('status', filterOptions.status);
      queryQuizzes = queryQuizzes.eq('status', filterOptions.status);
      // lesson_plan_files table does not have status
    }

    if (filterOptions.searchTerm) {
      const searchTerm = `%${filterOptions.searchTerm}%`;
      queryModules = queryModules.ilike('name', searchTerm);
      queryVideos = queryVideos.ilike('title', searchTerm);
      queryQuizzes = queryQuizzes.ilike('title', searchTerm);
      queryLessonPlans = queryLessonPlans.or(`file_name.ilike.${searchTerm},module_name.ilike.${searchTerm},lesson_name.ilike.${searchTerm}`);
    }

    const [modules, videos, quizzes, lessonPlans] = await Promise.all([
      queryModules.order('created_at', { ascending: false }).then(res => res.data || []),
      queryVideos.order('created_at', { ascending: false }).then(res => res.data || []),
      queryQuizzes.order('created_at', { ascending: false }).then(res => res.data || []),
      queryLessonPlans.order('uploaded_at', { ascending: false }).then(res => (res.data || []).map(normalizeLessonPlanRow))
    ]);

    const filteredLessonPlans = filterOptions.status && filterOptions.status !== 'active'
      ? []
      : lessonPlans;

    return {
      modules,
      videos,
      quizzes,
      lessonPlans: filteredLessonPlans
    };

  } catch (error) {
    console.error('Error filtering content:', error);
    showNotification('Failed to filter content', 'error');
    return {
      modules: [],
      videos: [],
      quizzes: [],
      lessonPlans: []
    };
  }
}