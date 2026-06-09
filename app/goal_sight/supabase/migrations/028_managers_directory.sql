-- ============================================================
-- Goal Sight — Managers directory table
-- File: 028_managers_directory.sql
-- Description:
--   Admin-managed manager directory. These are records the admin oversees
--   (add / disable / set permissions) and may optionally link to a real login
--   account via profile_id. Distinct from profiles(role='manager') which are
--   the actual login users.
-- Safe to re-run.
-- ============================================================

create table if not exists public.managers (
  id               uuid primary key default gen_random_uuid(),
  profile_id       uuid references public.profiles(id) on delete set null,
  name             text not null,
  email            text,
  image_url        text,
  upload_count     integer not null default 0,
  matches_analyzed integer not null default 0,
  tactical_rating  numeric(3,1) not null default 0,
  last_active      timestamptz,
  is_active        boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index if not exists idx_managers_profile_id on public.managers(profile_id);
create index if not exists idx_managers_is_active  on public.managers(is_active);

drop trigger if exists trg_managers_updated_at on public.managers;
create trigger trg_managers_updated_at before update on public.managers
  for each row execute function public.set_updated_at();

alter table public.managers enable row level security;
drop policy if exists "Admin full access managers" on public.managers;
drop policy if exists "Role read managers" on public.managers;
create policy "Admin full access managers" on public.managers
  for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy "Role read managers" on public.managers
  for select to authenticated using (public.has_role('admin') or public.has_role('manager'));
