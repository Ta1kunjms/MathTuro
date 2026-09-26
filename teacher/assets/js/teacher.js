/*
  File: teacher.js
  Purpose:
  - Contains all teacher-specific functionality
  - Manages module and lesson creation/editing
  - Handles quiz submission approval/rejection
  - Views student progress reports

  Dependencies:
  - supabase.js - for Supabase client connection
  - auth.js - for authentication checks
  - modules.js - for module and lesson data handling
  - uploads.js - for file upload functionality
*/

/*
  Function Name: approveQuizSubmission
  Purpose:
  - Approves a student's quiz submission
  - Updates the submission status to "approved"
  - Adds teacher comments if provided

  When it runs:
  - Called when teacher reviews and approves a quiz submission
  - Can be called from the teacher dashboard or submissions page

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Updates the quiz_submissions table
  - Sets status to "approved"
  - Saves teacher_comment field
  - Records reviewed_at timestamp

  Error handling:
  - Validates user role
  - Handles database update errors
  - Shows alert for errors
*/
async function approveQuizSubmission(submissionId, comment = null) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      alert('You do not have permission to approve quiz submissions');
      return false;
    }

    // Update submission status
    const { error } = await getSupabase()
      .from('quiz_submissions')
      .update({
        status: 'approved',
        teacher_comment: comment,
        reviewed_at: new Date().toISOString(),
        reviewed_by: user.id,
        updated_at: new Date().toISOString()
      })
      .eq('id', submissionId);

    if (error) {
      console.error('Error approving quiz submission:', error);
      alert('Failed to approve quiz submission: ' + error.message);
      return false;
    }

    return true;

  } catch (error) {
    console.error('Error approving quiz submission:', error);
    alert('Failed to approve quiz submission. Please try again.');
    return false;
  }
}

/*
  Function Name: rejectQuizSubmission
  Purpose:
  - Rejects a student's quiz submission
  - Updates the submission status to "rejected"
  - Requires teacher to provide comments explaining rejection

  When it runs:
  - Called when teacher reviews and rejects a quiz submission
  - Can be called from the teacher dashboard or submissions page

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Updates the quiz_submissions table
  - Sets status to "rejected"
  - Saves teacher_comment field (required)
  - Records reviewed_at timestamp

  Error handling:
  - Validates user role
  - Requires comment to be provided
  - Handles database update errors
  - Shows alert for errors
*/
async function rejectQuizSubmission(submissionId, comment) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      alert('You do not have permission to reject quiz submissions');
      return false;
    }

    // Validate comment is provided
    if (!comment || comment.trim() === '') {
      alert('Please provide a comment explaining why you are rejecting this submission');
      return false;
    }

    // Update submission status
    const { error } = await getSupabase()
      .from('quiz_submissions')
      .update({
        status: 'rejected',
        teacher_comment: comment.trim(),
        reviewed_at: new Date().toISOString(),
        reviewed_by: user.id,
        updated_at: new Date().toISOString()
      })
      .eq('id', submissionId);

    if (error) {
      console.error('Error rejecting quiz submission:', error);
      alert('Failed to reject quiz submission: ' + error.message);
      return false;
    }

    return true;

  } catch (error) {
    console.error('Error rejecting quiz submission:', error);
    alert('Failed to reject quiz submission. Please try again.');
    return false;
  }
}

