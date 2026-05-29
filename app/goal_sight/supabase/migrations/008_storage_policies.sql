-- ============================================================
-- Goal Sight MVP - Storage Policies
-- File: 008_storage_policies.sql
-- Description:
-- Role-based access for Supabase Storage buckets.
-- Safe to re-run.
-- ============================================================

-- Drop old policies if re-running

drop policy if exists "Public read team logos" on storage.objects;
drop policy if exists "Public read player images" on storage.objects;

drop policy if exists "Admin full access match videos" on storage.objects;
drop policy if exists "Manager read match videos" on storage.objects;
drop policy if exists "Manager upload match videos" on storage.objects;
drop policy if exists "Player read match videos" on storage.objects;

-- Public read for team logos
create policy "Public read team logos"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'team-logos');

-- Public read for player images
create policy "Public read player images"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'player-images');

-- Match videos bucket: role-based access
-- Admin: upload, update, delete, read
create policy "Admin full access match videos"
on storage.objects
for all
to authenticated
using (
  bucket_id = 'match-videos' and public.has_role('admin')
)
with check (
  bucket_id = 'match-videos' and public.has_role('admin')
);

-- Manager: upload + read
create policy "Manager read match videos"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'match-videos' and public.has_role('manager')
);

create policy "Manager upload match videos"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'match-videos' and public.has_role('manager')
);

-- Player: read only
create policy "Player read match videos"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'match-videos' and public.has_role('player')
);
