-- ============================================================
-- Goal Sight — Seed Player Intelligence & Risk Analysis
-- File: 034_seed_player_intelligence.sql
-- Description:
--   Seeds player_intelligence (PlayerProfileModel enrichment) and
--   player_risk_analysis (RiskAnalysisModel snapshots) for all
--   seeded players. Safe to re-run (INSERT … ON CONFLICT DO UPDATE).
-- ============================================================

-- ============================================================
-- 1) player_intelligence
-- ============================================================

insert into public.player_intelligence (
  player_id, current_rating, average_rating, fatigue, activity_level,
  primary_contribution, secondary_contribution, trend, status, improvement_rate,
  insights, ratings_history,
  total_matches, total_goals, total_assists, total_tackles,
  work_rate, tactical_impact, injury_risk
)
select
  p.id,
  v.cr, v.ar, v.fatigue, v.activity,
  v.primary_c, v.secondary_c, v.trend, v.status, v.imp_rate,
  v.insights::jsonb, v.ratings_history::jsonb,
  v.matches, v.goals, v.assists, v.tackles,
  v.work_rate, v.tactical_impact, v.injury_risk
from public.players p
join (values
  -- GoalSight FC
  ('Hassan Ali',       9.1, 8.8, 44, 91, 'Attack',   'Balanced', 'stable',    'Elite Form',      3.2,
   '["Relentless pressing triggers opponent errors","Clinical finishing — 51% shot conversion","Exceptional acceleration in 1v1","Defensive tracking improved this season"]',
   '[8.5,8.8,9.0,8.7,9.1,8.9,9.2,9.1]', 12, 8, 10, 0, 91.0, 88.0, 18.0),

  ('Mostafa Samir',    8.4, 8.2, 52, 89, 'Attack',   'Balanced', 'improving', 'Explosive Form',  5.1,
   '["Electrifying on the left flank","Won 78% of dribble attempts","Scored in 6 consecutive matches","Needs to track back more consistently"]',
   '[7.9,8.1,8.2,8.3,8.4,8.5,8.6,8.4]', 12, 9, 4, 0, 89.0, 82.0, 22.0),

  ('Karim Wael',       8.0, 7.8, 38, 76, 'Defense',  'Balanced', 'stable',    'In Form',         1.8,
   '["7 clean sheets and 38 saves this season","Commanding presence in the box","Top 3 goalkeeper in the league","Distribution improving — 78% accuracy"]',
   '[7.5,7.6,7.8,7.7,8.0,7.9,8.1,8.0]', 12, 0, 0, 0, 76.0, 79.0, 15.0),

  ('Ziad Hamdy',       7.6, 7.4, 55, 82, 'Defense',  'Balanced', 'stable',    'Stable',          0.5,
   '["Aerially dominant — wins 74% of headers","Strong in last-ditch tackles","Positional awareness improving","Needs to improve distribution under pressure"]',
   '[7.2,7.3,7.4,7.4,7.5,7.6,7.7,7.6]', 12, 0, 1, 48, 82.0, 77.0, 30.0),

  ('Tariq Ziad',       7.0, 6.9, 62, 78, 'Balanced', 'Defense',  'declining', 'Needs Improvement',-1.2,
   '["High pressing work rate","Loses possession in dangerous areas","Needs to improve decision-making","Stamina management required"]',
   '[7.2,7.1,7.0,6.9,7.0,6.8,7.1,7.0]', 12, 1, 2, 62, 78.0, 68.0, 42.0),

  ('Omar Fathy',       7.2, 7.1, 48, 85, 'Defense',  'Attack',   'stable',    'Stable',          1.0,
   '["Overlapping runs create width","Consistent defensive positioning","Assists improving — 3 this season","Needs to improve crossing accuracy"]',
   '[6.9,7.0,7.1,7.1,7.2,7.3,7.2,7.2]', 12, 0, 3, 38, 85.0, 73.0, 20.0),

  -- Falcons United
  ('Adel Ragab',       8.1, 7.9, 58, 84, 'Attack',   'Balanced', 'improving', 'In Form',         4.2,
   '["Powerful aerial presence — 68% header wins","Excellent hold-up play","Finishing accuracy improving","Pressing triggers need better timing"]',
   '[7.5,7.7,7.8,7.9,8.0,8.1,8.2,8.1]', 12, 9, 2, 20, 84.0, 80.0, 35.0),

  ('Youssef Ahmed',    7.5, 7.3, 50, 80, 'Balanced', 'Attack',   'stable',    'Stable',          1.5,
   '["Box-to-box engine with good stamina","Through ball accuracy 71%","Interceptions increasing","Should shoot more from edge of area"]',
   '[7.1,7.2,7.3,7.3,7.4,7.5,7.5,7.5]', 12, 2, 4, 72, 80.0, 74.0, 25.0),

  ('Nasser Ibrahim',   7.8, 7.6, 42, 75, 'Defense',  'Balanced', 'stable',    'In Form',         2.1,
   '["Dominant in aerial duels","Progressive carries initiate attacks","Commanding presence reduces opponent shots","Leadership drives defensive concentration"]',
   '[7.3,7.5,7.6,7.5,7.7,7.8,7.9,7.8]', 12, 1, 0, 90, 75.0, 78.0, 18.0),

  ('Sherif Gamal',     6.9, 6.8, 65, 77, 'Defense',  'Attack',   'stable',    'Stable',          0.2,
   '["Solid positional defending","Overlapping runs create space","Needs to improve crossing","Fatigue management needed"]',
   '[6.7,6.8,6.9,6.8,6.9,7.0,6.9,6.9]', 12, 0, 2, 32, 77.0, 66.0, 38.0),

  ('Mahmoud Saif',     7.4, 7.2, 35, 70, 'Defense',  'Balanced', 'stable',    'Stable',          0.8,
   '["Reliable shot stopper","Command of penalty area","Distribution needs improvement","Good communication with backline"]',
   '[7.0,7.1,7.2,7.2,7.3,7.4,7.4,7.4]', 12, 0, 0, 0, 70.0, 72.0, 12.0),

  -- Lions City
  ('Tamer Said',       7.9, 7.7, 60, 82, 'Attack',   'Balanced', 'improving', 'In Form',         3.8,
   '["Physical targetman with strong hold-up","Championship best headers per game","Link-up play creating half-chances","Stamina management needed in 70th+ min"]',
   '[7.3,7.5,7.6,7.7,7.7,7.8,7.9,7.9]', 12, 7, 1, 18, 82.0, 78.0, 42.0),

  ('Amr Khaled',       7.3, 7.1, 55, 80, 'Attack',   'Balanced', 'improving', 'Stable',          2.5,
   '["Creative number 10 with good vision","High dribble attempts per 90","Assists improving — 5 this season","Should improve defensive press intensity"]',
   '[6.9,7.0,7.1,7.2,7.2,7.3,7.4,7.3]', 12, 3, 5, 30, 80.0, 76.0, 28.0),

  ('Walid Nour',       7.0, 6.9, 45, 72, 'Defense',  'Balanced', 'stable',    'Stable',          0.5,
   '["Experienced center-back","Solid positioning","Reduced aerial ability with age","Must communicate better with young backline"]',
   '[6.7,6.8,6.9,6.9,7.0,7.0,7.1,7.0]', 12, 0, 0, 75, 72.0, 68.0, 22.0),

  -- Sharks FC
  ('Bassem Nabil',     7.7, 7.5, 50, 86, 'Attack',   'Balanced', 'improving', 'In Form',         3.5,
   '["Pacey winger with strong dribbling","Crossing accuracy improved to 36%","Defensive tracking improving","Needs to be more decisive in final third"]',
   '[7.2,7.3,7.4,7.5,7.6,7.7,7.8,7.7]', 12, 5, 3, 28, 86.0, 79.0, 24.0),

  ('Ibrahim Sameh',    7.2, 7.0, 48, 74, 'Defense',  'Balanced', 'stable',    'Stable',          0.8,
   '["Solid center-back with good positioning","Strong in 1v1 defending","Needs to improve with the ball","Aerial duels solid — 72% win rate"]',
   '[6.8,6.9,7.0,7.0,7.1,7.2,7.2,7.2]', 12, 1, 0, 68, 74.0, 71.0, 20.0),

  -- Eagles Club
  ('Saad Magdy',       7.1, 6.9, 62, 78, 'Attack',   'Balanced', 'stable',    'Stable',          1.2,
   '["Dangerous on the counter-attack","Physical presence upfront","Needs more link-up play","Should press higher to create turnovers"]',
   '[6.7,6.8,6.9,6.9,7.0,7.1,7.1,7.1]', 12, 5, 1, 14, 78.0, 72.0, 35.0),

  ('Fady Emam',        6.8, 6.6, 58, 76, 'Balanced', 'Defense',  'stable',    'Stable',          0.4,
   '["Energetic midfielder who covers ground","Passing accuracy needs improvement","Interception rate growing","Needs to add goals to his game"]',
   '[6.5,6.6,6.7,6.6,6.7,6.8,6.8,6.8]', 12, 1, 4, 55, 76.0, 66.0, 28.0),

  -- Panthers
  ('George Maher',     7.0, 6.8, 55, 82, 'Attack',   'Balanced', 'improving', 'Stable',          2.8,
   '["Pace and directness cause problems","Young talent with high ceiling","Decision-making needs polish","Needs to track back more consistently"]',
   '[6.5,6.6,6.8,6.8,6.9,7.0,7.1,7.0]', 12, 4, 2, 20, 82.0, 70.0, 30.0),

  ('Andrew Nabil',     6.5, 6.3, 40, 68, 'Defense',  'Balanced', 'stable',    'Stable',          0.6,
   '["Improving shot-stopper for a young keeper","Needs to command his area more","Distribution below average","Good reflexes but positional issues"]',
   '[6.2,6.3,6.3,6.4,6.4,6.5,6.5,6.5]', 12, 0, 0, 0, 68.0, 62.0, 18.0)

) as v(name, cr, ar, fatigue, activity, primary_c, secondary_c, trend, status, imp_rate,
       insights, ratings_history, matches, goals, assists, tackles,
       work_rate, tactical_impact, injury_risk)
  on p.full_name = v.name
