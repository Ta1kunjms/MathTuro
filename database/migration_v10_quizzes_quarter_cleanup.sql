-- Replace legacy quiz category/subject schema with quarter-based filtering.
begin;

-- 1) Ensure quarter exists on quizzes.
alter table public.quizzes
add column if not exists quarter smallint;

-- 2) Backfill missing/invalid values so constraints can be enforced.
update public.quizzes
set quarter = 1
where quarter is null
   or quarter < 1
   or quarter > 4;

-- 3) Enforce valid quarter values.
alter table public.quizzes
drop constraint if exists quizzes_quarter_check;

alter table public.quizzes
add constraint quizzes_quarter_check check (quarter between 1 and 4);

alter table public.quizzes
alter column quarter set default 1,
alter column quarter set not null;

-- 4) Remove legacy category indexing/columns.
drop index if exists public.idx_quizzes_category;
alter table public.quizzes drop column if exists category;
alter table public.quizzes drop column if exists subject;

-- 5) Add quarter index for tabs/filter performance.
create index if not exists idx_quizzes_quarter on public.quizzes (quarter);

commit;
