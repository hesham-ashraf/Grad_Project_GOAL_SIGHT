-- ============================================================
-- Goal Sight — Seed fan highlights (DEV SEED)
-- File: 025_seed_highlights.sql
-- Description:
--   Mirrors the fan home highlights feed into the highlights table.
--   duration_seconds and views are stored numerically; the app formats them
--   back to "M:SS" and "1.2M views".
-- DEV ONLY. Idempotent (skips if any highlight exists).
-- ============================================================

insert into public.highlights (title, thumbnail_url, video_url, duration_seconds, league, views)
select * from (values
  ('Manchester United vs Liverpool - All Goals & Highlights','https://images.unsplash.com/photo-1579952363873-27f3bade9f55?auto=format&fit=crop&w=1100&q=80',null,323,'Premier League',1200000::bigint),
  ('Real Madrid vs Barcelona - El Clasico Extended Highlights','https://images.unsplash.com/photo-1560272564-c83b66b1ad12?auto=format&fit=crop&w=1100&q=80',null,525,'La Liga',2500000),
  ('Bayern Munich - Amazing Team Goals Compilation','https://images.unsplash.com/photo-1486286701208-1d58e9338013?auto=format&fit=crop&w=1100&q=80',null,372,'Bundesliga',892000),
  ('PSG vs Marseille - Best Moments','https://images.unsplash.com/photo-1459865264687-595d652de67e?auto=format&fit=crop&w=1100&q=80',null,298,'Ligue 1',654000)
) as h(title,thumbnail_url,video_url,duration_seconds,league,views)
where not exists (select 1 from public.highlights);
