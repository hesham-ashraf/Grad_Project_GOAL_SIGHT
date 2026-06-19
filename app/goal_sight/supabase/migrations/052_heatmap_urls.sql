-- ============================================================
-- Goal Sight — Heatmap PNG URLs
-- File: 052_heatmap_urls.sql
-- Description:
--   The AI pipeline returns, per analysed match:
--     • one OVERALL match heatmap PNG  → shown in the match analysis screen
--     • one heatmap PNG PER PLAYER      → shown as a labelled history on the
--                                         player's profile ("vs Zamalek", ...)
--   The model delivers these as URLs (it uploads the PNGs and returns the URL).
--   We persist the URL on the existing rows:
--     • match_analyses.heatmap_url        (overall)
--     • match_player_analysis.heatmap_url (per player, per match — the history
--       is just all of a player's match_player_analysis rows joined to the match)
--   Idempotent.
-- ============================================================

alter table public.match_analyses
  add column if not exists heatmap_url text;

alter table public.match_player_analysis
  add column if not exists heatmap_url text;
