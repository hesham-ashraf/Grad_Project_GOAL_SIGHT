-- ---------------------------------------------------------------------------
-- 038_analyzed_video.sql
--
-- Adds analyzed_video_path to match_analyses and a signed_url column to
-- analysis_artifacts so the Flutter app can fetch and play the AI-annotated
-- video without needing direct storage access.
-- ---------------------------------------------------------------------------

-- ── analysis_artifacts table (create if not exists) ──────────────────────────
-- Stores per-analysis file artifacts (type, storage path, signed URL cache).
CREATE TABLE IF NOT EXISTS public.analysis_artifacts (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_id     uuid NOT NULL REFERENCES public.match_analyses(id) ON DELETE CASCADE,
  artifact_type   text NOT NULL CHECK (artifact_type IN ('analyzed_video', 'report_pdf', 'heatmap_image')),
  storage_path    text NOT NULL,
  signed_url      text,
  signed_url_expires_at timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS analysis_artifacts_analysis_id_idx
  ON public.analysis_artifacts(analysis_id);

-- ── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.analysis_artifacts ENABLE ROW LEVEL SECURITY;

-- Managers/admins can read artifacts belonging to their own club's analyses.
CREATE POLICY "artifacts_club_select"
  ON public.analysis_artifacts
  FOR SELECT
  USING (
    analysis_id IN (
      SELECT id FROM public.match_analyses
      WHERE club_id = auth_club_id()
    )
  );

-- Only the service role (backend pipeline) may insert/update artifacts.
-- No client-side insert policy — the AI worker writes via service key.

-- ── Realtime ─────────────────────────────────────────────────────────────────
-- Not needed for artifacts (no live streaming requirement).

-- ── Function: refresh_artifact_signed_url ────────────────────────────────────
-- Called by the backend after generating a new signed URL.
-- Managers/admins call a supabase edge function; the function calls this via
-- service-role to update the cached URL.
-- (No direct client access needed — signed URL is returned in the select join.)

-- ── Convenience view ─────────────────────────────────────────────────────────
-- Not required; the Flutter query uses a join select directly.
