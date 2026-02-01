# Learning Management System

A modern, interactive learning management system built with HTML, Tailwind CSS, and JavaScript, powered by Supabase for authentication and backend services.

## System Overview

This platform provides a complete learning management solution with role-based access for students, teachers, and administrators. It features interactive lessons, quiz submissions, progress tracking, and comprehensive teacher tools.

## Features

### Student Features:
- User registration and login
- Browse and complete interactive lessons
- Watch video tutorials
- Take quizzes with score tracking
- Submit quiz scores with optional screenshots
- Track learning progress through dashboard
- View submitted quiz statuses

### Teacher Features:
- Create and manage learning modules
- Create and edit lessons with content and videos
- Set quiz links for lessons
- Review and approve quiz submissions
- Reject submissions with feedback
- View student progress reports
- Monitor overall class performance

### Admin Features:
- Manage all users (students, teachers, admins)
- Full system-wide module and lesson management
- View all quiz submissions
- Access system activity logs
- Manage system settings

## Tech Stack

**Frontend:**
- HTML5 with semantic markup
- Tailwind CSS for styling
- Vanilla JavaScript for interactivity
- Responsive design mobile-first approach

**Backend Services (Supabase):**
- Authentication: User registration, login, password reset
- Database: PostgreSQL for data storage
- Storage: File storage for images and documents
- Real-time: Optional real-time features

## Project Structure

```
/project-root
│
├── index.html                    # Root redirect to public/index.html
│
├── /public                       # Public pages (landing, auth)
│   ├── index.html               # Landing page
│   ├── login.html               # User login page
│   ├── register.html            # User registration
│   ├── about.html               # About page
│   ├── contact.html             # Contact page
│   ├── privacy.html             # Privacy policy
│   ├── terms.html               # Terms of service
│   ├── reset-password.html      # Password reset
│   └── tutorial-videos.html     # Public tutorials
│
├── /student                      # Student portal
│   ├── dashboard.html           # Student dashboard
│   ├── modules.html             # Browse modules
│   ├── quizzes.html             # Quiz list
│   ├── lesson-view.html         # Lesson viewer
│   ├── module-view.html         # Module viewer
│   └── /assets
│       ├── /css
│       │   └── student.css      # Student-specific styles
│       └── /js
│           └── student.js       # Student-specific logic
│
├── /teacher                      # Teacher portal
│   ├── dashboard.html           # Teacher dashboard
│   ├── manage-modules.html      # Module management
│   ├── manage-quizzes.html      # Quiz management
│   ├── manage-videos.html       # Video management
│   ├── edit-module.html         # Module editor
│   ├── submissions.html         # Review submissions
│   └── /assets
│       ├── /css
│       │   └── teacher.css      # Teacher-specific styles
│       └── /js
│           └── teacher.js       # Teacher-specific logic
│
├── /admin                        # Admin portal
│   ├── dashboard.html           # Admin dashboard
│   ├── login.html               # Admin login
│   ├── users.html               # User management
│   ├── activity.html            # Activity logs
│   └── /assets
│       ├── /css
│       │   └── admin.css        # Admin-specific styles
│       └── /js
│           └── admin.js         # Admin-specific logic
│
├── /shared                       # Shared resources
│   ├── /css
│   │   └── base.css             # Common base styles
│   └── /js
│       ├── config.js            # App configuration
│       ├── supabase.js          # Supabase client
│       ├── auth.js              # Authentication logic
│       ├── modules.js           # Module/lesson CRUD
│       ├── uploads.js           # File upload handling
│       └── utils.js             # Utility functions
│
├── /Logo                         # Logo images
├── /assets/images               # Static images
├── /database                    # SQL migration files
│
└── README.md                    # This documentation
```

## Folder Organization

### `/public` - Public Pages
Contains pages accessible without authentication (landing, login, register, etc.)

### `/student` - Student Portal  
Contains all student-facing pages with their own CSS and JS assets.

