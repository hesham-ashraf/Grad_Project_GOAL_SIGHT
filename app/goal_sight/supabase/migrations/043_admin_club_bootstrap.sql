-- ============================================================
-- Goal Sight — Admin club bootstrap + hardened manager promotion
-- File: 043_admin_club_bootstrap.sql
-- Description:
--   Every admin owns exactly one club (a teams row). This migration adds:
--     * create_admin_club()  — the calling admin creates / renames their club
--                              and gets profiles.club_id set.
--     * promote_to_manager() — REWRITTEN to (a) require the caller be an admin
--                              and (b) derive the club from the admin's own
--                              profile instead of trusting a caller-supplied
--                              club_id (the old version was callable by any
--                              authenticated user against any club).
-- Safe to re-run.
-- ============================================================

-- ------------------------------------------------------------
-- create_admin_club: the signed-in admin creates or renames their club.
-- ------------------------------------------------------------
create or replace function public.create_admin_club(p_name text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid      uuid := auth.uid();
  v_role     text;
  v_club_id  uuid;
  v_name     text := nullif(trim(p_name), '');
begin
  if v_uid is null then
    raise exception 'Not authenticated.';
  end if;
  if v_name is null then
    raise exception 'Club name is required.';
  end if;

  select role, club_id into v_role, v_club_id from profiles where id = v_uid;

  if v_role is distinct from 'admin' then
    raise exception 'Only admins can create a club.';
  end if;

  if v_club_id is null then
    -- Create a new club (team) and attach it to this admin.
    insert into teams (name) values (v_name)
    returning id into v_club_id;
    update profiles set club_id = v_club_id where id = v_uid;
  else
    -- Admin already owns a club — just rename it.
    update teams set name = v_name where id = v_club_id;
  end if;

  return jsonb_build_object('id', v_club_id, 'name', v_name);
exception
  when unique_violation then
    raise exception 'A club named "%" already exists. Pick a different name.', v_name;
end;
$$;

revoke all on function public.create_admin_club(text) from public;
grant execute on function public.create_admin_club(text) to authenticated;

-- ------------------------------------------------------------
-- promote_to_manager: admin-only; club is the admin's own club.
-- Signature kept (TEXT, UUID, BOOLEAN, BOOLEAN, BOOLEAN) for client
-- compatibility, but p_club_id is ignored in favour of the admin's club.
-- ------------------------------------------------------------
create or replace function public.promote_to_manager(
  p_email            text,
  p_club_id          uuid default null,
  p_can_upload       boolean default true,
  p_can_edit_players boolean default true,
  p_can_manage_staff boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller   uuid := auth.uid();
  v_role     text;
  v_club_id  uuid;
  v_user_id  uuid;
  v_name     text;
  v_mgr_id   uuid;
begin
  -- 1. Caller must be an admin with a club.
  select role, club_id into v_role, v_club_id from profiles where id = v_caller;
  if v_role is distinct from 'admin' then
    raise exception 'Only admins can promote managers.';
  end if;
  if v_club_id is null then
    raise exception 'Create your club first, then add managers.';
  end if;

  -- 2. Find the target user by email.
  select id into v_user_id from auth.users where email = p_email limit 1;
  if v_user_id is null then
    raise exception 'No GoalSight account found for email: %', p_email;
  end if;

  -- 3. Pull their display name.
  select full_name into v_name from profiles where id = v_user_id;

  -- 4. Guard: already a manager of this club?
  if exists (select 1 from managers where email = p_email and club_id = v_club_id) then
    raise exception 'This user is already a manager of this club.';
  end if;

  -- 5. Promote into THIS admin's club.
  update profiles set role = 'manager', club_id = v_club_id where id = v_user_id;

  insert into managers (
    name, email, club_id, is_active,
    can_upload, can_edit_players, can_manage_staff,
    upload_count, matches_analyzed, tactical_rating, last_active
  )
  values (
    coalesce(v_name, p_email), p_email, v_club_id, true,
    p_can_upload, p_can_edit_players, p_can_manage_staff,
    0, 0, 0, now()
  )
  returning id into v_mgr_id;

  return jsonb_build_object('id', v_mgr_id, 'name', coalesce(v_name, p_email), 'email', p_email);
end;
$$;

revoke all on function public.promote_to_manager(text, uuid, boolean, boolean, boolean) from public;
grant execute on function public.promote_to_manager(text, uuid, boolean, boolean, boolean) to authenticated;
