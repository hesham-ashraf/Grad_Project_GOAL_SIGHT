-- ============================================================
-- Goal Sight - Production RLS Policy Validation Queries
-- File: 032_policy_validation_queries.sql
-- Phase: 15 Production Sign-off Validation
-- Description:
--   Deterministic Supabase SQL Editor checks for RLS, policy coverage,
--   storage policy presence, and realtime publication coverage.
--
-- Important:
--   This file intentionally does not impersonate users.
--   It does not change request claims, switch local roles, or spoof auth.uid().
--
-- Result model:
--   PASS means the database catalog contains the expected RLS/policy shape.
--   FAIL means a required table, policy, predicate, or publication entry is
--   missing or does not match the production gate expectation.
--   AUTH_CLIENT_REQUIRED means the SQL Editor cannot prove runtime behavior;
--   validate with real signed-in admin, manager, player, and fan sessions.
-- ============================================================

-- ============================================================
-- 1) Full policy inventory currently present
-- ============================================================

select
  schemaname,
  tablename,
  policyname,
  cmd,
  roles,
  qual,
  with_check
from pg_policies
where schemaname in ('public', 'storage')
order by schemaname, tablename, policyname;

-- ============================================================
-- 2) RLS enabled status for all public application tables
-- ============================================================

select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced,
  case
    when c.relrowsecurity then 'PASS'
    else 'FAIL'
  end as validation_status
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
order by c.relname;

-- ============================================================
-- 3) Required Phase 15 table existence and RLS gate
-- ============================================================

with expected_tables(table_name) as (
  values
    ('profiles'),
    ('teams'),
    ('players'),
    ('matches'),
    ('match_events'),
    ('player_match_stats'),
    ('videos'),
    ('upload_jobs'),
    ('notifications'),
    ('activity_logs')
),
actual_tables as (
  select c.relname as table_name, c.relrowsecurity
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relkind = 'r'
)
select
  e.table_name,
  case
    when a.table_name is null then 'FAIL'
    when a.relrowsecurity then 'PASS'
    else 'FAIL'
  end as validation_status,
  case
    when a.table_name is null then 'table is missing'
    when a.relrowsecurity then 'RLS is enabled'
    else 'RLS is disabled'
  end as finding
from expected_tables e
left join actual_tables a on a.table_name = e.table_name
order by e.table_name;

-- ============================================================
-- 4) Required policy existence coverage
-- ============================================================

with expected_policies(schemaname, tablename, policyname, expected_cmd) as (
  values
    ('public', 'profiles', 'Admin full access profiles', 'ALL'),
    ('public', 'profiles', 'Player read own profile', 'SELECT'),
    ('public', 'profiles', 'Player insert own profile', 'INSERT'),
    ('public', 'profiles', 'Player update own profile', 'UPDATE'),

    ('public', 'teams', 'Admin full access teams', 'ALL'),
    ('public', 'teams', 'Manager full access teams', 'ALL'),
    ('public', 'teams', 'Role read teams', 'SELECT'),

    ('public', 'players', 'Admin full access players', 'ALL'),
    ('public', 'players', 'Manager full access players', 'ALL'),
    ('public', 'players', 'Role read players', 'SELECT'),

    ('public', 'matches', 'Admin full access matches', 'ALL'),
    ('public', 'matches', 'Manager full access matches', 'ALL'),
    ('public', 'matches', 'Role read matches', 'SELECT'),

    ('public', 'match_events', 'Admin full access match events', 'ALL'),
    ('public', 'match_events', 'Manager full access match events', 'ALL'),
    ('public', 'match_events', 'Role read match events', 'SELECT'),

    ('public', 'player_match_stats', 'Admin full access player match stats', 'ALL'),
    ('public', 'player_match_stats', 'Manager full access player match stats', 'ALL'),
    ('public', 'player_match_stats', 'Player read own stats', 'SELECT'),

    ('public', 'videos', 'Admin full access videos', 'ALL'),
    ('public', 'videos', 'Manager read videos', 'SELECT'),
    ('public', 'videos', 'Manager upload videos', 'INSERT'),
    ('public', 'videos', 'Player read videos', 'SELECT'),

    ('public', 'upload_jobs', 'Admin full access upload jobs', 'ALL'),
    ('public', 'upload_jobs', 'Manager create upload jobs', 'INSERT'),
    ('public', 'upload_jobs', 'Manager read own upload jobs', 'SELECT'),
    ('public', 'upload_jobs', 'Manager update own upload jobs', 'UPDATE'),

    ('public', 'notifications', 'Admin full access notifications', 'ALL'),
    ('public', 'notifications', 'User read own notifications', 'SELECT'),
    ('public', 'notifications', 'User update own notifications', 'UPDATE'),

    ('public', 'activity_logs', 'Admin read activity logs', 'SELECT'),
    ('public', 'activity_logs', 'User insert own activity', 'INSERT'),
    ('public', 'activity_logs', 'User read own activity', 'SELECT'),

    ('storage', 'objects', 'Public read team logos', 'SELECT'),
    ('storage', 'objects', 'Public read player images', 'SELECT'),
    ('storage', 'objects', 'Admin full access match videos', 'ALL'),
    ('storage', 'objects', 'Manager read match videos', 'SELECT'),
    ('storage', 'objects', 'Manager upload match videos', 'INSERT'),
    ('storage', 'objects', 'Player read match videos', 'SELECT')
)
select
  e.schemaname,
  e.tablename,
  e.policyname,
  e.expected_cmd,
  coalesce(p.cmd, 'MISSING') as actual_cmd,
  case
    when p.policyname is null then 'FAIL'
    when p.cmd <> e.expected_cmd then 'FAIL'
    else 'PASS'
  end as validation_status
