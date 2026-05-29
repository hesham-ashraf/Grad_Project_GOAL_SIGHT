-- ============================================================
-- Goal Sight MVP - Upload Jobs Table
-- File: 011_upload_jobs.sql
-- Description:
-- Adds upload_jobs to track video upload progress and processing.
-- Safe to re-run.
-- ============================================================

create table if not exists public.upload_jobs (
  id uuid primary key default gen_random_uuid(),
  -- Links each job to a video record
  video_id uuid references public.videos(id) on delete set null,
  -- Who initiated the upload job
  uploaded_by uuid references public.profiles(id) on delete set null,
  status text not null default 'uploaded',
  progress integer not null default 0,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint upload_jobs_status_check
  check (status in ('uploaded', 'processing', 'analyzing', 'completed', 'failed'))
);

-- Indexes for faster queries
create index if not exists idx_upload_jobs_video_id
on public.upload_jobs(video_id);

create index if not exists idx_upload_jobs_uploaded_by
on public.upload_jobs(uploaded_by);

create index if not exists idx_upload_jobs_status
on public.upload_jobs(status);
