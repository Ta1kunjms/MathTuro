/*
  File: student.js
  Purpose:
  - Contains all student-specific functionality
  - Handles module and lesson navigation
  - Manages quiz score entry and screenshot uploads
  - Tracks lesson progress

  Dependencies:
  - supabase.js - for Supabase client connection
  - auth.js - for authentication checks
  - modules.js - for module and lesson data handling
  - uploads.js - for file upload functionality
*/

/*
  Function Name: markLessonComplete
  Purpose:
  - Marks a lesson as complete for the current student
  - Updates the lesson progress in the database

  When it runs:
  - Called when student completes a lesson and clicks the "Mark as Complete" button

  Who can use it:
  - Student

  Backend interaction:
  - Reads existing lesson progress from lesson_progress table
  - Updates or inserts progress record
  - Sets completed flag to true
  - Records completion time

  Error handling:
  - Shows alert if marking lesson complete fails
  - Logs error to console
*/
async function markLessonComplete(lessonId) {
  try {
    // Get current user from localStorage
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'student') {
      alert('You must be logged in as a student to mark lessons as complete');
      return false;
    }

    // Check if progress record already exists
    const { data: existingProgress, error: checkError } = await getSupabase()
      .from('lesson_progress')
      .select('*')
      .eq('student_id', user.id)
      .eq('lesson_id', lessonId)
      .single();

    if (checkError && checkError.code !== 'PGRST116') { // PGRST116 is "no rows returned"
      throw new Error(checkError.message);
    }

    let updateResult;
    if (existingProgress) {
      // Update existing record
      updateResult = await getSupabase()
        .from('lesson_progress')
        .update({
          completed: true,
          completed_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq('student_id', user.id)
        .eq('lesson_id', lessonId);
    } else {
      // Create new record
      updateResult = await getSupabase()
        .from('lesson_progress')
        .insert({
          student_id: user.id,
          lesson_id: lessonId,
          completed: true,
          completed_at: new Date().toISOString(),
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        });
    }

    if (updateResult.error) {
      throw new Error(updateResult.error.message);
    }

    return true;

  } catch (error) {
    console.error('Error marking lesson complete:', error);
    alert('Failed to mark lesson as complete. Please try again.');
    return false;
  }
}

/*
  Function Name: submitQuizScore
  Purpose:
  - Submits a quiz score and optional screenshot as proof
  - Creates a quiz submission record in the database
  - Handles file upload if screenshot is provided

  When it runs:
  - Called when student fills out the quiz score form and clicks "Submit"

  Who can use it:
  - Student

  Backend interaction:
  - Uploads screenshot to Supabase Storage (if provided)
  - Creates a new record in the quiz_submissions table
  - Sets initial status to "pending" for teacher approval
  - Stores score, total items, and screenshot URL

  Error handling:
  - Validates score and total items are numbers
  - Validates score is not greater than total items
  - Handles file upload errors
  - Handles database insertion errors
  - Shows alert for any errors
*/
async function submitQuizScore(lessonId, score, totalItems, screenshotFile = null) {
  try {
    // Get current user from localStorage
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'student') {
      alert('You must be logged in as a student to submit quiz scores');
      return false;
    }

    // Validate input
    const numScore = parseInt(score);
    const numTotalItems = parseInt(totalItems);

    if (isNaN(numScore) || isNaN(numTotalItems)) {
      alert('Score and total items must be numbers');
      return false;
    }

    if (numScore < 0 || numTotalItems <= 0) {
      alert('Score must be at least 0 and total items must be greater than 0');
      return false;
    }

    if (numScore > numTotalItems) {
      alert('Score cannot be greater than total items');
      return false;
    }

    let screenshotUrl = null;
    
    // Upload screenshot if provided
    if (screenshotFile) {
      const uploadResult = await uploadQuizScreenshot(lessonId, user.id, screenshotFile);
      
      if (!uploadResult.success) {
        alert('Failed to upload screenshot: ' + uploadResult.error);
        return false;
      }
      
      screenshotUrl = uploadResult.url;
    }

    // Create quiz submission
    const { data, error } = await getSupabase()
      .from('quiz_submissions')
      .insert({
        student_id: user.id,
        lesson_id: lessonId,
        score: numScore,
        total_items: numTotalItems,
        screenshot_url: screenshotUrl,
        status: 'pending',
        submitted_at: new Date().toISOString(),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select('*')
      .single();

    if (error) {
      throw new Error(error.message);
    }

    return true;

  } catch (error) {
    console.error('Error submitting quiz score:', error);
    alert('Failed to submit quiz score. Please try again.');
    return false;
  }
}

/*
  Function Name: getStudentProgressByModule
  Purpose:
  - Retrieves a student's progress for all lessons in a specific module
  - Calculates completion percentage
  - Returns progress data including completed lessons and quiz scores

  When it runs:
  - Called when student views a module details page

  Who can use it:
  - Student

  Backend interaction:
  - Reads lessons from lessons table for the specified module
  - Reads lesson progress from lesson_progress table
  - Reads quiz submissions from quiz_submissions table
  - Combines data to calculate module completion

  Error handling:
  - Returns empty progress data if no lessons found
  - Logs errors to console
*/
async function getStudentProgressByModule(moduleId) {
  try {
    // Get current user from localStorage
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'student') {
      return null;
    }

    // Get all lessons in the module
    const { data: lessons, error: lessonsError } = await getSupabase()
      .from('lessons')
      .select('*')
      .eq('module_id', moduleId)
      .order('order', { ascending: true });

    if (lessonsError) {
      console.error('Error loading lessons:', lessonsError);
      return null;
    }

    // Get lesson progress
    const { data: progress, error: progressError } = await getSupabase()
      .from('lesson_progress')
      .select('*')
      .eq('student_id', user.id)
      .in('lesson_id', lessons.map(lesson => lesson.id));

    if (progressError) {
      console.error('Error loading lesson progress:', progressError);
    }

    // Get quiz submissions
    const { data: submissions, error: submissionsError } = await getSupabase()
      .from('quiz_submissions')
      .select('*')
      .eq('student_id', user.id)
      .in('lesson_id', lessons.map(lesson => lesson.id));

    if (submissionsError) {
      console.error('Error loading quiz submissions:', submissionsError);
    }

    // Calculate progress
    const lessonProgress = lessons.map(lesson => {
      const lessonProgress = progress.find(p => p.lesson_id === lesson.id);
      const quizSubmission = submissions.find(s => s.lesson_id === lesson.id);

      return {
        lesson_id: lesson.id,
        lesson_title: lesson.title,
        completed: lessonProgress && lessonProgress.completed,
        completed_at: lessonProgress?.completed_at,
        quiz_submitted: !!quizSubmission,
        quiz_score: quizSubmission?.score,
        quiz_total_items: quizSubmission?.total_items,
        quiz_status: quizSubmission?.status,
        quiz_screenshot_url: quizSubmission?.screenshot_url
      };
    });

    // Calculate completion percentage
    const completedLessons = lessonProgress.filter(progress => progress.completed).length;
    const totalLessons = lessonProgress.length;
    const completionPercentage = totalLessons > 0 ? Math.round((completedLessons / totalLessons) * 100) : 0;

    return {
      module_id: moduleId,
      total_lessons: totalLessons,
      completed_lessons: completedLessons,
      completion_percentage: completionPercentage,
      lessons: lessonProgress
    };

  } catch (error) {
    console.error('Error getting student progress:', error);
    return null;
  }
}

/*
  Function Name: getQuizSubmissions
  Purpose:
  - Retrieves all quiz submissions for the current student
  - Filters by status (pending, approved, rejected)
  - Returns submissions with lesson information

  When it runs:
  - Called when student views their quiz submissions page
  - Called when teacher views pending submissions

  Who can use it:
  - Student

  Backend interaction:
  - Reads quiz submissions from quiz_submissions table
  - Joins with lessons table to get lesson details
  - Orders by submission date descending

  Error handling:
  - Returns empty array if no submissions
  - Logs errors to console
*/
async function getQuizSubmissions(status = null) {
  try {
    // Get current user from localStorage
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'student') {
      return [];
    }

    // Build query
    let query = getSupabase()
      .from('quiz_submissions')
      .select('*, lessons(title, module_id), modules(title)')
      .eq('student_id', user.id)
      .order('submitted_at', { ascending: false });

    // Filter by status if provided
    if (status) {
      query = query.eq('status', status);
    }

    const { data, error } = await query;

    if (error) {
      console.error('Error loading quiz submissions:', error);
      return [];
    }

    return data;

  } catch (error) {
    console.error('Error getting quiz submissions:', error);
    return [];
  }
}