on conflict (player_id) do update set
  current_rating       = excluded.current_rating,
  average_rating       = excluded.average_rating,
  fatigue              = excluded.fatigue,
  activity_level       = excluded.activity_level,
  primary_contribution = excluded.primary_contribution,
  secondary_contribution = excluded.secondary_contribution,
  trend                = excluded.trend,
  status               = excluded.status,
  improvement_rate     = excluded.improvement_rate,
  insights             = excluded.insights,
  ratings_history      = excluded.ratings_history,
  total_matches        = excluded.total_matches,
  total_goals          = excluded.total_goals,
  total_assists        = excluded.total_assists,
  total_tackles        = excluded.total_tackles,
  work_rate            = excluded.work_rate,
  tactical_impact      = excluded.tactical_impact,
  injury_risk          = excluded.injury_risk,
  updated_at           = now();

-- ============================================================
-- 2) player_risk_analysis — one snapshot per player
-- ============================================================

insert into public.player_risk_analysis (
  player_id, fatigue_risk, injury_risk, consistency_risk, tactical_risk,
  workload_score, risk_level, next_match_risk_factor, days_until_full_recovery,
  recommendations, analyzed_at
)
select
  p.id,
  v.fatigue_risk, v.injury_risk, v.consistency_risk, v.tactical_risk,
  v.workload_score, v.risk_level,
  v.next_risk, v.recovery_days,
  v.recommendations::jsonb,
  now()
