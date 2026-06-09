-- ============================================================
-- Goal Sight — Seed manager upload history (DEV SEED)
-- File: 027_seed_upload_jobs.sql
-- Description:
--   Mirrors upload_history_mock_data.dart into upload_jobs, owned by the demo
--   manager (manager@goalsight.ai). created_at carries the model's uploadedAt.
-- DEV ONLY. Idempotent (skips if any job already has a file_name).
-- ============================================================

do $$
declare mgr uuid;
begin
  if exists (select 1 from public.upload_jobs where file_name is not null) then return; end if;
  select p.id into mgr from public.profiles p
    join auth.users u on u.id = p.id where u.email = 'manager@goalsight.ai' limit 1;

  insert into public.upload_jobs
    (uploaded_by, status, ui_status, progress, home_team, away_team, competition, venue,
     match_date, file_name, created_at, intensity_score, match_score, tactical_summary,
     error_message, processing_stage)
  values
    (mgr,'completed','completed',100,'GoalSight FC','Falcons United','Premier League','GoalSight Arena',
      '2025-05-02','match_goalsight_vs_falcons_may2.mp4','2025-05-02 21:15',92,'3 - 1',
      'GoalSight controlled central zones with high-press triggers. Wide overloads created 6 high-value chances.',null,null),
    (mgr,'completed','completed',100,'Sharks FC','GoalSight FC','Premier League','Shark Tank Stadium',
      '2025-04-28','match_sharks_vs_goalsight_apr28.mp4','2025-04-28 22:40',65,'0 - 0',
      'Defensive solidity throughout. Mid-block held shape well; limited Sharks to 3 shots on target.',null,null),
    (mgr,'completed','completed',100,'Lions City','GoalSight FC','League Cup','Lions Den',
      '2025-04-22','cup_lions_vs_goalsight_apr22.mp4','2025-04-22 20:05',78,'1 - 2',
      'Strong second-half comeback. Tactical switch to 3-5-2 at HT created numerical advantage.',null,null),
    (mgr,'failed','failed',34,'GoalSight FC','Panthers FC','Premier League','GoalSight Arena',
      '2025-04-16','match_goalsight_vs_panthers_apr16.mp4','2025-04-16 19:30',null,null,null,
      'Video file corrupted at timestamp 42:18. Re-encode and retry.',null),
    (mgr,'completed','completed',100,'Eagles Club','GoalSight FC','Premier League','Eagles Nest',
      '2025-04-10','match_eagles_vs_goalsight_apr10.mp4','2025-04-10 22:15',84,'1 - 3',
      'Clinical counter-attacking performance. Fast transitions from back three led to all three goals.',null,null),
    (mgr,'failed','failed',0,'GoalSight FC','Wolves United','FA Cup','GoalSight Arena',
      '2025-04-04','facup_goalsight_vs_wolves_apr4.mp4','2025-04-04 21:50',null,null,null,
      'Unsupported resolution (8K). Please compress to 4K maximum.',null),
    (mgr,'completed','completed',100,'GoalSight FC','Red Lions','Premier League','GoalSight Arena',
      '2025-03-29','match_goalsight_vs_redlions_mar29.mp4','2025-03-29 22:10',71,'2 - 0',
      'Possession-dominant display with 64% control. Midfield pressed well above the halfway line.',null,null),
    (mgr,'processing','processing',62,'GoalSight FC','Falcons United','Premier League','GoalSight Arena',
      '2025-05-15','match_goalsight_vs_falcons_may15.mp4','2025-05-15 23:00',null,null,null,
      null,'generatingInsights');

  update public.upload_jobs set updated_at = created_at where file_name is not null;
end $$;
