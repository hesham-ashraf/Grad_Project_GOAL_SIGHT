-- ============================================================
-- Goal Sight — Seed fan highlights reel
-- File: 050_seed_highlights.sql
-- Description:
--   The fan Home highlights carousel reads public-readable `highlights`. It was
--   empty, so the section rendered blank. Seeds a few demo highlight clips
--   (public sample videos + thumbnails). Idempotent via fixed UUIDs.
-- ============================================================

insert into public.highlights (id, title, thumbnail_url, video_url, duration_seconds, league, views)
values
  ('41000001-0000-0000-0000-000000000001', 'Al Ahly 3-0 Pyramids — All Goals',     'https://picsum.photos/seed/goalsight1/640/360', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',   142, 'Egyptian Premier League', 184000),
  ('41000002-0000-0000-0000-000000000002', 'Al Ahly 2-1 Zamalek — Cairo Derby',    'https://picsum.photos/seed/goalsight2/640/360', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4', 168, 'Egyptian Premier League', 423000),
  ('41000003-0000-0000-0000-000000000003', 'Top 10 Saves — Matchweek 22',          'https://picsum.photos/seed/goalsight3/640/360', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4', 95,  'Egyptian Premier League', 76000),
  ('41000004-0000-0000-0000-000000000004', 'Future FC Stunning Counter Attack',    'https://picsum.photos/seed/goalsight4/640/360', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4', 58, 'Egyptian Premier League', 51000),
  ('41000005-0000-0000-0000-000000000005', 'Goal of the Month Contenders',         'https://picsum.photos/seed/goalsight5/640/360', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',    120, 'Egyptian Premier League', 132000),
  ('41000006-0000-0000-0000-000000000006', 'Al Masry vs Ismaily — Highlights',     'https://picsum.photos/seed/goalsight6/640/360', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4', 134, 'Egyptian Premier League', 28000)
on conflict (id) do nothing;