/*
  Function Name: getPendingQuizSubmissions
  Purpose:
  - Retrieves all pending quiz submissions that need to be reviewed
  - Returns submissions with student and lesson information

  When it runs:
  - Called when teacher views the pending submissions page
  - Called when teacher checks dashboard for pending reviews

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Reads from quiz_submissions table where status is "pending"
  - Joins with users and lessons tables for additional info
  - Orders by submitted_at ascending

  Error handling:
  - Returns empty array if no pending submissions
  - Logs errors to console
*/
async function getPendingQuizSubmissions() {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      return [];
    }

    const { data: submissions, error } = await getSupabase()
      .from('quiz_submissions')
      .select('*')
      .eq('status', 'pending')
      .order('submitted_at', { ascending: true });

    if (error) {
      console.error('Error loading pending submissions:', error);
      return [];
    }

    if (!submissions || submissions.length === 0) return [];

    const userIds = [...new Set(submissions.map(s => s.user_id).filter(Boolean))];
    const quizIds = [...new Set(submissions.map(s => s.quiz_id).filter(Boolean))];
    const moduleIds = [...new Set(submissions.map(s => s.module_id).filter(Boolean))];
    const lessonIds = [...new Set(submissions.map(s => s.lesson_id).filter(Boolean))];

    let usersMap = {}, quizzesMap = {}, modulesMap = {}, lessonsMap = {};

    if (userIds.length > 0) {
      const { data: users } = await getSupabase().from('users').select('id, full_name').in('id', userIds);
      if (users) users.forEach(u => usersMap[u.id] = u);
    }
    if (quizIds.length > 0) {
      const { data: quizzes } = await getSupabase().from('quizzes').select('id, title').in('id', quizIds);
      if (quizzes) quizzes.forEach(q => quizzesMap[q.id] = q);
    }
    if (moduleIds.length > 0) {
      const { data: modules } = await getSupabase().from('modules').select('id, title').in('id', moduleIds);
      if (modules) modules.forEach(m => modulesMap[m.id] = m);
    }
    if (lessonIds.length > 0) {
      const { data: lessons } = await getSupabase().from('lessons').select('id, title, module_id').in('id', lessonIds);
      if (lessons) lessons.forEach(l => lessonsMap[l.id] = l);
    }

    return submissions.map(s => ({
      ...s,
      users: usersMap[s.user_id] || null,
      quizzes: quizzesMap[s.quiz_id] || null,
      modules: modulesMap[s.module_id] || null,
      lessons: lessonsMap[s.lesson_id] || null
    }));

  } catch (error) {
    console.error('Error getting pending submissions:', error);
    return [];
  }
}

/*
  Function Name: getStudentProgress
  Purpose:
  - Retrieves detailed progress information for a specific student
  - Returns module, lesson, and quiz completion data

  When it runs:
  - Called when teacher views a student's detailed progress
  - Called from the student progress page

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Reads from users, modules, lessons, lesson_progress, and quiz_submissions tables
  - Calculates completion percentages per module
  - Returns detailed progress data

  Error handling:
  - Returns null if student not found
  - Logs errors to console
*/
async function getStudentProgress(studentId) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      return null;
    }

    // Get student information
    const { data: student, error: studentError } = await getSupabase()
      .from('users')
      .select('*')
      .eq('id', studentId)
      .single();

    if (studentError) {
      console.error('Error loading student:', studentError);
      return null;
    }

    // Get all modules and lessons
    const { data: modules, error: modulesError } = await getSupabase()
      .from('modules')
      .select('*, lessons(*)')
      .eq('is_active', true)
      .order('order', { ascending: true });

    if (modulesError) {
      console.error('Error loading modules:', modulesError);
      return null;
    }

    // Get lesson progress
    const { data: progressData, error: progressError } = await getSupabase()
      .from('lesson_progress')
      .select('*')
      .eq('user_id', studentId);

    if (progressError) {
      console.error('Error loading lesson progress:', progressError);
    }

    // Get quiz submissions
    const { data: submissionsData, error: submissionsError } = await getSupabase()
      .from('quiz_submissions')
      .select('*')
      .eq('user_id', studentId);

    if (submissionsError) {
      console.error('Error loading quiz submissions:', submissionsError);
    }

    const progress = progressData || [];
    const submissions = submissionsData || [];

    // Process module progress
    const moduleProgress = modules.map(module => {
      const moduleLessons = module.lessons || [];
      
      const completedLessons = moduleLessons.filter(lesson => 
        progress.some(p => p.lesson_id === lesson.id && p.completed)
      ).length;

      const quizSubmissions = moduleLessons.filter(lesson => 
        submissions.some(s => s.lesson_id === lesson.id)
      ).length;

      const approvedQuizzes = moduleLessons.filter(lesson => 
        submissions.some(s => s.lesson_id === lesson.id && s.status === 'approved')
      ).length;

      const completionPercentage = moduleLessons.length > 0 ? 
        Math.round((completedLessons / moduleLessons.length) * 100) : 0;

      return {
        module_id: module.id,
        module_title: module.title,
        total_lessons: moduleLessons.length,
        completed_lessons: completedLessons,
        completion_percentage: completionPercentage,
        quiz_submissions: quizSubmissions,
        approved_quizzes: approvedQuizzes,
        lessons: moduleLessons.map(lesson => {
          const lessonProgress = progress.find(p => p.lesson_id === lesson.id);
          const quizSubmission = submissions.find(s => s.lesson_id === lesson.id);

          return {
            lesson_id: lesson.id,
            lesson_title: lesson.title,
            completed: !!lessonProgress?.completed,
            completed_at: lessonProgress?.completed_at,
            quiz_submitted: !!quizSubmission,
            quiz_score: quizSubmission?.student_score,
            quiz_total_items: quizSubmission?.total_items,
            quiz_status: quizSubmission?.status,
            quiz_screenshot_url: quizSubmission?.screenshot_url,
            teacher_comment: quizSubmission?.teacher_comment
          };
        })
      };
    });

    // Calculate overall progress
    const totalLessons = modules.reduce((sum, module) => sum + module.lessons.length, 0);
    const totalCompletedLessons = moduleProgress.reduce((sum, module) => sum + module.completed_lessons, 0);
    const totalApprovedQuizzes = moduleProgress.reduce((sum, module) => sum + module.approved_quizzes, 0);
    const totalQuizSubmissions = moduleProgress.reduce((sum, module) => sum + module.quiz_submissions, 0);

    return {
      user_id: student.id,
      student_name: student.full_name,
      student_email: student.email,
      total_lessons: totalLessons,
      completed_lessons: totalCompletedLessons,
      overall_completion: totalLessons > 0 ? Math.round((totalCompletedLessons / totalLessons) * 100) : 0,
      total_quizzes_submitted: totalQuizSubmissions,
      total_quizzes_approved: totalApprovedQuizzes,
      modules: moduleProgress
    };

  } catch (error) {
    console.error('Error getting student progress:', error);
    return null;
  }
}