/*
  Function Name: requestQuizResubmission
  Purpose:
  - Requests to resubmit a rejected quiz
  - Updates the submission status back to pending
  - Clears any existing teacher comments

  When it runs:
  - Called when student clicks "Resubmit" on a rejected quiz

  Who can use it:
  - Student

  Backend interaction:
  - Updates the quiz_submissions table
  - Changes status from "rejected" to "pending"
  - Clears teacher_comment field
  - Updates updated_at timestamp

  Error handling:
  - Shows alert if request fails
  - Logs error to console
*/
async function requestQuizResubmission(submissionId) {
  try {
    // Get current user from localStorage
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'student') {
      alert('You must be logged in as a student to request resubmission');
      return false;
    }

    // Update submission status
    const { error } = await getSupabase()
      .from('quiz_submissions')
      .update({
        status: 'pending',
        teacher_comment: null,
        updated_at: new Date().toISOString()
      })
      .eq('id', submissionId)
      .eq('student_id', user.id);

    if (error) {
      throw new Error(error.message);
    }

    return true;

  } catch (error) {
    console.error('Error requesting resubmission:', error);
    alert('Failed to request resubmission. Please try again.');
    return false;
  }
}

/*
  Function Name: updateQuizSubmission
  Purpose:
  - Updates an existing quiz submission
  - Allows student to resubmit with new score or screenshot
  - Handles file upload if new screenshot is provided

  When it runs:
  - Called when student resubmits a quiz after rejection

  Who can use it:
  - Student

  Backend interaction:
  - Updates the quiz_submissions table
  - Handles file upload for new screenshot
  - Changes status back to pending
  - Clears teacher comments

  Error handling:
  - Validates input values
  - Handles file upload errors
  - Handles database update errors
  - Shows alert for any errors
*/
async function updateQuizSubmission(submissionId, score, totalItems, screenshotFile = null) {
  try {
    // Get current user from localStorage
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || user.role !== 'student') {
      alert('You must be logged in as a student to update quiz submissions');
      return false;
    }

    // Validate input
    const numScore = parseInt(score);
    const numTotalItems = parseInt(totalItems);

    if (isNaN(numScore) || isNaN(numTotalItems)) {
      alert('Score and total items must be numbers');
      return false;
    }

    if (numScore < 0 || numTotalItems <= 0) {
      alert('Score must be at least 0 and total items must be greater than 0');
      return false;
    }

    if (numScore > numTotalItems) {
      alert('Score cannot be greater than total items');
      return false;
    }

    const updateData = {
      score: numScore,
      total_items: numTotalItems,
      status: 'pending',
      teacher_comment: null,
      updated_at: new Date().toISOString()
    };

    // Upload new screenshot if provided
    if (screenshotFile) {
      // Get submission data to get lesson_id
      const { data: submission, error: getError } = await getSupabase()
        .from('quiz_submissions')
        .select('lesson_id')
        .eq('id', submissionId)
        .single();

      if (getError) {
        throw new Error(getError.message);
      }

      const uploadResult = await uploadQuizScreenshot(submission.lesson_id, user.id, screenshotFile);
      
      if (!uploadResult.success) {
        alert('Failed to upload screenshot: ' + uploadResult.error);
        return false;
      }
      
      updateData.screenshot_url = uploadResult.url;
    }

    // Update the submission
    const { error: updateError } = await getSupabase()
      .from('quiz_submissions')
      .update(updateData)
      .eq('id', submissionId)
      .eq('student_id', user.id);

    if (updateError) {
      throw new Error(updateError.message);
    }

    return true;

  } catch (error) {
    console.error('Error updating quiz submission:', error);
    alert('Failed to update quiz submission. Please try again.');
    return false;
  }
}

