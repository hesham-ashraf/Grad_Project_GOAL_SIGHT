-- ============================================================
-- Goal Sight — Club-scope the match-videos storage bucket
-- File: 047_match_videos_club_scope.sql
-- Description:
--   The match-videos bucket previously allowed ANY manager/admin to read or
--   upload (role-only policies). This isolates raw video files per club: an
--   object is reachable only by the admin/managers of the club that owns it.
--   Tenancy is encoded in the object path as the FIRST folder segment:
--       <club_id>/<uploader_uid>/<timestamp>_<filename>
--   so (storage.foldername(name))[1] must equal the caller's club_id.
--   Safe to re-run.
-- ============================================================

-- Drop the old role-only policies (and the dead 'player' one).
drop policy if exists "Admin full access match videos" on storage.objects;
drop policy if exists "Manager read match videos"      on storage.objects;
drop policy if exists "Manager upload match videos"    on storage.objects;
drop policy if exists "Player read match videos"       on storage.objects;

-- One club-scoped policy covering read/insert/update/delete for the owning
-- club's admin + managers. auth_club_id() is null for users without a club,
-- so the path comparison fails closed (no access).
drop policy if exists "match_videos_club_all" on storage.objects;
create policy "match_videos_club_all" on storage.objects
  for all to authenticated
  using (
    bucket_id = 'match-videos'
    and public.auth_role() in ('admin','manager')
    and (storage.foldername(name))[1] = public.auth_club_id()::text
  )
  with check (
    bucket_id = 'match-videos'
    and public.auth_role() in ('admin','manager')
    and (storage.foldername(name))[1] = public.auth_club_id()::text
  );
