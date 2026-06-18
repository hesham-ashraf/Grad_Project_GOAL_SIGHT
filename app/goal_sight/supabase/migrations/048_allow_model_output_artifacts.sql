-- ============================================================
-- Goal Sight - Raw model-output artifacts
-- File: 048_allow_model_output_artifacts.sql
-- Description:
--   Allows the analysis_artifacts table to store the raw JSON returned by the
--   four ML models before the app normalizes it into match/team/player rows.
--   The app writes these rows with artifact_type = 'model_output' and data:
--     { "model_name": "...", "payload": {...} }
-- Safe to re-run.
-- ============================================================

do $$
declare
  v_constraint text;
begin
  select conname into v_constraint
  from pg_constraint
  where conrelid = 'public.analysis_artifacts'::regclass
    and contype = 'c'
    and pg_get_constraintdef(oid) like '%artifact_type%'
  limit 1;

  if v_constraint is not null then
    execute format(
      'alter table public.analysis_artifacts drop constraint %I',
      v_constraint
    );
  end if;
end $$;

alter table public.analysis_artifacts
  add constraint analysis_artifacts_artifact_type_check
  check (artifact_type in (
    'heatmap',
    'passing_network',
    'formation',
    'pressure_map',
    'attack_zones',
    'momentum',
    'possession_timeline',
    'shot_map',
    'xg_timeline',
    'model_output'
  ));
