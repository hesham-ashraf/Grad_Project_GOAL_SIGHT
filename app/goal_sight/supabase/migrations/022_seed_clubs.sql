-- ============================================================
-- Goal Sight — Seed clubs, season stats & squads (DEV SEED)
-- File: 022_seed_clubs.sql
-- Description:
--   Mirrors the Flutter mock `clubs_provider.dart` data into Supabase so the
--   SupabaseClubRepository returns the same 6 clubs + squads the app shipped
--   with. Idempotent: upserts teams/stats by key, inserts players if absent.
-- DEV ONLY.
-- ============================================================

do $$
declare tid uuid; r record;
begin
  insert into public.teams (name, stadium, league, country, founded_year, coach, playing_style, primary_color, description)
  values
    ('GoalSight FC','GoalSight Arena','GoalSight Premier League','Egypt',1998,'Ahmed Nour','High Press · 4-3-3','#2DE2E6','The most dominant club in the league, known for aggressive pressing and rapid transitions.'),
    ('Falcons United','Sky Stadium','GoalSight Premier League','Egypt',2003,'Samy Hassan','Balanced · 4-2-3-1','#705AF5','Consistent contenders built on solid defence and set-piece mastery.'),
    ('Lions City','The Den','GoalSight Premier League','Egypt',1995,'Khalid Mostafa','Direct Play · 4-4-2','#FFC857','Hard-working and physical — known for resilience and dangerous set pieces.'),
    ('Sharks FC','Oceanic Park','GoalSight Premier League','Egypt',2008,'Hany Zakaria','Mid Block · 4-1-4-1','#356BFF','Compact and organised — tough to beat at home, danger on the counter-attack.'),
    ('Eagles Club','High Peak Arena','GoalSight Premier League','Egypt',2001,'Ramy Fares','Low Block · 5-4-1','#FF6B8A','Defensively organised with pacey attackers on the break — hard to dominate.'),
    ('Panthers','Jungle Stadium','GoalSight Premier League','Egypt',2010,'Nader Ali','Counter-attack · 4-5-1','#70F59A','Young squad with high potential. Inconsistent but capable of beating anyone on their day.')
  on conflict (name) do update set
    stadium=excluded.stadium, league=excluded.league, country=excluded.country,
    founded_year=excluded.founded_year, coach=excluded.coach, playing_style=excluded.playing_style,
    primary_color=excluded.primary_color, description=excluded.description;

  for r in select * from (values
    ('GoalSight FC',12,10,1,1,30,8,1,31,7,64,198,12,0),
    ('Falcons United',12,7,4,1,21,11,2,25,5,52,156,18,1),
    ('Lions City',12,6,4,2,19,14,3,22,4,44,141,24,2),
    ('Sharks FC',12,5,4,3,15,14,4,19,4,48,128,20,1),
    ('Eagles Club',12,4,5,3,13,16,5,17,3,39,114,28,3),
    ('Panthers',12,3,3,6,12,18,6,12,2,42,109,22,1)
  ) as s(club,mp,w,d,l,gs,gc,rnk,pts,cs,poss,shots,yc,rc)
  loop
    select id into tid from public.teams where name=r.club;
    insert into public.team_season_stats (team_id, season, matches_played, wins, draws, losses,
      goals_scored, goals_conceded, ranking, points, clean_sheets, avg_possession, total_shots, yellow_cards, red_cards)
    values (tid,'current',r.mp,r.w,r.d,r.l,r.gs,r.gc,r.rnk,r.pts,r.cs,r.poss,r.shots,r.yc,r.rc)
    on conflict (team_id, season) do update set
      matches_played=excluded.matches_played, wins=excluded.wins, draws=excluded.draws, losses=excluded.losses,
      goals_scored=excluded.goals_scored, goals_conceded=excluded.goals_conceded, ranking=excluded.ranking,
      points=excluded.points, clean_sheets=excluded.clean_sheets, avg_possession=excluded.avg_possession,
      total_shots=excluded.total_shots, yellow_cards=excluded.yellow_cards, red_cards=excluded.red_cards;
  end loop;

  for r in select * from (values
    ('GoalSight FC','Hassan Ali','CAM','🇪🇬',27,12,8,10,0,0,9.1,'elite','€9.5M',true,'Season-defining performances. Controls tempo, creates relentlessly — the league''s best playmaker.'),
    ('GoalSight FC','Mostafa Samir','LW','🇪🇬',24,12,9,4,0,0,8.4,'elite','€6.2M',false,'Electrifying on the left flank. Won 78% of dribble attempts. Scored in 6 consecutive matches.'),
    ('GoalSight FC','Karim Wael','GK','🇪🇬',31,12,0,0,0,7,8.0,'elite','€3.8M',false,'7 clean sheets and 38 saves. Commanding presence in the box — top 3 GK in the league.'),
    ('GoalSight FC','Ziad Hamdy','CB','🇪🇬',29,12,1,2,54,0,7.8,'good','€4.1M',false,'Rock-solid centre-back. Wins 81% of aerial duels. Excellent in initiating build-up from deep.'),
    ('GoalSight FC','Omar Fathy','RB','🇪🇬',23,11,0,4,38,0,7.4,'good','€3.2M',false,'Energetic right-back who contributes heavily in attack. Provided 4 assists via overlapping runs.'),
    ('GoalSight FC','Tariq Ziad','DM','🇪🇬',26,10,1,2,47,0,6.9,'average','€2.5M',false,'Disciplined in the defensive phase but loses possession too often under pressure. Improving.'),
    ('Falcons United','Adel Ragab','ST','🇪🇬',25,12,11,3,0,0,8.3,'elite','€7.0M',true,'Top scorer in the league. Lethal in the box — 11 goals from just 38 shots. Clinical finisher.'),
    ('Falcons United','Youssef Ahmed','CM','🇪🇬',28,12,2,6,42,0,7.6,'good','€3.9M',false,'Engine of the midfield. High work rate, strong in the tackle, and creative in tight spaces.'),
    ('Falcons United','Nasser Ibrahim','CB','🇪🇬',30,12,2,0,61,0,7.9,'good','€4.5M',false,'Commanding CB. Dominates set pieces at both ends. Scored 2 goals from corners this season.'),
    ('Falcons United','Sherif Gamal','LB','🇪🇬',22,10,0,2,29,0,6.7,'average','€1.8M',false,'Young full-back showing potential. Defensively shaky vs pacey wingers but improving match by match.'),
    ('Falcons United','Mahmoud Saif','GK','🇪🇬',33,12,0,0,0,5,7.5,'good','€2.7M',false,'Experienced shot-stopper. Excellent distribution and sweeping ability. Keeps the defence organised.'),
    ('Lions City','Tamer Said','ST','🇪🇬',26,12,9,2,0,0,8.0,'elite','€5.5M',true,'Physical and technically gifted. Wins most aerial battles and brings teammates into play effectively.'),
    ('Lions City','Amr Khaled','AM','🇪🇬',24,11,4,6,0,0,7.4,'good','€3.6M',false,'Creative link between midfield and attack. Provides key passes in tight areas with composure.'),
    ('Lions City','Walid Nour','CB','🇪🇬',32,12,0,0,48,0,6.8,'average','€1.5M',false,'Experienced but losing a step. Strong positioning compensates for declining pace in most matches.'),
    ('Sharks FC','Omar Fathy','GK','🇪🇬',29,12,0,0,0,4,8.1,'elite','€4.8M',true,'Best goalkeeper in the league this season. 41 saves — the primary reason Sharks remain competitive.'),
    ('Sharks FC','Bassem Nabil','RW','🇪🇬',23,12,6,3,0,0,7.6,'good','€4.0M',false,'Pacey winger who thrives on the counter. 6 goals, 3 assists — a constant danger in transition.'),
    ('Sharks FC','Ibrahim Sameh','CB','🇪🇬',28,12,1,0,55,0,7.1,'good','€2.8M',false,'Consistent in the defensive block. High tackle success rate and strong aerial ability.'),
    ('Eagles Club','Saad Magdy','ST','🇪🇬',27,12,7,1,0,0,7.2,'good','€3.3M',true,'Hard-working striker who holds the ball up and brings others into play. Scores most goals from set pieces.'),
    ('Eagles Club','Fady Emam','CM','🇪🇬',25,11,1,4,33,0,6.5,'average','€1.9M',false,'Works hard to link play but struggles with final third execution. High pass completion in own half.'),
    ('Panthers','George Maher','LW','🇪🇬',22,12,5,3,0,0,7.3,'good','€2.6M',true,'The team''s brightest talent. Rapid and direct — beats defenders with ease. Needs to improve consistency.'),
    ('Panthers','Andrew Nabil','GK','🇪🇬',30,12,0,0,0,2,6.4,'poor','€1.2M',false,'Struggled with shot-stopping this season. Conceded 18 goals — positional awareness needs work.')
  ) as p(club,pname,pos,nat,p_age,apps,g,a,tk,cs,rating,tier,mv,cap,summary)
  loop
    select id into tid from public.teams where name=r.club;
    if tid is not null and not exists (select 1 from public.players where team_id=tid and full_name=r.pname) then
      insert into public.players (team_id, full_name, position, nationality, age, appearances,
        season_goals, season_assists, season_tackles, season_clean_sheets, season_rating,
        performance_tier, market_value, is_captain, performance_summary)
      values (tid, r.pname, r.pos, r.nat, r.p_age, r.apps, r.g, r.a, r.tk, r.cs, r.rating,
        r.tier, r.mv, r.cap, r.summary);
    end if;
  end loop;
end $$;
