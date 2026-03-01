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

async function getAllLessonPlans() {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'admin') {
      showNotification('You do not have permission to access this content', 'error');
      return [];
    }

    const { data, error } = await getSupabase()
      .from('lesson_plan_files')
      .select(`
        *,
        user:user_id (id, full_name)
      `)
      .order('uploaded_at', { ascending: false });

    if (error) {
      console.error('Error loading lesson plans:', error);
      showNotification('Failed to load lesson plans', 'error');
      return [];
    }

    return data;

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

    const { data, error } = await getSupabase()
      .from('lesson_plan_files')
      .insert({
        ...lessonPlanData,
        user_id: user.id,
        uploaded_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      console.error('Error creating lesson plan:', error);
      showNotification('Failed to create lesson plan', 'error');
      return null;
    }

    showNotification('Lesson plan created successfully', 'success');
    return data;

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

    const { data, error } = await getSupabase()
      .from('lesson_plan_files')
      .update({
        ...updates
      })
      .eq('id', lessonPlanId)
      .select()
      .single();

    if (error) {
      console.error('Error updating lesson plan:', error);
      showNotification('Failed to update lesson plan', 'error');
      return null;
    }

    showNotification('Lesson plan updated successfully', 'success');
    return data;

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
      .from('lesson_plan_files')
      .select('file_url')
      .eq('id', lessonPlanId)
      .single();

    if (fetchError) {
      console.error('Error fetching lesson plan:', fetchError);
      return false;
    }

    if (lessonPlan.file_url) {
      const fileName = lessonPlan.file_url.split('/').pop();
      const { error: storageError } = await getSupabase()
        .storage
        .from('lesson-plans')
        .remove([fileName]);
      
      if (storageError) {
        console.warn('Failed to delete storage file:', storageError);
      }
    }

    const { error: deleteError } = await getSupabase()
      .from('lesson_plan_files')
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
  return updateLessonPlan(lessonPlanId, { status: 'archived' });
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
      getSupabase().from('lesson_plan_files').select('status').then(res => res.data)
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
        active: lessonPlans.filter(l => l.status === 'active').length,
        archived: lessonPlans.filter(l => l.status === 'archived').length,
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

    let queryLessonPlans = getSupabase().from('lesson_plan_files').select(`
      *,
      user:user_id (id, full_name)
    `);

    // Apply filters
    if (filterOptions.gradeLevel) {
      queryModules = queryModules.eq('grade_level', filterOptions.gradeLevel);
      queryVideos = queryVideos.eq('grade_level', filterOptions.gradeLevel);
      queryQuizzes = queryQuizzes.eq('grade_level', filterOptions.gradeLevel);
      queryLessonPlans = queryLessonPlans.eq('grade_level', filterOptions.gradeLevel);
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
      queryLessonPlans = queryLessonPlans.eq('status', filterOptions.status);
    }

    if (filterOptions.searchTerm) {
      const searchTerm = `%${filterOptions.searchTerm}%`;
      queryModules = queryModules.ilike('title', searchTerm);
      queryVideos = queryVideos.ilike('title', searchTerm);
      queryQuizzes = queryQuizzes.ilike('title', searchTerm);
      queryLessonPlans = queryLessonPlans.ilike('file_name', searchTerm);
    }

    const [modules, videos, quizzes, lessonPlans] = await Promise.all([
      queryModules.order('created_at', { ascending: false }).then(res => res.data || []),
      queryVideos.order('created_at', { ascending: false }).then(res => res.data || []),
      queryQuizzes.order('created_at', { ascending: false }).then(res => res.data || []),
      queryLessonPlans.order('uploaded_at', { ascending: false }).then(res => res.data || [])
    ]);

    return {
      modules,
      videos,
      quizzes,
      lessonPlans
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