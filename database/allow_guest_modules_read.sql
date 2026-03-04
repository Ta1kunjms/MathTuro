-- Allow guests (anon role) to see ALL modules without login/token.
-- Run in Supabase SQL Editor.

begin;

-- Ensure anon can read the table
grant select on table public.modules to anon;

-- Remove restrictive guest-select policies if present
-- (keep teacher/admin/student scoped policies for authenticated users)
drop policy if exists "modules_guest_read_all" on public.modules;
drop policy if exists "modules_read_published" on public.modules;

-- Guest/anonymous read-all policy
create policy "modules_guest_read_all"
on public.modules
for select
to anon
using (true);

commit;
