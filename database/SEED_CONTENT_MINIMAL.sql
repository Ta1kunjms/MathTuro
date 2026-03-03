-- ============================================================
-- SEED MINIMAL CONTENT (ONE RUN)
-- Creates sample modules, lessons, videos, quizzes if tables are empty.
-- ============================================================

BEGIN;

-- Pick one teacher/admin owner for seeded content
WITH owner_user AS (
  SELECT id
  FROM public.users
  WHERE role IN ('teacher', 'admin')
  ORDER BY created_at
  LIMIT 1
)
INSERT INTO public.modules (
  title, description, teacher_id, status, is_active, "order", order_index, created_at, updated_at
)
SELECT
  seed.title,
  seed.description,
  o.id,
  'published',
  true,
  seed.sort_order,
  seed.sort_order,
  NOW(),
  NOW()
FROM owner_user o
CROSS JOIN (
  VALUES
    ('Numbers and Operations', 'Core arithmetic and number sense lessons', 1),
    ('Intro to Algebra', 'Variables, expressions, and simple equations', 2),
    ('Geometry Basics', 'Angles, shapes, perimeter, and area', 3)
) AS seed(title, description, sort_order)
WHERE NOT EXISTS (SELECT 1 FROM public.modules);

-- Lessons per module (only if module has zero lessons)
INSERT INTO public.lessons (
  module_id, title, content, "order", order_index, created_at, updated_at
)
SELECT
  m.id,
  lesson_seed.title,
  lesson_seed.content,
  lesson_seed.sort_order,
  lesson_seed.sort_order,
  NOW(),
  NOW()
FROM public.modules m
JOIN LATERAL (
  VALUES
    ('Lesson 1', 'Introduction and key concepts', 1),
    ('Lesson 2', 'Worked examples', 2),
    ('Lesson 3', 'Practice and recap', 3)
) AS lesson_seed(title, content, sort_order) ON TRUE
WHERE NOT EXISTS (
  SELECT 1 FROM public.lessons l WHERE l.module_id = m.id
);

-- Videos (minimal)
WITH owner_user AS (
  SELECT id
  FROM public.users
  WHERE role IN ('teacher', 'admin')
  ORDER BY created_at
  LIMIT 1
)
INSERT INTO public.videos (
  title, description, video_url, teacher_id, status, is_published, created_at, updated_at
)
SELECT
  seed.title,
  seed.description,
  seed.video_url,
  o.id,
  'active',
  true,
  NOW(),
  NOW()
FROM owner_user o
CROSS JOIN (
  VALUES
    ('Understanding Fractions', 'Quick walkthrough on fraction basics', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
    ('Linear Equations Intro', 'Solve one-variable equations', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ')
) AS seed(title, description, video_url)
WHERE NOT EXISTS (SELECT 1 FROM public.videos);

-- Quizzes (minimal)
WITH owner_user AS (
  SELECT id
  FROM public.users
  WHERE role IN ('teacher', 'admin')
  ORDER BY created_at
  LIMIT 1
)
INSERT INTO public.quizzes (
  title, description, quiz_url, total_items, teacher_id, status, is_published, created_at, updated_at
)
SELECT
  seed.title,
  seed.description,
  seed.quiz_url,
  seed.total_items,
  o.id,
  'active',
  true,
  NOW(),
  NOW()
FROM owner_user o
CROSS JOIN (
  VALUES
    ('Numbers Quiz 1', 'Basic arithmetic check', 'https://forms.gle/example1', 10),
    ('Algebra Quiz 1', 'Variables and equations check', 'https://forms.gle/example2', 10)
) AS seed(title, description, quiz_url, total_items)
WHERE NOT EXISTS (SELECT 1 FROM public.quizzes);

COMMIT;

-- Verify
-- SELECT COUNT(*) AS modules_total FROM public.modules;
-- SELECT COUNT(*) AS lessons_total FROM public.lessons;
-- SELECT COUNT(*) AS videos_total FROM public.videos;
-- SELECT COUNT(*) AS quizzes_total FROM public.quizzes;
