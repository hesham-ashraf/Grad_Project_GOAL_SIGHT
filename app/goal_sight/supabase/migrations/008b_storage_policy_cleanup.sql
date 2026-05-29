-- ============================================================
-- Goal Sight MVP - Storage Policy Cleanup
-- File: 008b_storage_policy_cleanup.sql
-- Description:
-- Removes legacy development policies and keeps only
-- the Phase 10 production-ready storage policies.
-- Safe to re-run.
-- ============================================================

-- Remove legacy dev read policies for public buckets
-- (Phase 10 replaces them with production policy names.)
drop policy if exists "Dev read team logos" on storage.objects;
drop policy if exists "Dev read player images" on storage.objects;

-- Remove legacy authenticated upload policies for public buckets
-- (Uploads should be role-based in Phase 10.)
drop policy if exists "Authenticated users can upload team logos" on storage.objects;
drop policy if exists "Authenticated users can upload player images" on storage.objects;

-- Remove legacy authenticated match video policies
-- (Match video access should be role-based in Phase 10.)
drop policy if exists "Authenticated users can upload match videos" on storage.objects;
drop policy if exists "Authenticated users can read own match videos" on storage.objects;
