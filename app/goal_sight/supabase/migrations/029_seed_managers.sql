-- ============================================================
-- Goal Sight — Seed admin manager directory (DEV SEED)
-- File: 029_seed_managers.sql
-- Description:
--   Mirrors AdminMockData.managers into the managers table. last_active is
--   stored relative to seed time.
-- DEV ONLY. Idempotent (skips if any manager exists).
-- ============================================================

insert into public.managers
  (name, email, image_url, upload_count, matches_analyzed, tactical_rating, last_active, is_active)
select * from (values
  ('Jurgen Klopp','jurgen@liverpool.com','https://i.pravatar.cc/150?u=jurgen',142,89,9.2, now() - interval '2 hours', true),
  ('Pep Guardiola','pep@mancity.com','https://i.pravatar.cc/150?u=pep',210,156,9.5, now() - interval '15 minutes', true),
  ('Mikel Arteta','mikel@arsenal.com','https://i.pravatar.cc/150?u=mikel',87,45,8.7, now() - interval '1 day', false),
  ('Carlo Ancelotti','carlo@realmadrid.com','https://i.pravatar.cc/150?u=carlo',98,62,8.9, now() - interval '6 hours', true),
  ('Thomas Tuchel','thomas@england.com','https://i.pravatar.cc/150?u=thomas',54,38,8.4, now() - interval '20 hours', true),
  ('Xabi Alonso','xabi@bayer.com','https://i.pravatar.cc/150?u=xabi',31,22,8.1, now() - interval '3 days', false)
) as m(name,email,image_url,upload_count,matches_analyzed,tactical_rating,last_active,is_active)
where not exists (select 1 from public.managers);