/*
  Function Name: getStudentsByModule
  Purpose:
  - Retrieves all students and their progress for a specific module
  - Returns students with completion and quiz submission status

  When it runs:
  - Called when teacher views module-specific student progress
  - Called from the module management page

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Reads from users, lessons, lesson_progress, and quiz_submissions tables
  - Filters by module ID
  - Returns per-student progress data

  Error handling:
  - Returns empty array if no students found
  - Logs errors to console
*/
async function getStudentsByModule(moduleId) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      return [];
    }

    // Get all lessons in the module
    const { data: lessons, error: lessonsError } = await getSupabase()
      .from('lessons')
      .select('id')
      .eq('module_id', moduleId);

    if (lessonsError) {
      console.error('Error loading lessons:', lessonsError);
      return [];
    }

    // Get all students
    const { data: students, error: studentsError } = await getSupabase()
      .from('users')
      .select('*')
      .eq('role', 'student');

    if (studentsError) {
      console.error('Error loading students:', studentsError);
      return [];
    }

    // Get lesson progress for all students
    const { data: progressData, error: progressError } = await getSupabase()
      .from('lesson_progress')
      .select('*')
      .in('lesson_id', lessons.map(lesson => lesson.id));

    if (progressError) {
      console.error('Error loading lesson progress:', progressError);
    }

    // Get quiz submissions for all students
    const { data: submissionsData, error: submissionsError } = await getSupabase()
      .from('quiz_submissions')
      .select('*')
      .in('lesson_id', lessons.map(lesson => lesson.id));

    if (submissionsError) {
      console.error('Error loading quiz submissions:', submissionsError);
    }

    const progress = progressData || [];
    const submissions = submissionsData || [];

    // Process student progress
    return students.map(student => {
      const studentProgress = progress.filter(p => p.user_id === student.id);
      const studentSubmissions = submissions.filter(s => s.user_id === student.id);

      const completedLessons = studentProgress.filter(p => p.completed).length;
      const submittedQuizzes = studentSubmissions.length;
      const approvedQuizzes = studentSubmissions.filter(s => s.status === 'approved').length;

      const completionPercentage = lessons.length > 0 ? 
        Math.round((completedLessons / lessons.length) * 100) : 0;

      return {
        user_id: student.id,
        student_name: student.full_name,
        student_email: student.email,
        total_lessons: lessons.length,
        completed_lessons: completedLessons,
        completion_percentage: completionPercentage,
        submitted_quizzes: submittedQuizzes,
        approved_quizzes: approvedQuizzes,
        lessons: lessons.map(lesson => {
          const lessonProgress = studentProgress.find(p => p.lesson_id === lesson.id);
          const quizSubmission = studentSubmissions.find(s => s.lesson_id === lesson.id);

          return {
            lesson_id: lesson.id,
            completed: !!lessonProgress?.completed,
            quiz_submitted: !!quizSubmission,
            quiz_score: quizSubmission?.student_score,
            quiz_total_items: quizSubmission?.total_items,
            quiz_status: quizSubmission?.status,
            quiz_screenshot_url: quizSubmission?.screenshot_url,
            teacher_comment: quizSubmission?.teacher_comment
          };
        })
      };
    });

  } catch (error) {
    console.error('Error getting students by module:', error);
    return [];
  }
}

