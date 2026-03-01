-- Fix: missing public.lesson_plans table
-- Safe to run multiple times.

create extension if not exists pgcrypto;

create table if not exists public.lesson_plans (
    id uuid primary key default gen_random_uuid(),
    teacher_id uuid references public.users(id) on delete set null,
    title text not null,
    description text,
    grade_level text,
    status text not null default 'draft',
    file_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table public.lesson_plans add column if not exists teacher_id uuid references public.users(id) on delete set null;
alter table public.lesson_plans add column if not exists title text;
alter table public.lesson_plans add column if not exists description text;
alter table public.lesson_plans add column if not exists grade_level text;
alter table public.lesson_plans add column if not exists status text default 'draft';
alter table public.lesson_plans add column if not exists file_url text;
alter table public.lesson_plans add column if not exists created_at timestamptz default now();
alter table public.lesson_plans add column if not exists updated_at timestamptz default now();

create index if not exists idx_lesson_plans_teacher_id on public.lesson_plans(teacher_id);
create index if not exists idx_lesson_plans_created_at on public.lesson_plans(created_at desc);

alter table public.lesson_plans enable row level security;

drop policy if exists lesson_plans_select_policy on public.lesson_plans;
create policy lesson_plans_select_policy
on public.lesson_plans
for select
to authenticated
using (
  teacher_id = auth.uid()
  or exists (
    select 1
    from public.users u
    where u.id = auth.uid()
      and u.role in ('admin', 'teacher')
  )
);

drop policy if exists lesson_plans_insert_policy on public.lesson_plans;
create policy lesson_plans_insert_policy
on public.lesson_plans
for insert
to authenticated
with check (
  teacher_id = auth.uid()
  or exists (
    select 1
    from public.users u
    where u.id = auth.uid()
      and u.role = 'admin'
  )
);

drop policy if exists lesson_plans_update_policy on public.lesson_plans;
create policy lesson_plans_update_policy
on public.lesson_plans
for update
to authenticated
using (
  teacher_id = auth.uid()
  or exists (
    select 1
    from public.users u
    where u.id = auth.uid()
      and u.role = 'admin'
  )
)
with check (
  teacher_id = auth.uid()
  or exists (
    select 1
    from public.users u
    where u.id = auth.uid()
      and u.role = 'admin'
  )
);

drop policy if exists lesson_plans_delete_policy on public.lesson_plans;
create policy lesson_plans_delete_policy
on public.lesson_plans
for delete
to authenticated
using (
  teacher_id = auth.uid()
  or exists (
    select 1
    from public.users u
    where u.id = auth.uid()
      and u.role = 'admin'
  )
);
