-- ============================================================
-- Goal Sight MVP - Player Policy Alignment
-- File: 010_player_policy_alignment.sql
-- Description:
-- Updates player stats policy to use players.profile_id instead of
-- assuming player_id == auth.uid(). Safe to re-run.
-- ============================================================

-- Replace the old player stats policy

drop policy if exists "Player read own stats" on public.player_match_stats;

-- Player can only read stats for the linked player record
create policy "Player read own stats"
on public.player_match_stats
for select
to authenticated
using (
  public.has_role('player')
  and exists (
    select 1
    from public.players p
    where p.id = player_match_stats.player_id
      and p.profile_id = auth.uid()
  )
);