from expected_policies e
left join pg_policies p
  on p.schemaname = e.schemaname
 and p.tablename = e.tablename
 and p.policyname = e.policyname
order by e.schemaname, e.tablename, e.policyname;

-- ============================================================
-- 5) Predicate coverage: upload_jobs ownership enforcement
-- ============================================================

with upload_job_checks(check_name, policyname, required_cmd, requires_qual, requires_with_check) as (
  values
    (
      'upload_jobs admin full access uses admin role',
      'Admin full access upload jobs',
      'ALL',
      array['has_role', 'admin'],
      array['has_role', 'admin']
    ),
    (
      'upload_jobs manager insert is own uploaded_by only',
      'Manager create upload jobs',
      'INSERT',
      array[]::text[],
      array['has_role', 'manager', 'uploaded_by', 'auth.uid']
    ),
    (
      'upload_jobs manager select is own uploaded_by only',
      'Manager read own upload jobs',
      'SELECT',
      array['has_role', 'manager', 'uploaded_by', 'auth.uid'],
      array[]::text[]
    ),
    (
      'upload_jobs manager update is own uploaded_by only',
      'Manager update own upload jobs',
      'UPDATE',
      array['has_role', 'manager', 'uploaded_by', 'auth.uid'],
      array['has_role', 'manager', 'uploaded_by', 'auth.uid']
    )
),
evaluated as (
  select
    c.check_name,
    p.policyname,
    p.cmd,
    lower(coalesce(p.qual, '')) as qual,
    lower(coalesce(p.with_check, '')) as with_check,
    c.required_cmd,
    c.requires_qual,
    c.requires_with_check
  from upload_job_checks c
  left join pg_policies p
    on p.schemaname = 'public'
   and p.tablename = 'upload_jobs'
   and p.policyname = c.policyname
)
select
  check_name,
  case
    when policyname is null then 'FAIL'
    when cmd <> required_cmd then 'FAIL'
    when exists (select 1 from unnest(requires_qual) as token(value) where qual not like '%' || token.value || '%') then 'FAIL'
    when exists (select 1 from unnest(requires_with_check) as token(value) where with_check not like '%' || token.value || '%') then 'FAIL'
    else 'PASS'
  end as validation_status,
  'Catalog predicate check. Requires authenticated client validation for runtime proof.' as note
from evaluated
order by check_name;

-- ============================================================
-- 6) Predicate coverage: player_match_stats profile linkage
-- ============================================================

select
  'player_match_stats player self-access uses players.profile_id linkage' as check_name,
  case
    when p.policyname is null then 'FAIL'
    when p.cmd <> 'SELECT' then 'FAIL'
    when lower(coalesce(p.qual, '')) not like '%has_role%' then 'FAIL'
    when lower(coalesce(p.qual, '')) not like '%player%' then 'FAIL'
    when lower(coalesce(p.qual, '')) not like '%exists%' then 'FAIL'
    when lower(coalesce(p.qual, '')) not like '%players%' then 'FAIL'
    when lower(coalesce(p.qual, '')) not like '%profile_id%' then 'FAIL'
    when lower(coalesce(p.qual, '')) not like '%auth.uid%' then 'FAIL'
    else 'PASS'
  end as validation_status,
  p.qual as actual_predicate,
  'Catalog predicate check. Requires authenticated client validation for runtime proof.' as note
