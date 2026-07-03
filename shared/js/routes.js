/**
 * routes.js — Shared application routes config
 */
const MathTuroRoutes = {
  public: [
    { path: '/', title: 'Home' },
    { path: '/login', title: 'Login' },
    { path: '/register', title: 'Register' },
    { path: '/about', title: 'About' },
    { path: '/contact', title: 'Contact' },
    { path: '/modules', title: 'Modules' },
    { path: '/tutorial-videos', title: 'Tutorial Videos' }
  ],
  student: [
    { path: '/student/dashboard.html', title: 'Student Dashboard', icon: 'home' },
    { path: '/student/modules.html', title: 'Modules', parent: '/student/dashboard.html' },
    { path: '/student/module-view.html', title: 'Module View', parent: '/student/modules.html' },
    { path: '/student/quizzes.html', title: 'Quizzes', parent: '/student/dashboard.html' }
  ],
  teacher: [
    { path: '/teacher/dashboard.html', title: 'Teacher Dashboard', icon: 'home' },
    { path: '/teacher/manage-modules.html', title: 'Manage Modules', parent: '/teacher/dashboard.html' },
    { path: '/teacher/manage-quizzes.html', title: 'Manage Quizzes', parent: '/teacher/dashboard.html' },
    { path: '/teacher/manage-videos.html', title: 'Manage Videos', parent: '/teacher/dashboard.html' },
    { path: '/teacher/student-progress.html', title: 'Student Progress', parent: '/teacher/dashboard.html' },
    { path: '/teacher/reports.html', title: 'Reports', parent: '/teacher/dashboard.html' },
    { path: '/teacher/submissions.html', title: 'Submissions', parent: '/teacher/dashboard.html' }
  ],
  admin: [
    { path: '/admin/dashboard.html', title: 'Admin Dashboard', icon: 'home' },
    { path: '/admin/users.html', title: 'Users', parent: '/admin/dashboard.html' },
    { path: '/admin/grade-levels.html', title: 'Grade Levels & Sections', parent: '/admin/dashboard.html' },
    { path: '/admin/lesson-plan.html', title: 'Lesson Plans', parent: '/admin/dashboard.html' },
    { path: '/admin/manage-modules.html', title: 'Manage Modules', parent: '/admin/dashboard.html' },
    { path: '/admin/manage-videos.html', title: 'Manage Videos', parent: '/admin/dashboard.html' },
    { path: '/admin/manage-quizzes.html', title: 'Manage Quizzes', parent: '/admin/dashboard.html' },
    { path: '/admin/activity.html', title: 'Activity Log', parent: '/admin/dashboard.html' },
    { path: '/admin/analytics.html', title: 'Analytics', parent: '/admin/dashboard.html' },
    { path: '/admin/system-status.html', title: 'System Status', parent: '/admin/dashboard.html' },
    { path: '/admin/settings.html', title: 'Settings', parent: '/admin/dashboard.html' }
  ]
};

if (typeof module !== 'undefined') {
  module.exports = MathTuroRoutes;
} else {
  window.MathTuroRoutes = MathTuroRoutes;
}