// ============================================
// STUDENT DASHBOARD API FUNCTIONS
// ============================================

/*
  Function Name: getStudentDashboardStats
  Purpose:
  - Retrieves comprehensive dashboard statistics for a student
  - Includes modules, lessons, submissions, and XP data

  Returns:
  - Object with all dashboard statistics
*/
async function getStudentDashboardStats() {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user || user.role !== 'student') return null;

    // Get all modules with lessons
    const { data: modules } = await getSupabase()
      .from('modules')
      .select('*, lessons(id)')
      .eq('is_active', true);

    // Get lesson progress
    const { data: lessonProgress } = await getSupabase()
      .from('lesson_progress')
      .select('*, lessons(module_id)')
      .eq('student_id', user.id)
      .eq('completed', true);

    // Get quiz submissions
    const { data: submissions } = await getSupabase()
      .from('quiz_submissions')
      .select('score, total_items, status')
      .eq('student_id', user.id);

    // Calculate stats
    const completedLessons = lessonProgress?.length || 0;
    let totalLessons = 0;
    modules?.forEach(m => totalLessons += (m.lessons?.length || 0));

    // Calculate completed modules
    const moduleProgress = {};
    lessonProgress?.forEach(lp => {
      const moduleId = lp.lessons?.module_id;
      if (moduleId) moduleProgress[moduleId] = (moduleProgress[moduleId] || 0) + 1;
    });

    let completedModules = 0;
    modules?.forEach(module => {
      const moduleLessonsCount = module.lessons?.length || 0;
      if (moduleLessonsCount > 0 && moduleProgress[module.id] >= moduleLessonsCount) {
        completedModules++;
      }
    });

    // Calculate average score
    let averageScore = 0;
    const approvedSubmissions = submissions?.filter(s => s.status === 'approved') || [];
    if (approvedSubmissions.length > 0) {
      const totalPercent = approvedSubmissions.reduce((sum, s) => sum + (s.score / s.total_items * 100), 0);
      averageScore = Math.round(totalPercent / approvedSubmissions.length);
    }

    // Calculate XP
    const xp = (completedLessons * 10) + (completedModules * 50) + (approvedSubmissions.length * 20);

    return {
      modules: modules || [],
      totalModules: modules?.length || 0,
      completedModules,
      totalLessons,
      completedLessons,
      submissions: submissions || [],
      approvedSubmissions: approvedSubmissions.length,
      averageScore,
      xp
    };

  } catch (error) {
    console.error('Error getting dashboard stats:', error);
    return null;
  }
}