from (select 1) seed
left join pg_policies p
  on p.schemaname = 'public'
 and p.tablename = 'player_match_stats'
 and p.policyname = 'Player read own stats';

-- ============================================================
-- 7) Predicate coverage: notifications ownership enforcement
-- ============================================================

with notification_checks(check_name, policyname, required_cmd, requires_qual, requires_with_check) as (
  values
    (
      'notifications user select is own user_id only',
      'User read own notifications',
      'SELECT',
      array['user_id', 'auth.uid'],
      array[]::text[]
    ),
    (
      'notifications user update is own user_id only',
      'User update own notifications',
      'UPDATE',
      array['user_id', 'auth.uid'],
      array['user_id', 'auth.uid']
    ),
    (
      'notifications admin full access uses admin role',
      'Admin full access notifications',
      'ALL',
      array['has_role', 'admin'],
      array['has_role', 'admin']
    )
),
evaluated as (
  select
    c.check_name,
    p.policyname,
    p.cmd,
    lower(coalesce(p.qual, '')) as qual,
    lower(coalesce(p.with_check, '')) as with_check,
    c.required_cmd,
    c.requires_qual,
    c.requires_with_check
  from notification_checks c
  left join pg_policies p
    on p.schemaname = 'public'
   and p.tablename = 'notifications'
   and p.policyname = c.policyname
)
select
  check_name,
  case
    when policyname is null then 'FAIL'
    when cmd <> required_cmd then 'FAIL'
    when exists (select 1 from unnest(requires_qual) as token(value) where qual not like '%' || token.value || '%') then 'FAIL'
    when exists (select 1 from unnest(requires_with_check) as token(value) where with_check not like '%' || token.value || '%') then 'FAIL'
    else 'PASS'
  end as validation_status,
  'Catalog predicate check. Requires authenticated client validation for runtime proof.' as note
from evaluated
order by check_name;

-- ============================================================
-- 8) Predicate coverage: activity_logs ownership enforcement
-- ============================================================

with activity_checks(check_name, policyname, required_cmd, requires_qual, requires_with_check) as (
  values
    (
      'activity_logs user insert is own actor_id only',
      'User insert own activity',
      'INSERT',
      array[]::text[],
      array['actor_id', 'auth.uid']
    ),
    (
      'activity_logs user select is own actor_id only',
      'User read own activity',
      'SELECT',
      array['actor_id', 'auth.uid'],
      array[]::text[]
    ),
    (
      'activity_logs admin read uses admin role',
      'Admin read activity logs',
      'SELECT',
      array['has_role', 'admin'],
      array[]::text[]
    )
),
evaluated as (
  select
    c.check_name,
    p.policyname,
    p.cmd,
    lower(coalesce(p.qual, '')) as qual,
    lower(coalesce(p.with_check, '')) as with_check,
    c.required_cmd,
    c.requires_qual,
    c.requires_with_check
  from activity_checks c
  left join pg_policies p
    on p.schemaname = 'public'
   and p.tablename = 'activity_logs'
   and p.policyname = c.policyname
)
select
  check_name,
  case
    when policyname is null then 'FAIL'
    when cmd <> required_cmd then 'FAIL'
    when exists (select 1 from unnest(requires_qual) as token(value) where qual not like '%' || token.value || '%') then 'FAIL'
    when exists (select 1 from unnest(requires_with_check) as token(value) where with_check not like '%' || token.value || '%') then 'FAIL'
    else 'PASS'
  end as validation_status,
  'Catalog predicate check. Requires authenticated client validation for runtime proof.' as note
from evaluated
order by check_name;

-- ============================================================
-- 9) Storage policy and bucket coverage
-- ============================================================

with expected_buckets(bucket_id, expected_public) as (
  values
    ('team-logos', true),
    ('player-images', true),
    ('match-videos', false)
)
select
  e.bucket_id,
  e.expected_public,
  b.public as actual_public,
  case
    when b.id is null then 'FAIL'
    when b.public is distinct from e.expected_public then 'FAIL'
    else 'PASS'
  end as validation_status
from expected_buckets e
left join storage.buckets b on b.id = e.bucket_id
order by e.bucket_id;