/*
  Function Name: getSubmissionStats
  Purpose:
  - Retrieves submission statistics for teacher dashboard
  - Returns counts of pending, approved, and rejected submissions

  When it runs:
  - Called when teacher views their dashboard
  - Provides quick overview of submission statuses

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Reads from quiz_submissions table
  - Counts submissions by status

  Error handling:
  - Returns default counts if query fails
  - Logs errors to console
*/
async function getSubmissionStats() {
  try {
    // Supabase JS client doesn't support .group() directly
    // We need to fetch all submissions and count client-side, or use separate queries
    const { data: allSubmissions, error } = await getSupabase()
      .from('quiz_submissions')
      .select('status');

    if (error) {
      console.error('Error loading submission stats:', error);
      return { pending: 0, approved: 0, rejected: 0 };
    }

    const stats = {
      pending: 0,
      approved: 0,
      rejected: 0
    };

    if (allSubmissions) {
      allSubmissions.forEach(submission => {
        if (stats[submission.status] !== undefined) {
          stats[submission.status]++;
        }
      });
    }

    return stats;

  } catch (error) {
    console.error('Error getting submission stats:', error);
    return { pending: 0, approved: 0, rejected: 0 };
  }
}

/*
  Function Name: sendNotification
  Purpose:
  - Sends an in-app notification to a student
  - Used to notify students about quiz submission reviews

  When it runs:
  - Called after teacher approves or rejects a quiz submission
  - Can be called manually from admin interface

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Inserts into notifications table
  - Sets read status to false
  - Records created_at timestamp

  Error handling:
  - Validates notification data
  - Handles database insertion errors
  - Shows alert for errors
*/
async function sendNotification(studentId, title, message) {
  try {
    // Check user role
    const user = JSON.parse(localStorage.getItem('user'));
    
    if (!user || (user.role !== 'teacher' && user.role !== 'admin')) {
      alert('You do not have permission to send notifications');
      return false;
    }

    // Validate notification data
    if (!title || !message) {
      alert('Notification title and message are required');
      return false;
    }

    const { error } = await getSupabase()
      .from('notifications')
      .insert({
        user_id: studentId,
        title: title,
        message: message,
        read: false,
        created_at: new Date().toISOString()
      });

    if (error) {
      console.error('Error sending notification:', error);
      alert('Failed to send notification: ' + error.message);
      return false;
    }

    return true;

  } catch (error) {
    console.error('Error sending notification:', error);
    alert('Failed to send notification. Please try again.');
    return false;
  }
}

