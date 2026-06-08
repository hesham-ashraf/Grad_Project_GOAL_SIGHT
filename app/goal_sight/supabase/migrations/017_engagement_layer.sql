-- ============================================================
-- Goal Sight — Engagement Layer
-- File: 017_engagement_layer.sql
-- Description:
--   notifications, notification_preferences, activity_logs,
--   user_favorite_teams, user_favorite_players, saved_matches, highlights.
-- Safe to re-run.
-- ============================================================

create table if not exists public.notifications (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references public.profiles(id) on delete cascade,
  type                text not null default 'info'
                        check (type in ('info','system','upload_complete','analysis_ready',
                                        'tactical_warning','alert','subscription')),
  title               text not null,
  body                text,
  related_entity_type text,
  related_entity_id   uuid,
  data                jsonb not null default '{}'::jsonb,
  is_read             boolean not null default false,
  read_at             timestamptz,
  created_at          timestamptz not null default now()
);
create index if not exists idx_notifications_user   on public.notifications(user_id);
create index if not exists idx_notifications_unread on public.notifications(user_id, is_read);

create table if not exists public.notification_preferences (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null unique references public.profiles(id) on delete cascade,
  upload_updates        boolean not null default true,
  analysis_ready        boolean not null default true,
  tactical_alerts       boolean not null default true,
  system_announcements  boolean not null default true,
  push_enabled          boolean not null default true,
  email_enabled         boolean not null default false,
  updated_at            timestamptz not null default now(),
  created_at            timestamptz not null default now()
);
drop trigger if exists trg_notification_prefs_updated_at on public.notification_preferences;
create trigger trg_notification_prefs_updated_at before update on public.notification_preferences
  for each row execute function public.set_updated_at();

-- Audit trail (ActivityModel) for admin dashboards
create table if not exists public.activity_logs (
  id           uuid primary key default gen_random_uuid(),
  actor_id     uuid references public.profiles(id) on delete set null,
  actor_role   text,
  action       text not null,
  description  text,
  entity_type  text,
  entity_id    uuid,
  metadata     jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now()
);
create index if not exists idx_activity_logs_actor   on public.activity_logs(actor_id);
create index if not exists idx_activity_logs_created on public.activity_logs(created_at desc);
create index if not exists idx_activity_logs_action  on public.activity_logs(action);

-- Fan engagement
create table if not exists public.user_favorite_teams (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  team_id    uuid not null references public.teams(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, team_id)
);
create index if not exists idx_fav_teams_user on public.user_favorite_teams(user_id);
create index if not exists idx_fav_teams_team on public.user_favorite_teams(team_id);

create table if not exists public.user_favorite_players (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  player_id  uuid not null references public.players(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, player_id)
);
create index if not exists idx_fav_players_user   on public.user_favorite_players(user_id);
create index if not exists idx_fav_players_player on public.user_favorite_players(player_id);

create table if not exists public.saved_matches (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  match_id   uuid not null references public.matches(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, match_id)
);
create index if not exists idx_saved_matches_user  on public.saved_matches(user_id);
create index if not exists idx_saved_matches_match on public.saved_matches(match_id);

-- Fan highlights feed (FanHighlightModel)
create table if not exists public.highlights (
  id               uuid primary key default gen_random_uuid(),
  match_id         uuid references public.matches(id) on delete set null,
  title            text not null,
  thumbnail_url    text,
  video_url        text,
  duration_seconds integer,
  league           text,
  views            bigint not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index if not exists idx_highlights_match on public.highlights(match_id);
drop trigger if exists trg_highlights_updated_at on public.highlights;
create trigger trg_highlights_updated_at before update on public.highlights
  for each row execute function public.set_updated_at();

-- ---- RLS ----
alter table public.notifications            enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.activity_logs            enable row level security;
alter table public.user_favorite_teams      enable row level security;
alter table public.user_favorite_players    enable row level security;
alter table public.saved_matches            enable row level security;
alter table public.highlights               enable row level security;

-- notifications: user reads & marks-read own; admin full; creation via service role/triggers
drop policy if exists "Admin full access notifications" on public.notifications;
drop policy if exists "User read own notifications" on public.notifications;
drop policy if exists "User update own notifications" on public.notifications;
create policy "Admin full access notifications" on public.notifications
  for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy "User read own notifications" on public.notifications
  for select to authenticated using (user_id = (select auth.uid()));
create policy "User update own notifications" on public.notifications
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- notification_preferences: user fully manages own row
drop policy if exists "User manage own notification prefs" on public.notification_preferences;
drop policy if exists "Admin read notification prefs" on public.notification_preferences;
create policy "User manage own notification prefs" on public.notification_preferences
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Admin read notification prefs" on public.notification_preferences
  for select to authenticated using (public.has_role('admin'));

-- activity_logs: admin reads all; user may log + read own action
drop policy if exists "Admin read activity logs" on public.activity_logs;
drop policy if exists "User insert own activity" on public.activity_logs;
drop policy if exists "User read own activity" on public.activity_logs;
create policy "Admin read activity logs" on public.activity_logs
  for select to authenticated using (public.has_role('admin'));
create policy "User insert own activity" on public.activity_logs
  for insert to authenticated with check (actor_id = (select auth.uid()));
create policy "User read own activity" on public.activity_logs
  for select to authenticated using (actor_id = (select auth.uid()));

-- favorites & saved: user manages own
drop policy if exists "User manage own favorite teams" on public.user_favorite_teams;
drop policy if exists "User manage own favorite players" on public.user_favorite_players;
drop policy if exists "User manage own saved matches" on public.saved_matches;
create policy "User manage own favorite teams" on public.user_favorite_teams
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "User manage own favorite players" on public.user_favorite_players
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "User manage own saved matches" on public.saved_matches
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- highlights: everyone reads, admin/manager curate
drop policy if exists "Admin full access highlights" on public.highlights;
drop policy if exists "Manager full access highlights" on public.highlights;
drop policy if exists "Role read highlights" on public.highlights;
create policy "Admin full access highlights" on public.highlights
  for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy "Manager full access highlights" on public.highlights
  for all to authenticated using (public.has_role('manager')) with check (public.has_role('manager'));
create policy "Role read highlights" on public.highlights
  for select to authenticated using (
    public.has_role('admin') or public.has_role('manager') or
    public.has_role('player') or public.has_role('fan'));