with storage_checks(check_name, policyname, required_cmd, required_tokens) as (
  values
    ('storage public team logos readable', 'Public read team logos', 'SELECT', array['team-logos']),
    ('storage public player images readable', 'Public read player images', 'SELECT', array['player-images']),
    ('storage admin match videos full access', 'Admin full access match videos', 'ALL', array['match-videos', 'has_role', 'admin']),
    ('storage manager match videos read', 'Manager read match videos', 'SELECT', array['match-videos', 'has_role', 'manager']),
    ('storage manager match videos upload', 'Manager upload match videos', 'INSERT', array['match-videos', 'has_role', 'manager']),
    ('storage player match videos read', 'Player read match videos', 'SELECT', array['match-videos', 'has_role', 'player'])
),
evaluated as (
  select
    c.check_name,
    p.policyname,
    p.cmd,
    lower(coalesce(p.qual, '') || ' ' || coalesce(p.with_check, '')) as predicate_text,
    c.required_cmd,
    c.required_tokens
  from storage_checks c
  left join pg_policies p
    on p.schemaname = 'storage'
   and p.tablename = 'objects'
   and p.policyname = c.policyname
)
select
  check_name,
  case
    when policyname is null then 'FAIL'
    when cmd <> required_cmd then 'FAIL'
    when exists (select 1 from unnest(required_tokens) as token(value) where predicate_text not like '%' || token.value || '%') then 'FAIL'
    else 'PASS'
  end as validation_status,
  'Policy catalog check only. Requires authenticated client validation for upload/download proof.' as note
from evaluated
order by check_name;

-- ============================================================
-- 10) Realtime publication coverage
-- ============================================================

with expected_realtime_tables(table_name) as (
  values
    ('matches'),
    ('match_events'),
    ('player_match_stats'),
    ('tracking_snapshots'),
    ('videos'),
    ('upload_jobs'),
    ('notifications'),
    ('activity_logs')
)
select
  e.table_name,
  case
    when p.tablename is null then 'FAIL'
    else 'PASS'
  end as validation_status,
  case
    when p.tablename is null then 'missing from supabase_realtime'
    else 'present in supabase_realtime'
  end as finding
from expected_realtime_tables e
left join pg_publication_tables p
  on p.pubname = 'supabase_realtime'
 and p.schemaname = 'public'
 and p.tablename = e.table_name
order by e.table_name;

-- ============================================================
-- 11) Production sign-off summary
-- ============================================================

with expected_public_rls(table_name) as (
  values
    ('profiles'),
    ('teams'),
    ('players'),
    ('matches'),
    ('match_events'),
    ('player_match_stats'),
    ('videos'),
    ('upload_jobs'),
    ('notifications'),
    ('activity_logs')
),
public_tables as (
  select c.relname as table_name, c.relrowsecurity
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relkind = 'r'
),
rls_failures as (
  select 'RLS disabled or table missing: ' || e.table_name as failure
  from expected_public_rls e
  left join public_tables t on t.table_name = e.table_name
  where t.table_name is null
     or not t.relrowsecurity
),
expected_policy_count as (
  select 39 as required_count
),
actual_policy_count as (
  select count(*) as actual_count
  from pg_policies
  where (schemaname = 'public' and tablename in (
    'profiles',
    'teams',
    'players',
    'matches',
    'match_events',
    'player_match_stats',
    'videos',
    'upload_jobs',
    'notifications',
    'activity_logs'
  ))
  or (schemaname = 'storage' and tablename = 'objects' and policyname in (
    'Public read team logos',
    'Public read player images',
    'Admin full access match videos',
    'Manager read match videos',
    'Manager upload match videos',
    'Player read match videos'
  ))
),
realtime_failures as (
  select 'Realtime publication missing: ' || e.table_name as failure
  from (values
    ('matches'),
    ('match_events'),
    ('player_match_stats'),
    ('tracking_snapshots'),
    ('videos'),
    ('upload_jobs'),
    ('notifications'),
    ('activity_logs')
  ) e(table_name)
  left join pg_publication_tables p
    on p.pubname = 'supabase_realtime'
   and p.schemaname = 'public'
   and p.tablename = e.table_name
  where p.tablename is null
)
select
  case
    when exists (select 1 from rls_failures) then 'FAIL'
    when (select actual_count from actual_policy_count) < (select required_count from expected_policy_count) then 'FAIL'
    when exists (select 1 from realtime_failures) then 'FAIL'
    else 'PASS_WITH_AUTH_CLIENT_VALIDATION_REQUIRED'
  end as production_sql_signoff_status,
  (select actual_count from actual_policy_count) as detected_required_policy_count,
  (select required_count from expected_policy_count) as minimum_required_policy_count,
  'SQL catalog checks cannot prove runtime auth.uid() behavior. Requires authenticated client validation.' as required_follow_up;
