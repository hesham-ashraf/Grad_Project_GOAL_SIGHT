-- ============================================================
-- Goal Sight — Admin club also appears in fan clubs + standings
-- File: 046_admin_club_seeds_standings.sql
-- Description:
--   Fans see "public clubs/standings only". The fan club repository hides any
--   team that has no team_season_stats row, so a club created by an admin via
--   create_admin_club() would never show up for fans. This migration rewrites
--   create_admin_club() so that, when it creates a new club, it also seeds a
--   zeroed team_season_stats row (ranked at the end of the table). Renames are
--   left untouched. Safe to re-run.
-- ============================================================

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
  v_rank     int;
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

    -- Seed a zeroed standings row so the club is visible to fans
    -- (clubs/standings). Ranked at the bottom of the current table.
    select coalesce(max(ranking), 0) + 1 into v_rank from team_season_stats;
    insert into team_season_stats (team_id, ranking)
    values (v_club_id, v_rank)
    on conflict do nothing;
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
