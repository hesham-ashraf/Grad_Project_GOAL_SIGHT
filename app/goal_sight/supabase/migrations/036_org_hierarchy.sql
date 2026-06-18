-- ============================================================
-- 036 — Org hierarchy: admin owns a club; managers scoped to it
-- ============================================================
-- Model: one admin  = one club (club owner).
--        managers that belong to that admin share the same club_id.
-- Impact: admin sees ONLY data produced by his club's managers.
-- ============================================================

-- 1. Add club_id to profiles (nullable; populated for admin + manager roles).
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS club_id uuid REFERENCES public.teams (id) ON DELETE SET NULL;

-- Index for fast per-club lookups.
CREATE INDEX IF NOT EXISTS idx_profiles_club_id ON public.profiles (club_id);

-- 2. Mark the first seeded team as owned by each seeded admin profile.
--    (Replace with real admin UUIDs via seed data or Supabase UI for fresh envs.)
UPDATE public.profiles p
SET club_id = (
  SELECT t.id FROM public.teams t
  ORDER BY t.created_at
  LIMIT 1
)
WHERE p.role = 'admin'
  AND p.club_id IS NULL;

-- 3. Propagate the same club_id to all managers.
UPDATE public.profiles p
SET club_id = (
  SELECT p2.club_id FROM public.profiles p2 WHERE p2.role = 'admin' LIMIT 1
)
WHERE p.role = 'manager'
  AND p.club_id IS NULL;

-- 4. Mirror club_id onto the managers directory table so queries are simple.
ALTER TABLE public.managers
  ADD COLUMN IF NOT EXISTS club_id uuid REFERENCES public.teams (id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_managers_club_id ON public.managers (club_id);

UPDATE public.managers m
SET club_id = (
  SELECT p.club_id FROM public.profiles p WHERE p.id = m.profile_id LIMIT 1
)
WHERE m.club_id IS NULL;

-- 5. Helper function: returns the club_id for the currently signed-in user.
CREATE OR REPLACE FUNCTION public.auth_club_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT club_id FROM public.profiles WHERE id = auth.uid();
$$;

-- 6. RLS — profiles: users can see other profiles in the same club.
DROP POLICY IF EXISTS "profiles_same_club_select" ON public.profiles;
CREATE POLICY "profiles_same_club_select" ON public.profiles
  FOR SELECT USING (
    club_id = public.auth_club_id()
    OR id = auth.uid()
  );

-- 7. RLS — managers directory: admin/manager can see managers in their club.
DROP POLICY IF EXISTS "managers_club_select" ON public.managers;
CREATE POLICY "managers_club_select" ON public.managers
  FOR SELECT USING (
    club_id = public.auth_club_id()
    OR public.auth_club_id() IS NULL  -- fallback: allow if club not yet assigned
  );

-- 8. RLS — match_analyses: scoped to club via the manager who created it.
DROP POLICY IF EXISTS "analyses_club_select" ON public.match_analyses;
CREATE POLICY "analyses_club_select" ON public.match_analyses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = match_analyses.generated_by
        AND p.club_id = public.auth_club_id()
    )
    OR generated_by = auth.uid()
    OR public.auth_club_id() IS NULL
  );

-- 9. RLS — upload_jobs: scoped similarly.
DROP POLICY IF EXISTS "upload_jobs_club_select" ON public.upload_jobs;
CREATE POLICY "upload_jobs_club_select" ON public.upload_jobs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = upload_jobs.uploaded_by
        AND p.club_id = public.auth_club_id()
    )
    OR uploaded_by = auth.uid()
    OR public.auth_club_id() IS NULL
  );