### `/teacher` - Teacher Portal
Contains all teacher-facing pages for content management and grading.

### `/admin` - Admin Portal
Contains all admin-facing pages for system management.

### `/shared` - Shared Resources
Contains common CSS and JavaScript files used across all roles:
- **base.css**: Common styles (variables, typography, components)
- **config.js**: Application configuration
- **supabase.js**: Database client initialization
- **auth.js**: Login, logout, session management
- **modules.js**: Module and lesson CRUD operations
- **uploads.js**: File upload functionality
- **utils.js**: Toast notifications, validation, caching

## Setup Instructions

### Prerequisites:
1. A Supabase account (https://supabase.com)
2. A new Supabase project
3. Database tables created according to the schema

### Configuration:

1. **Supabase Setup:**
   - Create a new project on Supabase
   - Copy your project URL and anonymous key from Settings > API
   - Replace `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `js/supabase.js`

2. **Database Tables:**
   Create the following tables in your Supabase database:

   - `users` - stores user information
   - `modules` - stores learning modules
   - `lessons` - stores individual lessons
   - `quiz_submissions` - stores quiz submission data
   - `lesson_progress` - tracks lesson completion
   - `notifications` - stores user notifications
   - `activity_log` - records system activity

3. **Storage Buckets:**
   Create the following storage buckets:
   - `quiz-screenshots` - for storing quiz submission screenshots
   - `learning-materials` - for storing learning materials

4. **Authentication:**
   - Enable email/password authentication in Supabase
   - Configure redirect URLs if needed

## Usage Instructions

### For Students:
1. Register or login to the system
2. Browse available modules from the student dashboard
3. Click on a module to view lessons
4. Complete lessons and mark them as complete
5. Take quizzes and submit scores
6. Check dashboard for progress

### For Teachers:
1. Login to the system
2. Create and manage modules and lessons
3. Set quiz links for lessons
4. Review pending quiz submissions
5. Approve or reject submissions with feedback
6. View student progress reports

### For Administrators:
1. Login with admin credentials
2. Manage users, modules, and lessons
3. View system activity and statistics
4. Monitor overall platform performance

## Database Schema

### users table:
```sql
create table users (
  id uuid references auth.users on delete cascade,
  email text unique not null,
  full_name text,
  role text check (role in ('student', 'teacher', 'admin')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (id)
);
```

### modules table:
```sql
create table modules (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text,
  order integer,
  is_active boolean default true,
  created_by uuid references users,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);
```

### lessons table:
```sql
create table lessons (
  id uuid default gen_random_uuid() primary key,
  module_id uuid references modules on delete cascade,
  title text not null,
  content text,
  order integer,
  video_url text,
  quiz_url text,
  is_active boolean default true,
  created_by uuid references users,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);
```

### quiz_submissions table:
```sql
create table quiz_submissions (
  id uuid default gen_random_uuid() primary key,
  student_id uuid references users,
  lesson_id uuid references lessons,
  score integer,
  total_items integer,
  screenshot_url text,
  status text check (status in ('pending', 'approved', 'rejected')) default 'pending',
  teacher_comment text,
  reviewed_by uuid references users,
  reviewed_at timestamp with time zone,
  submitted_at timestamp with time zone default timezone('utc'::text, now()) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);
```

### lesson_progress table:
```sql
create table lesson_progress (
  id uuid default gen_random_uuid() primary key,
  student_id uuid references users on delete cascade,
  lesson_id uuid references lessons on delete cascade,
  completed boolean default false,
  completed_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(student_id, lesson_id)
);
```

### notifications table:
```sql
create table notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references users on delete cascade,
  title text not null,
  message text,
  read boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
```

### activity_log table:
```sql
create table activity_log (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references users on delete set null,
  action text not null,
  details text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
```

## Security

- All user inputs are validated
- Role-based access control
- Secure password hashing
- CSRF protection implemented
- SQL injection prevention
- File type validation for uploads

### Row Level Security (RLS) Policies

Enable RLS on all tables and apply the following policies in Supabase:

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

-- users policies
CREATE POLICY "Users can view their own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON users
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can insert users" ON users
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can update users" ON users
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can delete users" ON users
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- modules policies
CREATE POLICY "Anyone can view active modules" ON modules
  FOR SELECT USING (is_active = true);

CREATE POLICY "Teachers and admins can view all modules" ON modules
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
  );

CREATE POLICY "Teachers and admins can create modules" ON modules
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
  );

CREATE POLICY "Teachers and admins can update modules" ON modules
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
  );

CREATE POLICY "Teachers and admins can delete modules" ON modules
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
  );

-- lessons policies
CREATE POLICY "Anyone can view active lessons" ON lessons
  FOR SELECT USING (is_active = true);

CREATE POLICY "Teachers and admins can view all lessons" ON lessons
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
  );

CREATE POLICY "Teachers and admins can create lessons" ON lessons
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
  );

CREATE POLICY "Teachers and admins can update lessons" ON lessons
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
  );

CREATE POLICY "Teachers and admins can delete lessons" ON lessons
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
  );

-- quiz_submissions policies
CREATE POLICY "Students can view their own submissions" ON quiz_submissions
  FOR SELECT USING (student_id = auth.uid());

CREATE POLICY "Teachers and admins can view all submissions" ON quiz_submissions
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
  );

CREATE POLICY "Students can insert submissions" ON quiz_submissions
  FOR INSERT WITH CHECK (student_id = auth.uid());

CREATE POLICY "Teachers and admins can update submissions" ON quiz_submissions
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
  );

-- lesson_progress policies
CREATE POLICY "Students can view their own progress" ON lesson_progress
  FOR SELECT USING (student_id = auth.uid());

CREATE POLICY "Students can insert progress" ON lesson_progress
  FOR INSERT WITH CHECK (student_id = auth.uid());

CREATE POLICY "Students can update their own progress" ON lesson_progress
  FOR UPDATE USING (student_id = auth.uid());

CREATE POLICY "Teachers and admins can view all progress" ON lesson_progress
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
  );

-- notifications policies
CREATE POLICY "Users can view their own notifications" ON notifications
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications" ON notifications
  FOR UPDATE USING (user_id = auth.uid());

-- activity_log policies
CREATE POLICY "Admins can view activity log" ON activity_log
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Authenticated users can insert activity log" ON activity_log
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
```

### Storage Bucket Policies

Apply these policies to your Supabase storage buckets:

```sql
-- quiz-screenshots bucket policies
CREATE POLICY "Students can upload their screenshots" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'quiz-screenshots' AND
    auth.uid() IS NOT NULL
  );

CREATE POLICY "Users can view their own screenshots" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'quiz-screenshots' AND
    (auth.uid()::text = (storage.foldername(name))[1] OR
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher', 'admin')))
  );

-- learning-materials bucket policies
CREATE POLICY "Teachers and admins can upload materials" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'learning-materials' AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
  );

CREATE POLICY "Anyone authenticated can view materials" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'learning-materials' AND
    auth.uid() IS NOT NULL
  );
```

## Development

### Prerequisites:
- VS Code or any code editor
- Live Server extension for VS Code (recommended for local development)
- Git for version control

### Development Workflow:
1. Clone this repository
2. Open in VS Code
3. Install Live Server extension
4. Start Live Server from index.html
5. Make changes to files
6. Preview in browser

## Deployment

### Vercel Deployment:
1. Push code to GitHub repository
2. Connect repository to Vercel
3. Configure build settings (default Vercel settings work)
4. Deploy!

### Other Hosting Options:
- Netlify
- GitHub Pages
- Firebase Hosting
- Any static hosting service

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support, please contact:
- Email: support@example.com
- Phone: +1 (555) 123-4567

## Changelog

### Version 1.0.0 (Current)
- Initial release
- Complete system functionality
- Role-based access control
- Module and lesson management
- Quiz submission system
- Progress tracking
- Admin management tools
