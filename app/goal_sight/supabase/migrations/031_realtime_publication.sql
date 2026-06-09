-- ============================================================
-- Goal Sight - Phase 13 Realtime Publication
-- File: 031_realtime_publication.sql
-- Description:
--   Enables Supabase Realtime for backend tables that drive live
--   upload progress, processing state, live match timelines,
--   notification delivery, and activity feed updates.
-- Safe to re-run.
-- ============================================================

do $$
declare
  target_table text;
  realtime_tables text[] := array[
    -- Match screen score/status updates.
    'matches',
    -- Match timeline inserts such as goals, cards, shots, and fouls.
    'match_events',
    -- Live player stat refreshes during and after analysis.
    'player_match_stats',
    -- AI tracking samples used by live/analysis visualizations.
    'tracking_snapshots',
    -- Video processing status updates.
    'videos',
    -- Upload progress and AI processing progress updates.
    'upload_jobs',
    -- Per-user notification delivery and read-state updates.
    'notifications',
    -- Admin/user activity feed inserts.
    'activity_logs'
  ];
begin
  -- Supabase projects normally create this publication automatically.
  -- This guard keeps local/rebuilt databases from failing if it is absent.
  if not exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) then
    create publication supabase_realtime;
  end if;

  foreach target_table in array realtime_tables loop
    -- Full replica identity gives clients complete OLD rows on update/delete
    -- payloads, which is useful for progress bars, status transitions, and
    -- removing events from local caches.
    execute format('alter table public.%I replica identity full', target_table);

    -- ALTER PUBLICATION has no IF NOT EXISTS form, so check catalog state first.
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = target_table
    ) then
      execute format('alter publication supabase_realtime add table public.%I', target_table);
    end if;
  end loop;
end $$;

comment on table public.upload_jobs is
  'Tracks manager video upload and AI processing progress; included in Supabase Realtime for live progress updates.';

comment on table public.videos is
  'Stores uploaded match video metadata and processing_status; included in Supabase Realtime for processing state updates.';

comment on table public.matches is
  'Stores match status and score state; included in Supabase Realtime for live score updates.';

comment on table public.match_events is
  'Stores live match timeline events; included in Supabase Realtime for timeline updates.';

comment on table public.notifications is
  'Stores per-user notifications; included in Supabase Realtime for live delivery and read-state updates.';

comment on table public.activity_logs is
  'Stores user/admin activity feed entries; included in Supabase Realtime for feed updates.';