from public.players p
join (values
  -- GoalSight FC
  ('Hassan Ali',    44.0, 18.0, 15.0, 12.0, 82.0, 'low',    0.18, 1,
   '["Maintain current workload — performance indicators healthy","Monitor sprint recovery between matches","Optional rest in low-priority cup fixture"]'),
  ('Mostafa Samir', 52.0, 28.0, 20.0, 16.0, 86.0, 'medium', 0.28, 2,
   '["Moderate fatigue building — manage sprint workload","Consider 75-minute cap in next fixture","Recovery protocol recommended post-match"]'),
  ('Karim Wael',    38.0, 15.0, 10.0,  8.0, 76.0, 'low',    0.12, 0,
   '["Optimal condition — clear to play full 90","Maintain hydration protocol","No rotation needed this week"]'),
  ('Ziad Hamdy',    55.0, 32.0, 22.0, 18.0, 88.0, 'medium', 0.32, 2,
   '["Monitor aerial duel load — approaching threshold","Consider mid-week rest","Full recovery expected within 48 hours"]'),
  ('Tariq Ziad',    62.0, 44.0, 28.0, 20.0, 92.0, 'high',   0.55, 4,
   '["Rotation recommended — fatigue index elevated","Reduce high-intensity training load for 48 hours","Medical staff review before next selection"]'),
  ('Omar Fathy',    48.0, 22.0, 18.0, 14.0, 82.0, 'low',    0.22, 1,
   '["Acceptable load — standard management applies","Mild fatigue building but manageable","Full availability confirmed"]'),

  -- Falcons United
  ('Adel Ragab',    58.0, 38.0, 25.0, 18.0, 88.0, 'medium', 0.42, 3,
   '["Accumulating fatigue — manage aerial duel workload","Limit training intensity mid-week","Should be available for selection with managed load"]'),
  ('Youssef Ahmed', 50.0, 25.0, 18.0, 14.0, 82.0, 'low',    0.25, 1,
   '["Acceptable risk level — standard selection applies","Mild fatigue — reduce intensity mid-week","Full recovery expected before next fixture"]'),
  ('Nasser Ibrahim',42.0, 18.0, 12.0,  9.0, 76.0, 'low',    0.14, 0,
   '["Full availability confirmed — no concerns","Aerial workload at safe threshold","Continue standard recovery protocol"]'),
  ('Sherif Gamal',  65.0, 40.0, 28.0, 20.0, 91.0, 'high',   0.52, 4,
   '["Rest urgently recommended — overload index elevated","Substitute early in next match","Physio assessment recommended"]'),
  ('Mahmoud Saif',  35.0, 15.0,  8.0,  6.0, 72.0, 'low',    0.10, 0,
   '["Peak condition — optimal output expected","Maintain current training load","No physical concerns identified"]'),

  -- Lions City
  ('Tamer Said',    60.0, 45.0, 28.0, 20.0, 92.0, 'high',   0.58, 4,
   '["Rest recommended — overload 92%","Substitute by 65th minute in next match","Physio assessment of muscle loading required"]'),
  ('Amr Khaled',    55.0, 30.0, 20.0, 15.0, 84.0, 'medium', 0.30, 2,
   '["Moderate risk — manage sprint distances","Avoid back-to-back full appearances","Ice therapy post-match recommended"]'),
  ('Walid Nour',    45.0, 22.0, 15.0, 12.0, 78.0, 'low',    0.20, 1,
   '["Acceptable load — continue standard management","Monitor aerial duel count","Full availability for next fixture"]'),

  -- Sharks FC
  ('Bassem Nabil',  50.0, 26.0, 18.0, 14.0, 82.0, 'medium', 0.26, 2,
   '["Moderate fatigue detected — manage sprint count","Consider 75-minute cap","Recovery protocol recommended"]'),
  ('Ibrahim Sameh', 48.0, 20.0, 15.0, 12.0, 80.0, 'low',    0.20, 1,
   '["Normal load — standard management","Full availability confirmed","Continue current training program"]'),

  -- Eagles Club
  ('Saad Magdy',    62.0, 38.0, 26.0, 18.0, 90.0, 'high',   0.48, 3,
   '["Rotation advisable — fatigue building","Limit sprint training for 48 hours","Full availability with managed load"]'),
  ('Fady Emam',     58.0, 30.0, 22.0, 16.0, 86.0, 'medium', 0.35, 2,
   '["Moderate fatigue — standard management","Avoid overload in training","Full availability confirmed for next fixture"]'),

  -- Panthers
  ('George Maher',  55.0, 32.0, 20.0, 15.0, 84.0, 'medium', 0.32, 2,
   '["Sprint capacity slightly reduced","Avoid intense sprint drills for 48 hours","Full fitness expected within 2 days"]'),
  ('Andrew Nabil',  40.0, 18.0, 12.0,  8.0, 76.0, 'low',    0.15, 0,
   '["Optimal condition — clear to play","Continue standard recovery protocol","No concerns identified"]')

) as v(name, fatigue_risk, injury_risk, consistency_risk, tactical_risk,
       workload_score, risk_level, next_risk, recovery_days, recommendations)
  on p.full_name = v.name;