/*
  Function Name: getStudentStreak
  Purpose:
  - Retrieves the current learning streak for a student
  - Updates streak if needed based on recent activity
*/
async function getStudentStreak() {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user || user.role !== 'student') return 0;

    const { data: streakData } = await getSupabase()
      .from('student_streaks')
      .select('*')
      .eq('student_id', user.id)
      .single();

    return streakData?.current_streak || 0;

  } catch (error) {
    console.log('No streak data');
    return 0;
  }
}

/*
  Function Name: updateStudentStreak
  Purpose:
  - Updates or creates a streak record for the student
  - Called when student completes a lesson or quiz
*/
async function updateStudentStreak() {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user || user.role !== 'student') return false;

    const today = new Date().toISOString().split('T')[0];

    // Get current streak data
    const { data: existing } = await getSupabase()
      .from('student_streaks')
      .select('*')
      .eq('student_id', user.id)
      .single();

    if (existing) {
      const lastActivity = existing.last_activity_date;
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayStr = yesterday.toISOString().split('T')[0];

      let newStreak = existing.current_streak;
      if (lastActivity === yesterdayStr) {
        newStreak += 1;
      } else if (lastActivity !== today) {
        newStreak = 1;
      }

      await getSupabase()
        .from('student_streaks')
        .update({
          current_streak: newStreak,
          longest_streak: Math.max(newStreak, existing.longest_streak || 0),
          last_activity_date: today,
          updated_at: new Date().toISOString()
        })
        .eq('student_id', user.id);

    } else {
      await getSupabase()
        .from('student_streaks')
        .insert({
          student_id: user.id,
          current_streak: 1,
          longest_streak: 1,
          last_activity_date: today,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        });
    }

    return true;
  } catch (error) {
    console.error('Error updating streak:', error);
    return false;
  }
}

