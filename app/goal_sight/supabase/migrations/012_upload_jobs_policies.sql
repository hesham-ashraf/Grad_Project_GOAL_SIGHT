-- ============================================================
-- Goal Sight MVP - Upload Jobs RLS Policies
-- File: 012_upload_jobs_policies.sql
-- Description:
-- Role-based access for upload_jobs.
-- Safe to re-run.
-- ============================================================

-- Ensure RLS is enabled
alter table public.upload_jobs enable row level security;

-- Drop old policies if re-running

drop policy if exists "Admin full access upload jobs" on public.upload_jobs;
drop policy if exists "Manager create upload jobs" on public.upload_jobs;
drop policy if exists "Manager read own upload jobs" on public.upload_jobs;
drop policy if exists "Manager update own upload jobs" on public.upload_jobs;

-- Admin: full access
create policy "Admin full access upload jobs"
on public.upload_jobs
for all
to authenticated
using (public.has_role('admin'))
with check (public.has_role('admin'));

-- Manager: create jobs
create policy "Manager create upload jobs"
on public.upload_jobs
for insert
to authenticated
with check (
  public.has_role('manager') and uploaded_by = auth.uid()
);

-- Manager: view own jobs
create policy "Manager read own upload jobs"
on public.upload_jobs
for select
to authenticated
using (
  public.has_role('manager') and uploaded_by = auth.uid()
);

-- Manager: update own jobs
create policy "Manager update own upload jobs"
on public.upload_jobs
for update
to authenticated
using (
  public.has_role('manager') and uploaded_by = auth.uid()
)
with check (
  public.has_role('manager') and uploaded_by = auth.uid()
);
