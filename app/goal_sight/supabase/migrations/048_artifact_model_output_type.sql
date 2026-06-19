-- ============================================================
-- Goal Sight — Allow 'model_output' analysis artifacts
-- File: 048_artifact_model_output_type.sql
-- Description:
--   The 4 models return 4 JSON payloads per analysed match. We store each raw
--   payload as an analysis_artifacts row (artifact_type = 'model_output',
--   data = { model_name, payload }). The existing artifact_type CHECK only
--   allowed visualization types, so this adds 'model_output' to the domain.
--   Safe to re-run.
-- ============================================================

alter table public.analysis_artifacts
  drop constraint if exists analysis_artifacts_artifact_type_check;

alter table public.analysis_artifacts
  add constraint analysis_artifacts_artifact_type_check
  check (artifact_type = any (array[
    'heatmap', 'passing_network', 'formation', 'pressure_map',
    'attack_zones', 'momentum', 'possession_timeline', 'shot_map',
    'xg_timeline', 'model_output'
  ]));