/*
  Function Name: getRecentActivity
  Purpose:
  - Retrieves recent learning activity for the student
  - Returns lesson progress and quiz submissions
*/
async function getRecentActivity(limit = 10) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user || user.role !== 'student') return [];

    const { data: progress } = await getSupabase()
      .from('lesson_progress')
      .select('*, lessons(title, module_id)')
      .eq('student_id', user.id)
      .order('updated_at', { ascending: false })
      .limit(limit);

    return progress || [];

  } catch (error) {
    console.error('Error getting recent activity:', error);
    return [];
  }
}

/*
  Function Name: getWeeklyActivity
  Purpose:
  - Returns activity count for each day of the current week
  - Used for the weekly activity heatmap
*/
async function getWeeklyActivity() {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user || user.role !== 'student') return [0, 0, 0, 0, 0, 0, 0];

    const startOfWeek = new Date();
    startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay() + 1);
    startOfWeek.setHours(0, 0, 0, 0);

    const { data: activity } = await getSupabase()
      .from('lesson_progress')
      .select('updated_at')
      .eq('student_id', user.id)
      .gte('updated_at', startOfWeek.toISOString());

    const dayCounts = [0, 0, 0, 0, 0, 0, 0];
    activity?.forEach(a => {
      const day = new Date(a.updated_at).getDay();
      const adjustedDay = day === 0 ? 6 : day - 1;
      dayCounts[adjustedDay]++;
    });

    return dayCounts;

  } catch (error) {
    console.error('Error getting weekly activity:', error);
    return [0, 0, 0, 0, 0, 0, 0];
  }
}

/*
  Function Name: getStudentAchievements
  Purpose:
  - Returns list of achievements based on student progress
  - Calculates which achievements have been earned
*/
async function getStudentAchievements() {
  try {
    const stats = await getStudentDashboardStats();
    const streak = await getStudentStreak();

    if (!stats) return [];

    const achievements = [
      { id: 'first_lesson', emoji: '🏆', name: 'First Steps', desc: 'Complete your first lesson', earned: stats.completedLessons >= 1 },
      { id: 'five_lessons', emoji: '📖', name: 'Bookworm', desc: 'Complete 5 lessons', earned: stats.completedLessons >= 5 },
      { id: 'ten_lessons', emoji: '📚', name: 'Scholar', desc: 'Complete 10 lessons', earned: stats.completedLessons >= 10 },
      { id: 'quiz_master', emoji: '⭐', name: 'Quiz Star', desc: 'Get 5 quizzes approved', earned: stats.approvedSubmissions >= 5 },
      { id: 'perfect_score', emoji: '🎯', name: 'Perfectionist', desc: 'Get a perfect quiz score', earned: stats.submissions.some(s => s.score === s.total_items) },
      { id: 'module_complete', emoji: '🎓', name: 'Module Master', desc: 'Complete a module', earned: stats.completedModules >= 1 },
      { id: 'streak_3', emoji: '🔥', name: '3 Day Streak', desc: 'Learn 3 days in a row', earned: streak >= 3 },
      { id: 'streak_7', emoji: '💪', name: 'Week Warrior', desc: 'Learn 7 days in a row', earned: streak >= 7 },
      { id: 'xp_100', emoji: '💎', name: 'XP Hunter', desc: 'Earn 100 XP', earned: stats.xp >= 100 },
      { id: 'xp_500', emoji: '🌟', name: 'XP Master', desc: 'Earn 500 XP', earned: stats.xp >= 500 },
      { id: 'xp_1000', emoji: '👑', name: 'XP Legend', desc: 'Earn 1000 XP', earned: stats.xp >= 1000 }
    ];

    return achievements;

  } catch (error) {
    console.error('Error getting achievements:', error);
    return [];
  }
}

