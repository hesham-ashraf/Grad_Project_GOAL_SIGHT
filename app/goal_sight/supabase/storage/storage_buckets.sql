-- ============================================================
-- Goal Sight MVP - Supabase Storage Buckets
-- File: storage_buckets.sql
-- Description:
-- Creates storage buckets needed by the Goal Sight backend.
--
-- Buckets:
-- 1. match-videos  -> uploaded match footage
-- 2. team-logos    -> team logo images
-- 3. player-images -> player profile images
-- ============================================================

-- Create bucket for match videos
insert into storage.buckets (id, name, public)
values ('match-videos', 'match-videos', false)
on conflict (id) do nothing;

-- Create bucket for team logos
insert into storage.buckets (id, name, public)
values ('team-logos', 'team-logos', true)
on conflict (id) do nothing;

-- Create bucket for player images
insert into storage.buckets (id, name, public)
values ('player-images', 'player-images', true)
on conflict (id) do nothing;

-- ============================================================
-- Storage Policies
--
-- Development/MVP Notes:
-- - team-logos and player-images are public read buckets.
-- - match-videos are private because match footage can be sensitive.
-- - For production, upload permissions should be restricted to admins/coaches.
-- ============================================================

-- Remove old policies if re-running
drop policy if exists "Dev read team logos" on storage.objects;
drop policy if exists "Dev read player images" on storage.objects;
drop policy if exists "Authenticated users can upload team logos" on storage.objects;
drop policy if exists "Authenticated users can upload player images" on storage.objects;
drop policy if exists "Authenticated users can upload match videos" on storage.objects;
drop policy if exists "Authenticated users can read own match videos" on storage.objects;

-- Public read for public image buckets
create policy "Dev read team logos"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'team-logos');

create policy "Dev read player images"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'player-images');

-- Authenticated uploads for MVP development
create policy "Authenticated users can upload team logos"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'team-logos');

create policy "Authenticated users can upload player images"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'player-images');

create policy "Authenticated users can upload match videos"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'match-videos');

-- Authenticated users can read match videos during MVP development
-- Production should restrict this by role/team/subscription.
create policy "Authenticated users can read own match videos"
on storage.objects
for select
to authenticated
using (bucket_id = 'match-videos');