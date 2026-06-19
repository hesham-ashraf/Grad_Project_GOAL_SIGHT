-- ============================================================
-- Goal Sight — Seed public demo clubs (fan-side population)
-- File: 049_seed_public_clubs.sql
-- Description:
--   Fans see clubs + standings from the public-read `teams` /
--   `team_season_stats` tables. With only AlAhly seeded, those lists were
--   nearly empty. This adds the rest of the Egyptian Premier League as PUBLIC
--   teams (no owner / no managers / no squad — players stay club-private) plus
--   a `team_season_stats` row each so they appear in the Clubs directory and
--   the league standings alongside AlAhly (which is already rank #1).
--   Idempotent: fixed UUIDs + ON CONFLICT DO NOTHING.
-- ============================================================

insert into public.teams (id, name, stadium, league, country, founded_year, coach, playing_style, primary_color, description)
values
  ('e0000001-0000-0000-0000-000000000001', 'Zamalek',            'Cairo International Stadium', 'Egyptian Premier League', 'Egypt', 1911, 'Jose Riveiro',     'Possession-based build-up',   '#D7141A', 'Cairo giants and historic rivals of Al Ahly.'),
  ('e0000002-0000-0000-0000-000000000002', 'Pyramids FC',        'Cairo International Stadium', 'Egyptian Premier League', 'Egypt', 2008, 'Krunoslav Jurcic', 'High-tempo transitions',      '#1F6F3D', 'Ambitious, well-funded modern side.'),
  ('e0000003-0000-0000-0000-000000000003', 'Future FC',          'Al Salam Stadium',           'Egyptian Premier League', 'Egypt', 2018, 'Hossam Hassan',    'Compact counter-attacking',   '#F58220', 'Fast-rising newly promoted club.'),
  ('e0000004-0000-0000-0000-000000000004', 'Al Masry',           'Port Said Stadium',          'Egyptian Premier League', 'Egypt', 1920, 'Mido',             'Direct wing play',            '#0B7A3B', 'Port Said''s passionate green army.'),
  ('e0000005-0000-0000-0000-000000000005', 'Ismaily',            'Ismailia Stadium',           'Egyptian Premier League', 'Egypt', 1924, 'Ahmed Sami',       'Technical short passing',     '#F6C700', 'The Dervishes, known for flair.'),
  ('e0000006-0000-0000-0000-000000000006', 'Ceramica Cleopatra', 'Al Salam Stadium',           'Egyptian Premier League', 'Egypt', 2007, 'Ali Maher',        'Balanced 4-2-3-1',            '#7A3FB0', 'Steady mid-table establishment side.'),
  ('e0000007-0000-0000-0000-000000000007', 'ENPPI',              'Petrosport Stadium',         'Egyptian Premier League', 'Egypt', 1980, 'Talaat Youssef',   'Defensive organisation',      '#1763A6', 'The Petroleum club, hard to break down.')
on conflict (id) do nothing;

insert into public.team_season_stats
  (team_id, season, matches_played, wins, draws, losses, goals_scored, goals_conceded, clean_sheets, points, ranking, avg_possession, total_shots, yellow_cards, red_cards)
values
  ('e0000001-0000-0000-0000-000000000001', 'current', 22, 16, 3, 3, 50, 20, 9,  51, 2, 56, 312, 41, 2),
  ('e0000002-0000-0000-0000-000000000002', 'current', 22, 15, 4, 3, 44, 18, 10, 49, 3, 58, 305, 38, 1),
  ('e0000003-0000-0000-0000-000000000003', 'current', 22, 12, 6, 4, 38, 22, 7,  42, 4, 51, 268, 45, 3),
  ('e0000004-0000-0000-0000-000000000004', 'current', 22, 11, 5, 6, 33, 25, 6,  38, 5, 49, 251, 52, 4),
  ('e0000005-0000-0000-0000-000000000005', 'current', 22,  9, 7, 6, 30, 28, 5,  34, 6, 53, 244, 47, 2),
  ('e0000006-0000-0000-0000-000000000006', 'current', 22,  8, 6, 8, 28, 30, 5,  30, 7, 48, 230, 49, 3),
  ('e0000007-0000-0000-0000-000000000007', 'current', 22,  7, 5, 10, 25, 33, 6, 26, 8, 46, 219, 55, 5)
on conflict do nothing;