/*
  Function Name: getStudentNotifications
  Purpose:
  - Returns recent notifications for the student
  - Includes quiz review notifications
*/
async function getStudentNotifications(limit = 10) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user || user.role !== 'student') return [];

    const { data: submissions } = await getSupabase()
      .from('quiz_submissions')
      .select('*, lessons(title)')
      .eq('student_id', user.id)
      .in('status', ['approved', 'rejected'])
      .order('reviewed_at', { ascending: false })
      .limit(limit);

    return (submissions || []).map(sub => ({
      id: sub.id,
      type: sub.status === 'approved' ? 'success' : 'warning',
      title: `Quiz ${sub.status === 'approved' ? 'Approved' : 'Needs Review'}`,
      message: sub.lessons?.title || 'Quiz Submission',
      comment: sub.teacher_comment,
      date: sub.reviewed_at
    }));

  } catch (error) {
    console.error('Error getting notifications:', error);
    return [];
  }
}

// ============================================
// TUTORIAL VIDEOS API FUNCTIONS
// ============================================

/*
  Function Name: getTutorialVideos
  Purpose:
  - Retrieves tutorial videos, optionally filtered by category
*/
async function getTutorialVideos(category = null, featured = false) {
  try {
    let query = getSupabase()
      .from('tutorial_videos')
      .select('*')
      .eq('is_active', true)
      .order('order', { ascending: true });

    if (category && category !== 'all') {
      query = query.eq('category', category);
    }

    if (featured) {
      query = query.eq('is_featured', true);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data || [];

  } catch (error) {
    console.error('Error getting tutorial videos:', error);
    return [];
  }
}

/*
  Function Name: trackVideoView
  Purpose:
  - Records when a student views a tutorial video
*/
async function trackVideoView(videoId) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user) return false;

    await getSupabase()
      .from('video_views')
      .insert({
        video_id: videoId,
        student_id: user.id,
        viewed_at: new Date().toISOString()
      });

    return true;
  } catch (error) {
    console.error('Error tracking video view:', error);
    return false;
  }
}

/*
  Function Name: addTutorialVideo (Teacher/Admin only)
  Purpose:
  - Adds a new tutorial video to the database
*/
async function addTutorialVideo(videoData) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      return { success: false, error: 'Unauthorized' };
    }

    const { data, error } = await getSupabase()
      .from('tutorial_videos')
      .insert({
        title: videoData.title,
        description: videoData.description,
        category: videoData.category,
        video_url: videoData.videoUrl,
        thumbnail_url: videoData.thumbnailUrl,
        duration: videoData.duration,
        is_featured: videoData.isFeatured || false,
        is_active: true,
        created_by: user.id,
        order: videoData.order || 0,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) throw error;
    return { success: true, data };

  } catch (error) {
    console.error('Error adding tutorial video:', error);
    return { success: false, error: error.message };
  }
}