/*
  Function Name: loadTeacherSections
  Purpose:
  - Loads and displays the teacher's assigned sections on the dashboard
  - Fetches sections from database using getTeacherSections function
  - Displays sections with grade level information

  When it runs:
  - Called on teacher dashboard initialization
  - Can be called manually to refresh section data

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Calls getTeacherSections function which queries sections table
  - Filters sections by teacher_id

  Error handling:
  - Handles database query errors
  - Shows message if no sections are assigned
*/
async function loadTeacherSections(teacherId) {
  try {
    const sectionsContainer = document.getElementById('mySections');
    if (!sectionsContainer) {
      return;
    }

    // Show loading state
    sectionsContainer.innerHTML = `
      <div class="p-6 text-center text-gray-500">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-4 border-teacher-600 border-t-transparent mb-2"></div>
        <p>Loading sections...</p>
      </div>
    `;

    // Fetch teacher sections
    const sections = await getTeacherSections(teacherId);

    if (sections.length === 0) {
      sectionsContainer.innerHTML = `
        <div class="p-6 text-center text-gray-500">
          <p>No sections assigned</p>
        </div>
      `;
      return;
    }

    // Display sections
    let html = '';
    for (const section of sections) {
      // Get student count for the section
      const students = await getStudentsBySection(section.id);
      
      html += `
        <div class="p-4 hover:bg-gray-50 transition-colors">
          <div class="flex items-center justify-between">
            <div>
              <h4 class="font-semibold text-gray-800">${section.name}</h4>
              <p class="text-sm text-gray-600">${section.grade_levels?.name || 'N/A'}</p>
            </div>
            <div class="text-right">
              <p class="text-sm font-medium text-teacher-600">${students.length} Students</p>
              <button 
                onclick="viewSectionStudents('${section.id}', '${section.name}')"
                class="text-xs text-teacher-600 hover:text-teacher-700 mt-1"
              >
                View Students
              </button>
            </div>
          </div>
        </div>
      `;
    }

    sectionsContainer.innerHTML = html;

  } catch (error) {
    console.error('Error loading teacher sections:', error);
    const sectionsContainer = document.getElementById('mySections');
    if (sectionsContainer) {
      sectionsContainer.innerHTML = `
        <div class="p-6 text-center text-gray-500">
          <p>Error loading sections</p>
        </div>
      `;
    }
  }
}

/*
  Function Name: viewSectionStudents
  Purpose:
  - Displays students in a specific section
  - Can be used to show a modal or navigate to student list

  When it runs:
  - Called when teacher clicks "View Students" button on a section
  - Can be customized to show a modal or new page

  Who can use it:
  - Teacher / Admin

  Backend interaction:
  - Calls getStudentsBySection function which queries users table
  - Filters students by section_id

  Error handling:
  - Handles database query errors
  - Shows message if no students found
*/
async function viewSectionStudents(sectionId, sectionName) {
  try {
    const students = await getStudentsBySection(sectionId);
    
    if (students.length === 0) {
      alert(`No students in ${sectionName}`);
      return;
    }

    // Create a simple alert with student names (can be expanded to a modal)
    const studentNames = students.map(student => student.full_name).join('\n');
    alert(`Students in ${sectionName}:\n\n${studentNames}`);

  } catch (error) {
    console.error('Error viewing section students:', error);
    alert('Error loading students');
  }
}

/**
 * Phase 2 Formal Assessment: Teacher Verification
 * Calls public.verify_assessment_attempt RPC
 */
async function verifyAssessmentAttempt(attemptId, verifiedScore = null, verifiedTotal = null, notes = null) {
  try {
    const { data, error } = await getSupabase().rpc('verify_assessment_attempt', {
      p_attempt_id: attemptId,
      p_verified_score: verifiedScore !== null ? parseInt(verifiedScore, 10) : null,
      p_verified_total: verifiedTotal !== null ? parseInt(verifiedTotal, 10) : null,
      p_verification_notes: notes || null
    });

    if (error) throw error;
    return { success: true, data };
  } catch (error) {
    console.error('Error verifying assessment attempt:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Phase 2 Formal Assessment: Teacher Override on Terminal (3rd) Failed Attempt
 * In-place row update, never creates attempt 4, preserves numeric scores.
 * Calls public.apply_assessment_override RPC
 */
async function applyAssessmentOverride(attemptId, reason) {
  try {
    if (!reason || !reason.trim()) {
      return { success: false, error: 'An override reason is required' };
    }

    const { data, error } = await getSupabase().rpc('apply_assessment_override', {
      p_attempt_id: attemptId,
      p_reason: reason.trim()
    });

    if (error) throw error;
    return { success: true, data };
  } catch (error) {
    console.error('Error applying assessment override:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Phase 2 Regular Quiz: Teacher Override on Terminal (3rd) Failed Submission
 * Calls public.apply_quiz_override RPC
 */
async function applyQuizOverride(submissionId, reason) {
  try {
    if (!reason || !reason.trim()) {
      return { success: false, error: 'An override reason is required' };
    }

    const { data, error } = await getSupabase().rpc('apply_quiz_override', {
      p_submission_id: submissionId,
      p_reason: reason.trim()
    });

    if (error) throw error;
    return { success: true, data };
  } catch (error) {
    console.error('Error applying quiz override:', error);
    return { success: false, error: error.message };
  }
}
