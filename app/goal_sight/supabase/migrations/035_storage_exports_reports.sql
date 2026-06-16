-- ============================================================
-- Goal Sight — Analysis Exports & Report Storage
-- File: 035_storage_exports_reports.sql
-- Description:
--   * Private storage buckets `analysis-exports` and `reports`
--   * `analysis_exports` table  -> AnalysisExportModel (PDF/report references)
--   * `stored_reports` table     -> StoredReportModel (persistent reports)
--   * Role-based RLS + storage policies (admin full; manager owns its own).
-- Safe to re-run.
-- ============================================================

-- ============================================================
-- 1) Buckets (private)
-- ============================================================

insert into storage.buckets (id, name, public)
values
  ('analysis-exports', 'analysis-exports', false),
  ('reports', 'reports', false)
on conflict (id) do nothing;

-- ============================================================
-- 2) analysis_exports table
-- ============================================================

create table if not exists public.analysis_exports (
  id            uuid primary key default gen_random_uuid(),
  analysis_id   uuid references public.match_analyses(id) on delete cascade,
  owner_id      uuid not null default auth.uid(),
  export_type   text not null default 'pdf'
                  check (export_type in ('pdf','tactical_report','player_report','match_summary')),
  title         text not null default 'Analysis Export',
  file_name     text not null,
  storage_path  text not null,
  file_size     bigint not null default 0,
  mime_type     text not null default 'application/pdf',
  created_at    timestamptz not null default now()
);
create index if not exists idx_analysis_exports_analysis on public.analysis_exports(analysis_id);
create index if not exists idx_analysis_exports_owner    on public.analysis_exports(owner_id);

alter table public.analysis_exports enable row level security;

drop policy if exists "Admin full access analysis_exports" on public.analysis_exports;
drop policy if exists "Owner manage analysis_exports"      on public.analysis_exports;
drop policy if exists "Role read analysis_exports"         on public.analysis_exports;

create policy "Admin full access analysis_exports"
  on public.analysis_exports for all to authenticated
  using (public.has_role('admin')) with check (public.has_role('admin'));

create policy "Owner manage analysis_exports"
  on public.analysis_exports for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "Role read analysis_exports"
  on public.analysis_exports for select to authenticated
  using (public.has_role('admin') or public.has_role('manager') or public.has_role('player'));

-- ============================================================
-- 3) stored_reports table
-- ============================================================

create table if not exists public.stored_reports (
  id            uuid primary key default gen_random_uuid(),
  report_type   text not null default 'tactical'
                  check (report_type in ('tactical','ai','player_intelligence','summary')),
  title         text not null,
  owner_id      uuid not null default auth.uid(),
  related_id    uuid,                       -- analysis_id or player_id (loose link)
  file_name     text not null,
  storage_path  text not null,
  file_size     bigint not null default 0,
  mime_type     text not null default 'application/pdf',
  metadata      jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now()
);
create index if not exists idx_stored_reports_owner   on public.stored_reports(owner_id);
create index if not exists idx_stored_reports_type    on public.stored_reports(report_type);
create index if not exists idx_stored_reports_related on public.stored_reports(related_id);

alter table public.stored_reports enable row level security;

drop policy if exists "Admin full access stored_reports" on public.stored_reports;
drop policy if exists "Owner manage stored_reports"      on public.stored_reports;
drop policy if exists "Role read stored_reports"         on public.stored_reports;

create policy "Admin full access stored_reports"
  on public.stored_reports for all to authenticated
  using (public.has_role('admin')) with check (public.has_role('admin'));

create policy "Owner manage stored_reports"
  on public.stored_reports for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "Role read stored_reports"
  on public.stored_reports for select to authenticated
  using (public.has_role('admin') or public.has_role('manager') or public.has_role('player'));

-- ============================================================
-- 4) Storage object policies for the two private buckets
-- ============================================================

drop policy if exists "Admin full access exports bucket"   on storage.objects;
drop policy if exists "Manager manage own exports bucket"  on storage.objects;
drop policy if exists "Role read exports bucket"           on storage.objects;
drop policy if exists "Admin full access reports bucket"   on storage.objects;
drop policy if exists "Manager manage own reports bucket"  on storage.objects;
drop policy if exists "Role read reports bucket"           on storage.objects;

-- analysis-exports
create policy "Admin full access exports bucket"
  on storage.objects for all to authenticated
  using (bucket_id = 'analysis-exports' and public.has_role('admin'))
  with check (bucket_id = 'analysis-exports' and public.has_role('admin'));

create policy "Manager manage own exports bucket"
  on storage.objects for all to authenticated
  using (bucket_id = 'analysis-exports' and public.has_role('manager') and owner = (select auth.uid()))
  with check (bucket_id = 'analysis-exports' and public.has_role('manager') and owner = (select auth.uid()));

create policy "Role read exports bucket"
  on storage.objects for select to authenticated
  using (bucket_id = 'analysis-exports'
         and (public.has_role('admin') or public.has_role('manager') or public.has_role('player')));

-- reports
create policy "Admin full access reports bucket"
  on storage.objects for all to authenticated
  using (bucket_id = 'reports' and public.has_role('admin'))
  with check (bucket_id = 'reports' and public.has_role('admin'));

create policy "Manager manage own reports bucket"
  on storage.objects for all to authenticated
  using (bucket_id = 'reports' and public.has_role('manager') and owner = (select auth.uid()))
  with check (bucket_id = 'reports' and public.has_role('manager') and owner = (select auth.uid()));

create policy "Role read reports bucket"
  on storage.objects for select to authenticated
  using (bucket_id = 'reports'
         and (public.has_role('admin') or public.has_role('manager') or public.has_role('player')));
