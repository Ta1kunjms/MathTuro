-- Add quarter support to modules
alter table public.modules
add column if not exists quarter smallint;

-- Backfill existing rows to Quarter 1 so NOT NULL can be enforced safely
update public.modules
set quarter = 1
where quarter is null;

-- Enforce valid quarter values
alter table public.modules
drop constraint if exists modules_quarter_check;

alter table public.modules
add constraint modules_quarter_check check (quarter between 1 and 4);

-- Require a quarter and set default for compatibility
alter table public.modules
alter column quarter set default 1,
alter column quarter set not null;

-- Optional performance helper for quarter tab filtering
create index if not exists idx_modules_quarter on public.modules (quarter);
