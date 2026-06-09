-- ============================================================
-- Goal Sight — upload_jobs view-model fields
-- File: 026_upload_jobs_viewmodel_fields.sql
-- Description:
--   Adds the denormalized columns the Flutter UploadJobModel needs (match
--   metadata, file name, UI status/stage, AI result summary) so the
--   SupabaseUploadRepository can reconstruct a manager's upload history.
--   `ui_status` holds the model's UploadStatus.name (queued/uploading/...),
--   distinct from the existing lifecycle `status` CHECK column.
-- Safe to re-run.
-- ============================================================

alter table public.upload_jobs add column if not exists home_team        text;
alter table public.upload_jobs add column if not exists away_team        text;
alter table public.upload_jobs add column if not exists competition      text;
alter table public.upload_jobs add column if not exists venue            text;
alter table public.upload_jobs add column if not exists match_date       timestamptz;
alter table public.upload_jobs add column if not exists file_name        text;
alter table public.upload_jobs add column if not exists ui_status        text;
alter table public.upload_jobs add column if not exists notes            text;
alter table public.upload_jobs add column if not exists intensity_score  integer;
alter table public.upload_jobs add column if not exists match_score      text;
alter table public.upload_jobs add column if not exists tactical_summary text;
alter table public.upload_jobs add column if not exists processing_stage text;
