-- ============================================================
-- Goal Sight — Player/Profile Link Backfill
-- File: 033_player_profile_link_backfill.sql
-- Description:
--   Links the Ahmed Striker player row to the live player test account so
--   player-scoped runtime checks can resolve players.profile_id non-recursively.
--   Safe to re-run.
-- ============================================================

do $$
declare
  target_profile_id uuid;
begin
  select u.id
    into target_profile_id
  from auth.users u
  where u.email = 'player-test@goalsight.com'
     or lower(coalesce(u.raw_user_meta_data->>'role', '')) = 'player'
  order by case when u.email = 'player-test@goalsight.com' then 0 else 1 end
  limit 1;

  if target_profile_id is not null then
    update public.players
    set profile_id = target_profile_id
    where full_name = 'Ahmed Striker'
      and (profile_id is distinct from target_profile_id);
  end if;
end $$;