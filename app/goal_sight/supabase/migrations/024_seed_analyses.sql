-- ============================================================
-- Goal Sight — Seed AI match analyses (DEV SEED)
-- File: 024_seed_analyses.sql
-- Description:
--   Mirrors the 3 mock match analyses (match_analysis_providers.dart) into
--   match_analyses + team_match_analysis + match_player_analysis so the
--   SupabaseAnalysisRepository reconstructs the same MatchAnalysisModel list.
-- DEV ONLY. Idempotent (skips if any analysis already seeded).
-- ============================================================

do $$
declare aid uuid;
begin
  if exists (select 1 from public.match_analyses where home_team_name is not null) then
    return;
  end if;

  -- Match 1: GoalSight FC 3-1 Falcons United
  insert into public.match_analyses
    (home_team_name, away_team_name, score, date_label, result_status, intensity, highlight_text,
     dominant_team, home_avg_rating, away_avg_rating, motm_player_key, worst_player_key,
     overall_narrative, key_moments, recommendations)
  values (
    'GoalSight FC','Falcons United','3 - 1','May 2, 2026 · 20:00','FT',91,'High intensity match',
    'GoalSight FC',7.82,6.14,'p1','p6',
    $t$GoalSight FC delivered a commanding performance built on high-press intensity and rapid transitions. Their midfield trio dominated the central zones, completing 487 of 521 passes (93%). Falcons United showed brief flashes in the first half but were unable to sustain any meaningful possession sequences against GoalSight's aggressive 4-3-3 pressing block. The result was never seriously in doubt after the 67th-minute goal restored the lead.$t$,
    jsonb_build_array(
      $t$12' — Hassan Ali assist → Mostafa Samir opens scoring.$t$,
      $t$38' — Tariq Ziad loses ball, Falcons equalize from counter.$t$,
      $t$67' — Hassan Ali solo run, 2–1.$t$,
      $t$88' — Penalty won and converted, 3–1.$t$),
    jsonb_build_array(
      $t$Continue exploiting Falcons United's weak left-back who lost 1v1 duels 7 times.$t$,
      $t$Rest Hassan Ali for at least 20 minutes in the next fixture — fatigue index critical at 87.$t$,
      $t$Set-piece preparation: Falcons conceded 3 of their last 5 goals from corners.$t$,
      $t$Introduce Tariq Ziad as a late substitute only — his positional discipline breaks down under fatigue.$t$)
  ) returning id into aid;
  insert into public.team_match_analysis
    (match_analysis_id, side, team_name, possession, style, pressure_style, compactness, attacking_zones, avg_rating, top_players, worst_players)
  values
    (aid,'home','GoalSight FC',64,'Possession-based','High Press','Compact', jsonb_build_array('Left Wing','Central Channel'),7.82, jsonb_build_array('p1','p2'), jsonb_build_array('p4')),
    (aid,'away','Falcons United',36,'Counter-attack','Low Block','Deep', jsonb_build_array('Right Wing'),6.14, jsonb_build_array('p5'), jsonb_build_array('p6'));
  insert into public.match_player_analysis
    (match_analysis_id, player_key, player_name, player_position, rating, fatigue, performance_status, contribution, impact, insight, goals, assists, tackles, key_passes, is_motm, is_worst)
  values
    (aid,'p1','Hassan Ali','CAM',9.1,87,'excellent','attack','Game Changer',$t$Controlled tempo with 11 key touches in the final third. 2 assists, 1 goal, 94% pass accuracy.$t$,1,2,0,7,true,false),
    (aid,'p2','Mostafa Samir','LW',8.4,72,'excellent','attack','Decisive',$t$Scored the opener, created 3 chances. Won 6 of 7 dribble attempts on the left flank.$t$,1,1,0,3,false,false),
    (aid,'p3','Ziad Hamdy','CB',7.8,55,'good','defense','Reliable',$t$Commanding in the air — 8 duels won. Initiated 4 build-up sequences from deep.$t$,0,0,5,2,false,false),
    (aid,'p4','Tariq Ziad','DM',5.8,91,'poor','balanced','Liability',$t$Lost possession 8 times in dangerous central areas. Poor positioning led to the equaliser.$t$,0,0,0,0,false,true),
    (aid,'p5','Adel Mansour','CM',7.2,60,'good','defense','Steady',$t$Falcons United's most disciplined midfielder — 78% pass completion, 4 interceptions.$t$,0,0,4,2,false,false),
    (aid,'p6','Karim Essam','LB',4.9,83,'terrible','defense','Liability',$t$Lost 7 of 9 defensive duels on the flank. Directly responsible for 2 GoalSight goals.$t$,0,0,0,0,false,true);

  -- Match 2: Sharks FC 0-0 Eagles Club
  insert into public.match_analyses
    (home_team_name, away_team_name, score, date_label, result_status, intensity, highlight_text,
     dominant_team, home_avg_rating, away_avg_rating, motm_player_key, worst_player_key,
     overall_narrative, key_moments, recommendations)
  values (
    'Sharks FC','Eagles Club','0 - 0','May 1, 2026','FT',62,null,
    'None',6.48,6.61,'p7','p10',
    $t$A deeply tactical and frustrating contest. Both teams prioritised defensive solidity over creativity, resulting in a match of rare genuine chances. Omar Fathy's composed goalkeeping was the highlight in an otherwise forgettable encounter. Mid-block versus mid-block produced a gridlock that neither manager could solve from the bench.$t$,
    jsonb_build_array(
      $t$23' — Sharks penalty appeal waved away.$t$,
      $t$55' — Eagles hit the crossbar from long range.$t$,
      $t$78' — Sharks goalkeeper world-class save to deny Eagles.$t$),
    jsonb_build_array(
      $t$Eagles must improve final third entry — only 6 shots in 90 minutes is insufficient.$t$,
      $t$Sharks should recruit a creative midfielder; 43% of attacks broke down in the middle third.$t$,
      $t$Both sides can exploit set pieces more effectively — zero goals from 18 combined corners.$t$)
  ) returning id into aid;
  insert into public.team_match_analysis
    (match_analysis_id, side, team_name, possession, style, pressure_style, compactness, attacking_zones, avg_rating, top_players, worst_players)
  values
    (aid,'home','Sharks FC',51,'Balanced','Mid Block','Compact', jsonb_build_array('Central Channel'),6.48, jsonb_build_array('p7'), jsonb_build_array('p8')),
    (aid,'away','Eagles Club',49,'Balanced','Mid Block','Deep', jsonb_build_array('Right Wing'),6.61, jsonb_build_array('p9'), jsonb_build_array('p10'));
  insert into public.match_player_analysis
    (match_analysis_id, player_key, player_name, player_position, rating, fatigue, performance_status, contribution, impact, insight, goals, assists, tackles, key_passes, is_motm, is_worst)
  values
    (aid,'p7','Omar Fathy','GK',8.0,40,'excellent','defense','Wall',$t$4 saves, including one world-class stop from point blank. Commanded his box with authority.$t$,0,0,0,0,true,false),
    (aid,'p8','Bassem Nabil','RW',5.6,74,'poor','attack','Ineffective',$t$Completely isolated on the right wing. 0 successful dribbles, lost possession 9 times.$t$,0,0,0,0,false,true),
    (aid,'p9','Saad Magdy','ST',7.1,68,'good','attack','Threat',$t$3 shots on target, physically dominant in aerial duels. Unlucky not to score.$t$,0,0,0,2,false,false),
    (aid,'p10','Fady Emam','AM',5.4,79,'poor','attack','Negative',$t$Failed to link midfield and attack. 41% pass accuracy in the final third — costly.$t$,0,0,0,0,false,true);

  -- Match 3: Lions City 1-2 GoalSight FC
  insert into public.match_analyses
    (home_team_name, away_team_name, score, date_label, result_status, intensity, highlight_text,
     dominant_team, home_avg_rating, away_avg_rating, motm_player_key, worst_player_key,
     overall_narrative, key_moments, recommendations)
  values (
    'Lions City','GoalSight FC','1 - 2','Apr 28, 2026','FT',88,'Last-minute winner',
    'GoalSight FC',6.71,7.44,'p1','p11',
    $t$GoalSight FC showed remarkable resilience to come from behind in an away fixture of genuine quality. Lions City were disciplined for 70 minutes but conceded two late goals as GoalSight shifted to a more direct approach after the 65th minute. Hassan Ali's 92nd-minute finish combined technical brilliance with physical endurance — an extraordinary individual display.$t$,
    jsonb_build_array(
      $t$34' — Lions City open scoring from a direct free kick.$t$,
      $t$71' — GoalSight equalise from a corner routine.$t$,
      $t$90+2' — Hassan Ali solo effort wins the match.$t$),
    jsonb_build_array(
      $t$GoalSight's late-game pressure format (4-2-4 shape) should be used from the 75' mark consistently.$t$,
      $t$Lions City must address their 82nd-minute concentration failures — this is the 3rd match conceding late.$t$,
      $t$Hassan Ali's injury risk is elevated — fatigue at 91 after two consecutive high-intensity matches.$t$)
  ) returning id into aid;
  insert into public.team_match_analysis
    (match_analysis_id, side, team_name, possession, style, pressure_style, compactness, attacking_zones, avg_rating, top_players, worst_players)
  values
    (aid,'home','Lions City',44,'Direct','Low Block','Deep', jsonb_build_array('Right Wing','Set Pieces'),6.71, jsonb_build_array('p12'), jsonb_build_array('p11')),
    (aid,'away','GoalSight FC',56,'Possession-based','High Press','Compact', jsonb_build_array('Central Channel','Left Wing'),7.44, jsonb_build_array('p1','p13'), jsonb_build_array('p14'));
  insert into public.match_player_analysis
    (match_analysis_id, player_key, player_name, player_position, rating, fatigue, performance_status, contribution, impact, insight, goals, assists, tackles, key_passes, is_motm, is_worst)
  values
    (aid,'p1','Hassan Ali','CAM',8.8,91,'excellent','attack','Legendary',$t$Brilliant late-game performance. Scored the 90+2' winner after a 60-metre run — fatigue index critical.$t$,1,1,0,5,true,false),
    (aid,'p11','Walid Nour','CB',5.3,85,'poor','defense','Weak Link',$t$Beaten for pace on 4 occasions, directly responsible for the corner routine goal conceded.$t$,0,0,0,0,false,true),
    (aid,'p12','Tamer Said','ST',7.6,70,'good','attack','Consistent',$t$Lions City's best player. Won the free kick that led to the opening goal. Linked play well.$t$,1,0,0,3,false,false),
    (aid,'p13','Mostafa Samir','LW',7.9,65,'good','attack','Disruptive',$t$Constant menace on the left flank. Won the corner that led to the equaliser.$t$,0,1,0,4,false,false),
    (aid,'p14','Tariq Ziad','DM',6.1,77,'average','balanced','Below Par',$t$Improved from last match but still gave the ball away 5 times in midfield.$t$,0,0,3,0,false,false);
end $$;