/*
  Function Name: updateTutorialVideo (Teacher/Admin only)
  Purpose:
  - Updates an existing tutorial video
*/
async function updateTutorialVideo(videoId, videoData) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      return { success: false, error: 'Unauthorized' };
    }

    const { data, error } = await getSupabase()
      .from('tutorial_videos')
      .update({
        ...videoData,
        updated_at: new Date().toISOString()
      })
      .eq('id', videoId)
      .select()
      .single();

    if (error) throw error;
    return { success: true, data };

  } catch (error) {
    console.error('Error updating tutorial video:', error);
    return { success: false, error: error.message };
  }
}

/*
  Function Name: deleteTutorialVideo (Teacher/Admin only)
  Purpose:
  - Soft deletes a tutorial video by setting is_active to false
*/
async function deleteTutorialVideo(videoId) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      return { success: false, error: 'Unauthorized' };
    }

    const { error } = await getSupabase()
      .from('tutorial_videos')
      .update({ is_active: false, updated_at: new Date().toISOString() })
      .eq('id', videoId);

    if (error) throw error;
    return { success: true };

  } catch (error) {
    console.error('Error deleting tutorial video:', error);
    return { success: false, error: error.message };
  }
}

// ============================================
// STUDENT NOTES API FUNCTIONS
// ============================================

/*
  Function Name: saveStudentNote
  Purpose:
  - Saves a note for the student (stored in localStorage or database)
*/
async function saveStudentNote(noteContent, lessonId = null) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user || user.role !== 'student') return false;

    // Try to save to database first
    try {
      await getSupabase()
        .from('student_notes')
        .upsert({
          student_id: user.id,
          lesson_id: lessonId,
          content: noteContent,
          updated_at: new Date().toISOString()
        }, { onConflict: 'student_id,lesson_id' });
    } catch {
      // Fallback to localStorage
      const key = lessonId ? `note_${user.id}_${lessonId}` : `note_${user.id}_general`;
      localStorage.setItem(key, noteContent);
    }

    return true;
  } catch (error) {
    console.error('Error saving note:', error);
    return false;
  }
}

/*
  Function Name: getStudentNotes
  Purpose:
  - Retrieves notes for the student
*/
async function getStudentNotes(lessonId = null) {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    if (!user || user.role !== 'student') return '';

    // Try database first
    try {
      const { data } = await getSupabase()
        .from('student_notes')
        .select('content')
        .eq('student_id', user.id)
        .eq('lesson_id', lessonId)
        .single();

      if (data) return data.content;
    } catch {
      // Fallback to localStorage
      const key = lessonId ? `note_${user.id}_${lessonId}` : `note_${user.id}_general`;
      return localStorage.getItem(key) || '';
    }

    return '';
  } catch (error) {
    console.error('Error getting notes:', error);
    return '';
  }
}

// ============================================
// SEARCH FUNCTIONALITY
// ============================================

/*
  Function Name: searchContent
  Purpose:
  - Searches modules, lessons, and videos by keyword
*/
async function searchContent(query) {
  try {
    if (!query || query.length < 2) return { modules: [], lessons: [], videos: [] };

    const searchTerm = `%${query.toLowerCase()}%`;

    // Search modules
    const { data: modules } = await getSupabase()
      .from('modules')
      .select('id, title, description')
      .eq('is_active', true)
      .or(`title.ilike.${searchTerm},description.ilike.${searchTerm}`)
      .limit(5);

    // Search lessons
    const { data: lessons } = await getSupabase()
      .from('lessons')
      .select('id, title, module_id')
      .or(`title.ilike.${searchTerm}`)
      .limit(5);

    // Search videos
    const { data: videos } = await getSupabase()
      .from('tutorial_videos')
      .select('id, title, category')
      .eq('is_active', true)
      .or(`title.ilike.${searchTerm},description.ilike.${searchTerm}`)
      .limit(5);

    return {
      modules: modules || [],
      lessons: lessons || [],
      videos: videos || []
    };

  } catch (error) {
    console.error('Error searching content:', error);
    return { modules: [], lessons: [], videos: [] };
  }
}
