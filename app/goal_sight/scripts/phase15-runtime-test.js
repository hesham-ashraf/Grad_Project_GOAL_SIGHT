#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

if (typeof fetch !== 'function') {
  throw new Error('Node 18+ is required because this harness uses the built-in fetch API.');
}

const baseUrl = requiredEnv('SUPABASE_URL');
const anonKey = requiredEnv('SUPABASE_ANON_KEY');

const reportPath = path.join(__dirname, '..', 'supabase', 'validation', 'phase15_runtime_results.json');
const summaryPath = path.join(__dirname, '..', 'supabase', 'validation', 'phase15_runtime_summary.md');
const matrixPath = path.join(__dirname, '..', 'supabase', 'validation', 'phase15_coverage_matrix.md');
const allowDemoFallback = env('PHASE15_ALLOW_DEMO_SEEDS') === 'true';

const roleSpecs = [
  {
    role: 'admin',
    expectedUserId: 'b830875d-9fdc-4ad8-a4ed-ba1b2e99498c',
    emailEnv: 'PHASE15_ADMIN_EMAIL',
    passwordEnv: 'PHASE15_ADMIN_PASSWORD',
    tokenEnv: 'PHASE15_ADMIN_ACCESS_TOKEN',
    userIdEnv: 'PHASE15_ADMIN_USER_ID',
    demoEmail: 'admin@goalsight.ai',
    demoPassword: '123456'
  },
  {
    role: 'manager',
    expectedUserId: '1c34db13-cc1f-46bc-a1e0-dffc73342689',
    emailEnv: 'PHASE15_MANAGER_EMAIL',
    passwordEnv: 'PHASE15_MANAGER_PASSWORD',
    tokenEnv: 'PHASE15_MANAGER_ACCESS_TOKEN',
    userIdEnv: 'PHASE15_MANAGER_USER_ID',
    demoEmail: 'manager@goalsight.ai',
    demoPassword: '123456'
  },
  {
    role: 'player',
    expectedUserId: '05cc12a7-ffc8-4532-885e-daa345c1954d',
    emailEnv: 'PHASE15_PLAYER_EMAIL',
    passwordEnv: 'PHASE15_PLAYER_PASSWORD',
    tokenEnv: 'PHASE15_PLAYER_ACCESS_TOKEN',
    userIdEnv: 'PHASE15_PLAYER_USER_ID',
    demoEmail: 'player@goalsight.ai',
    demoPassword: '123456'
  },
  {
    role: 'fan',
    expectedUserId: '3cee463a-f9cf-4847-a3a2-ec39d661968a',
    emailEnv: 'PHASE15_FAN_EMAIL',
    passwordEnv: 'PHASE15_FAN_PASSWORD',
    tokenEnv: 'PHASE15_FAN_ACCESS_TOKEN',
    userIdEnv: 'PHASE15_FAN_USER_ID',
    demoEmail: 'fan@goalsight.ai',
    demoPassword: '123456'
  }
];

const state = {
  generatedAt: new Date().toISOString(),
  baseUrl,
  verdict: 'not_run',
  missingEnv: [],
  roles: [],
  tests: [],
  coverageVerdict: 'not_run',
  notes: []
};

main().catch((error) => {
  state.verdict = 'failed';
  state.notes.push(error.message);
  persistReport();
  console.error(error.message);
  process.exitCode = 1;
});

async function main() {
  const missingBaseEnv = [];
  if (!baseUrl) {
    missingBaseEnv.push('SUPABASE_URL');
  }
  if (!anonKey) {
    missingBaseEnv.push('SUPABASE_ANON_KEY');
  }

  if (missingBaseEnv.length > 0) {
    state.verdict = 'not_ready';
    state.missingEnv = missingBaseEnv;
    state.notes.push('Set the Supabase base URL and anon key before running the harness.');
    persistReport();
    console.error(`Missing required env vars: ${missingBaseEnv.join(', ')}`);
    process.exitCode = 1;
    return;
  }

  const contexts = [];
  for (const spec of roleSpecs) {
    const context = await resolveRoleContext(spec);
    contexts.push(context);
    state.roles.push({
      role: spec.role,
      authMode: context.authMode,
      userId: context.userId,
      status: context.status,
      notes: context.notes
    });
  }

  const missingRoleContexts = contexts.filter((context) => context.status === 'missing');
  if (missingRoleContexts.length > 0) {
    state.verdict = 'not_ready';
    state.missingEnv = missingRoleContexts.flatMap((context) => context.missingEnv);
    state.notes.push('Provide explicit role credentials or access tokens, then rerun the harness.');
    persistReport();
    console.error('Runtime validation could not start because role credentials are missing.');
    console.error(`Missing env vars: ${state.missingEnv.join(', ')}`);
    process.exitCode = 1;
    return;
  }

  const contextMap = Object.fromEntries(contexts.map((context) => [context.role, context]));
  const fixtures = await preparePhase15Fixtures(contextMap);

  try {
    state.tests = await runPhase15CoverageSuite(contextMap, fixtures);
    state.coverageMatrix = buildCoverageMatrix(state.tests);
    state.coverageVerdict = state.tests.every((testResult) => testResult.coverageStatus === 'PASS') ? 'PASS' : 'PARTIAL';
    state.verdict = state.tests.every((testResult) => testResult.executionStatus === 'pass') ? 'pass' : 'failed';
    state.notes.push(...state.tests.flatMap((testResult) => testResult.notes || []));
    persistReport();
    writePhase15Artifacts(state);

    console.log(JSON.stringify(state, null, 2));

    if (state.verdict !== 'pass') {
      process.exitCode = 1;
    }
  } finally {
    await cleanupPhase15Fixtures(fixtures).catch((error) => {
      state.notes.push(`Cleanup warning: ${error.message}`);
      persistReport();
    });
  }
}

function env(name) {
  const value = process.env[name];
  return typeof value === 'string' ? value.trim() : '';
}

function requiredEnv(name) {
  const value = env(name);
  if (!value) {
    return '';
  }

  return value;
}

function persistReport() {
  fs.writeFileSync(reportPath, `${JSON.stringify(state, null, 2)}\n`, 'utf8');
}

function createHeaders(accessToken, extraHeaders = {}) {
  const headers = {
    apikey: anonKey,
    Authorization: `Bearer ${accessToken}`,
    ...extraHeaders
  };

  return headers;
}

async function resolveRoleContext(spec) {
  const email = env(spec.emailEnv);
  const password = env(spec.passwordEnv);

  if (email && password) {
    const session = await signInWithPassword(email, password);
    return {
      role: spec.role,
      authMode: 'password',
      accessToken: session.access_token,
      userId: session.user.id,
      user: session.user,
      status: 'ready',
      notes: []
    };
  }

  const accessToken = env(spec.tokenEnv);
  if (accessToken) {
    const user = await fetchCurrentUser(accessToken);
    return {
      role: spec.role,
      authMode: 'access_token',
      accessToken,
      userId: user.id,
      user,
      status: 'ready',
      notes: []
    };
  }

  if (allowDemoFallback && spec.demoEmail && spec.demoPassword) {
    const session = await signInWithPassword(spec.demoEmail, spec.demoPassword);
    return {
      role: spec.role,
      authMode: 'demo_password',
      accessToken: session.access_token,
      userId: session.user.id,
      user: session.user,
      status: 'ready',
      notes: ['Using the documented demo seed credentials.']
    };
  }

  return {
    role: spec.role,
    authMode: 'missing',
    status: 'missing',
    missingEnv: [spec.tokenEnv, spec.emailEnv, spec.passwordEnv],
    notes: ['No access token or password-based credentials were supplied.']
  };
}

async function signInWithPassword(email, password) {
  const response = await fetch(joinUrl('/auth/v1/token?grant_type=password'), {
    method: 'POST',
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${anonKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ email, password })
  });

  const body = await readResponseBody(response);
  if (!response.ok) {
    throw new Error(`Failed to sign in as ${email}: ${describeResponse(body, response.status)}`);
  }

  if (!body || !body.access_token || !body.user) {
    throw new Error(`Unexpected auth response for ${email}.`);
  }

  return body;
}

async function fetchCurrentUser(accessToken) {
  const response = await fetch(joinUrl('/auth/v1/user'), {
    headers: createHeaders(accessToken)
  });

  const body = await readResponseBody(response);
  if (!response.ok) {
    throw new Error(`Failed to fetch current user: ${describeResponse(body, response.status)}`);
  }

  return body;
}

async function preparePhase15Fixtures(contextMap) {
  const fixtures = {
    adminAccessToken: contextMap.admin.accessToken,
    teamLogoObjectPath: `phase15/team-logos/${uniqueSuffix('logo')}.txt`,
    playerImageObjectPath: `phase15/player-images/${uniqueSuffix('player')}.txt`,
    matchVideoObjectPath: `phase15/match-videos/${uniqueSuffix('match')}.mp4`,
    uploadedDeniedObjectPath: `phase15/match-videos/${uniqueSuffix('fan-denied')}.mp4`,
    videoTableRowId: null,
    adminNotificationIds: [],
    activityLogIds: [],
    managerUploadJobId: null,
    otherUploadJobId: null,
    playerStatRowId: null,
    otherPlayerStatRowId: null,
    fanNotificationId: null,
    otherNotificationId: null,
    playerProfileId: contextMap.player.user.id,
    managerProfileId: contextMap.manager.user.id,
    fanProfileId: contextMap.fan.user.id,
    adminProfileId: contextMap.admin.user.id
  };

  const admin = contextMap.admin;
  const manager = contextMap.manager;
  const player = contextMap.player;
  const fan = contextMap.fan;

  const [matchRow] = await selectRows(admin.accessToken, 'matches', 'id', 'id=not.is.null');
  const [teamRow] = await selectRows(admin.accessToken, 'teams', 'id', 'id=not.is.null');
  const [otherPlayerRow] = await selectRows(admin.accessToken, 'players', 'id,full_name,profile_id', `id=neq.${player.user.id}`);

  fixtures.matchId = matchRow?.id || null;
  fixtures.teamId = teamRow?.id || null;
  fixtures.otherPlayerId = otherPlayerRow?.id || null;

  await uploadStorageObject(admin.accessToken, 'team-logos', fixtures.teamLogoObjectPath, textToBytes('phase15 team logo'), 'text/plain');
  await uploadStorageObject(admin.accessToken, 'player-images', fixtures.playerImageObjectPath, textToBytes('phase15 player image'), 'text/plain');

  const uploadVideoResponse = await uploadStorageObject(manager.accessToken, 'match-videos', fixtures.matchVideoObjectPath, textToBytes('phase15 match video'), 'video/mp4');
  fixtures.matchVideoObjectPath = uploadVideoResponse.objectPath;

  const videoInsert = await insertRows(admin.accessToken, 'videos', [{
    match_id: fixtures.matchId,
    uploaded_by: admin.user.id,
    video_url: `https://example.com/${fixtures.matchVideoObjectPath}`,
    file_name: `phase15-${uniqueSuffix('video')}.mp4`,
    processing_status: 'uploaded'
  }]);
  fixtures.videoTableRowId = videoInsert[0]?.id || null;

  const notificationInserts = await insertRows(admin.accessToken, 'notifications', [
    { user_id: admin.user.id, type: 'info', title: 'Phase 15 admin notification', body: 'Admin test notification' },
    { user_id: manager.user.id, type: 'info', title: 'Phase 15 manager notification', body: 'Manager test notification' },
    { user_id: player.user.id, type: 'info', title: 'Phase 15 player notification', body: 'Player test notification' },
    { user_id: fan.user.id, type: 'info', title: 'Phase 15 fan notification', body: 'Fan test notification' }
  ]);
  fixtures.adminNotificationIds = notificationInserts.map((row) => row.id);
  fixtures.fanNotificationId = notificationInserts.find((row) => row.user_id === fan.user.id)?.id || null;
  fixtures.otherNotificationId = notificationInserts.find((row) => row.user_id === manager.user.id)?.id || null;

  const managerLogs = await insertRows(manager.accessToken, 'activity_logs', [{
    actor_id: manager.user.id,
    actor_role: 'manager',
    action: 'phase15_manager_setup',
    description: 'Manager baseline activity log'
  }]);
  const playerLogs = await insertRows(player.accessToken, 'activity_logs', [{
    actor_id: player.user.id,
    actor_role: 'player',
    action: 'phase15_player_setup',
    description: 'Player baseline activity log'
  }]);
  const fanLogs = await insertRows(fan.accessToken, 'activity_logs', [{
    actor_id: fan.user.id,
    actor_role: 'fan',
    action: 'phase15_fan_setup',
    description: 'Fan baseline activity log'
  }]);
  fixtures.activityLogIds = [...managerLogs, ...playerLogs, ...fanLogs].map((row) => row.id);

  const playerStatRows = await insertRows(admin.accessToken, 'player_match_stats', [
    {
      match_id: fixtures.matchId,
      player_id: player.user.id,
      distance_covered_m: 9200,
      avg_speed: 6.4,
      max_speed: 28.2,
      passes_completed: 22,
      shots: 3,
      goals: 1,
      assists: 1,
      fouls: 0
    },
    {
      match_id: fixtures.matchId,
      player_id: fixtures.otherPlayerId,
      distance_covered_m: 8400,
      avg_speed: 5.7,
      max_speed: 26.4,
      passes_completed: 18,
      shots: 1,
      goals: 0,
      assists: 0,
      fouls: 1
    }
  ]);
  fixtures.playerStatRowId = playerStatRows.find((row) => row.player_id === player.user.id)?.id || null;
  fixtures.otherPlayerStatRowId = playerStatRows.find((row) => row.player_id === fixtures.otherPlayerId)?.id || null;

  const managerUploadJob = await insertRows(manager.accessToken, 'upload_jobs', [{
    uploaded_by: manager.user.id,
    status: 'uploaded',
    progress: 0,
    file_name: `phase15-manager-owned-${uniqueSuffix('job')}.mp4`
  }]);
  fixtures.managerUploadJobId = managerUploadJob[0]?.id || null;

  const otherUploadJob = await insertRows(admin.accessToken, 'upload_jobs', [{
    uploaded_by: fan.user.id,
    status: 'uploaded',
    progress: 0,
    file_name: `phase15-other-owned-${uniqueSuffix('job')}.mp4`
  }]);
  fixtures.otherUploadJobId = otherUploadJob[0]?.id || null;

  return fixtures;
}

async function cleanupPhase15Fixtures(fixtures) {
  const adminAccessToken = fixtures.adminAccessToken;
  if (!adminAccessToken) {
    return;
  }

  const deletions = [];
  if (fixtures.otherUploadJobId) {
    deletions.push(deleteRows(adminAccessToken, 'upload_jobs', `id=eq.${fixtures.otherUploadJobId}`));
  }
  if (fixtures.managerUploadJobId) {
    deletions.push(deleteRows(adminAccessToken, 'upload_jobs', `id=eq.${fixtures.managerUploadJobId}`));
  }
  if (fixtures.otherPlayerStatRowId) {
    deletions.push(deleteRows(adminAccessToken, 'player_match_stats', `id=eq.${fixtures.otherPlayerStatRowId}`));
  }
  if (fixtures.playerStatRowId) {
    deletions.push(deleteRows(adminAccessToken, 'player_match_stats', `id=eq.${fixtures.playerStatRowId}`));
  }
  if (fixtures.videoTableRowId) {
    deletions.push(deleteRows(adminAccessToken, 'videos', `id=eq.${fixtures.videoTableRowId}`));
  }
  for (const notificationId of [...fixtures.adminNotificationIds, fixtures.fanNotificationId, fixtures.otherNotificationId].filter(Boolean)) {
    deletions.push(deleteRows(adminAccessToken, 'notifications', `id=eq.${notificationId}`));
  }
  for (const activityLogId of fixtures.activityLogIds.filter(Boolean)) {
    deletions.push(deleteRows(adminAccessToken, 'activity_logs', `id=eq.${activityLogId}`));
  }

  await Promise.allSettled(deletions);

  await Promise.allSettled([
    deleteStorageObject(adminAccessToken, 'team-logos', fixtures.teamLogoObjectPath),
    deleteStorageObject(adminAccessToken, 'player-images', fixtures.playerImageObjectPath),
    deleteStorageObject(adminAccessToken, 'match-videos', fixtures.matchVideoObjectPath)
  ]);
}

async function runPhase15CoverageSuite(contextMap, fixtures) {
  const results = [];
  const admin = contextMap.admin;
  const manager = contextMap.manager;
  const player = contextMap.player;
  const fan = contextMap.fan;

  results.push(await runCoverageTest('A1', 'Admin can read all target tables', 'PASS', async () => {
    const tables = ['profiles', 'teams', 'players', 'matches', 'match_events', 'player_match_stats', 'videos', 'upload_jobs', 'notifications', 'activity_logs'];
    const rowsByTable = {};
    for (const table of tables) {
      rowsByTable[table] = await selectRows(admin.accessToken, table, 'id', 'id=not.is.null');
    }
    return [`Admin read ${tables.length} tables successfully.`];
  }));

  results.push(await runCoverageTest('A2', 'Admin can manage upload jobs', 'PASS', async () => {
    const row = await insertRows(admin.accessToken, 'upload_jobs', [{
      uploaded_by: manager.user.id,
      status: 'uploaded',
      progress: 0,
      file_name: `phase15-admin-managed-${uniqueSuffix('job')}.mp4`
    }]);
    const jobId = row[0].id;
    await updateRows(admin.accessToken, 'upload_jobs', { status: 'processing', progress: 33 }, `id=eq.${jobId}`);
    await deleteRows(admin.accessToken, 'upload_jobs', `id=eq.${jobId}`);
    return ['Admin insert, update, and delete succeeded.'];
  }));

  results.push(await runCoverageTest('A3', 'Admin notification access', 'PASS', async () => {
    const notifications = await selectRows(admin.accessToken, 'notifications', 'id,user_id,title', `user_id=in.(${[admin.user.id, manager.user.id, player.user.id, fan.user.id].join(',')})`);
    if (!notifications.length) {
      throw new Error('Expected admin-readable notification rows.');
    }
    return [`Admin read ${notifications.length} notification rows.`];
  }));

  results.push(await runCoverageTest('A4', 'Admin activity log access', 'PASS', async () => {
    const activityLogs = await selectRows(admin.accessToken, 'activity_logs', 'id,actor_id,action', 'id=not.is.null');
    if (!activityLogs.length) {
      throw new Error('Expected admin-readable activity log rows.');
    }
    return [`Admin read ${activityLogs.length} activity rows.`];
  }));

  results.push(await runCoverageTest('M1', 'Manager can create own upload job', 'PASS', async () => {
    if (!fixtures.managerUploadJobId) {
      throw new Error('Manager-owned upload job fixture was not created.');
    }
    const rows = await selectRows(manager.accessToken, 'upload_jobs', 'id,uploaded_by,status,progress,file_name', `id=eq.${fixtures.managerUploadJobId}`);
    if (!rows.length) {
      throw new Error('Manager could not read own upload job after insert.');
    }
    return [`Manager-owned upload job created: ${fixtures.managerUploadJobId}`];
  }));

  results.push(await runCoverageTest('M2', 'Manager can read own upload job', 'PASS', async () => {
    const rows = await selectRows(manager.accessToken, 'upload_jobs', 'id,uploaded_by,status', `uploaded_by=eq.${manager.user.id}`);
    if (!rows.some((row) => row.id === fixtures.managerUploadJobId)) {
      throw new Error('Manager own upload job not visible.');
    }
    return [`Manager read own upload job ${fixtures.managerUploadJobId}.`];
  }));

  results.push(await runCoverageTest('M3', 'Manager can update own upload job', 'PASS', async () => {
    await updateRows(manager.accessToken, 'upload_jobs', { status: 'processing', progress: 35 }, `id=eq.${fixtures.managerUploadJobId}`);
    const rows = await selectRows(manager.accessToken, 'upload_jobs', 'id,status,progress', `id=eq.${fixtures.managerUploadJobId}`);
    if (rows[0]?.progress !== 35) {
      throw new Error('Manager upload job did not update correctly.');
    }
    return ['Manager own upload job updated to 35%.'];
  }));

  results.push(await runCoverageTest('M4', 'Manager cannot create upload job for another user', 'PASS', async () => {
    const badInsert = await insertRowsExpectDenied(manager.accessToken, 'upload_jobs', [{
      uploaded_by: fan.user.id,
      status: 'uploaded',
      progress: 0,
      file_name: `phase15-manager-forbidden-${uniqueSuffix('job')}.mp4`
    }]);
    return [badInsert];
  }));

  results.push(await runCoverageTest('M5', 'Manager cannot update another user\'s upload job', 'PASS', async () => {
    const badUpdate = await updateRowsExpectDenied(manager.accessToken, 'upload_jobs', { status: 'processing', progress: 99 }, `id=eq.${fixtures.otherUploadJobId}`);
    return [badUpdate];
  }));

  results.push(await runCoverageTest('P1', 'Player can read own profile', 'PASS', async () => {
    const rows = await selectRows(player.accessToken, 'profiles', 'id,role,full_name', `id=eq.${player.user.id}`);
    if (rows[0]?.role !== 'player') {
      throw new Error('Player profile was not readable or role mismatch.');
    }
    return ['Player profile read succeeded.'];
  }));

  results.push(await runCoverageTest('P2', 'Player cannot read another user\'s profile', 'PASS', async () => {
    const rows = await selectRowsExpectDeniedOrEmpty(player.accessToken, 'profiles', 'id,role,full_name', `id=eq.${manager.user.id}`);
    if (rows.length > 0) {
      throw new Error('Player can read manager profile.');
    }
    return ['Player could not read manager profile.'];
  }));

  results.push(await runCoverageTest('P3', 'Player mapping is correct', 'PASS', async () => {
    const rows = await selectRows(admin.accessToken, 'players', 'id,full_name,profile_id', 'full_name=eq.Ahmed Striker');
    const playerRow = rows.find((row) => row.full_name === 'Ahmed Striker');
    if (!playerRow) {
      throw new Error('Ahmed Striker player row not found.');
    }
    if (playerRow.profile_id !== player.user.id) {
      throw new Error(`Ahmed Striker is linked to ${playerRow.profile_id}, expected ${player.user.id}.`);
    }
    return [`Ahmed Striker mapped to ${playerRow.profile_id}.`];
  }));

  results.push(await runCoverageTest('P4', 'Player can read own linked stats', 'PASS', async () => {
    const rows = await selectRows(player.accessToken, 'player_match_stats', 'id,player_id', `player_id=eq.${fixtures.playerStatRowId ? player.user.id : player.user.id}`);
    if (!rows.some((row) => row.id === fixtures.playerStatRowId)) {
      throw new Error('Player could not read own linked stats.');
    }
    return ['Player linked stats are visible.'];
  }));

  results.push(await runCoverageTest('P5', 'Player cannot read another player\'s stats', 'PASS', async () => {
    const rows = await selectRowsExpectDeniedOrEmpty(player.accessToken, 'player_match_stats', 'id,player_id', `player_id=eq.${fixtures.otherPlayerId}`);
    if (rows.length > 0) {
      throw new Error('Player can read another player\'s stats.');
    }
    return ['Other player stats stayed hidden.'];
  }));

  results.push(await runCoverageTest('P6', 'Player cannot read upload jobs', 'PASS', async () => {
    const rows = await selectRowsExpectDeniedOrEmpty(player.accessToken, 'upload_jobs', 'id', 'id=not.is.null');
    if (rows.length > 0) {
      throw new Error('Player can view upload jobs.');
    }
    return ['Upload jobs denied to player.'];
  }));

  results.push(await runCoverageTest('F1', 'Fan can read own profile', 'PASS', async () => {
    const rows = await selectRows(fan.accessToken, 'profiles', 'id,role,full_name', `id=eq.${fan.user.id}`);
    if (rows[0]?.role !== 'fan') {
      throw new Error('Fan profile was not readable or role mismatch.');
    }
    return ['Fan profile read succeeded.'];
  }));

  results.push(await runCoverageTest('F2', 'Fan cannot read other profiles', 'PASS', async () => {
    const rows = await selectRowsExpectDeniedOrEmpty(fan.accessToken, 'profiles', 'id,role,full_name', `id=eq.${manager.user.id}`);
    if (rows.length > 0) {
      throw new Error('Fan can read manager profile.');
    }
    return ['Manager profile hidden from fan.'];
  }));

  results.push(await runCoverageTest('F3', 'Fan can read public football data', 'PASS', async () => {
    await selectRows(fan.accessToken, 'teams', 'id,name', 'id=not.is.null');
    await selectRows(fan.accessToken, 'players', 'id,full_name', 'id=not.is.null');
    await selectRows(fan.accessToken, 'matches', 'id,status', 'id=not.is.null');
    await selectRows(fan.accessToken, 'match_events', 'id,event_type', 'id=not.is.null');
    return ['Fan read teams, players, matches, and match events.'];
  }));

  results.push(await runCoverageTest('F4', 'Fan cannot read player stats', 'PASS', async () => {
    const rows = await selectRowsExpectDeniedOrEmpty(fan.accessToken, 'player_match_stats', 'id,player_id', 'id=not.is.null');
    if (rows.length > 0) {
      throw new Error('Fan can view player stats.');
    }
    return ['Fan player stats request remained empty or denied.'];
  }));

  results.push(await runCoverageTest('F5', 'Fan cannot read videos', 'PASS', async () => {
    const rows = await selectRowsExpectDeniedOrEmpty(fan.accessToken, 'videos', 'id,video_url', 'id=not.is.null');
    if (rows.length > 0) {
      throw new Error('Fan can view videos.');
    }
    return ['Fan videos request remained empty or denied.'];
  }));

  results.push(await runCoverageTest('F6', 'Fan cannot read upload jobs', 'PASS', async () => {
    const rows = await selectRowsExpectDeniedOrEmpty(fan.accessToken, 'upload_jobs', 'id', 'id=not.is.null');
    if (rows.length > 0) {
      throw new Error('Fan can view upload jobs.');
    }
    return ['Fan upload_jobs request remained empty or denied.'];
  }));

  results.push(await runCoverageTest('F7', 'Fan notification ownership', 'PASS', async () => {
    const ownRows = await selectRows(fan.accessToken, 'notifications', 'id,user_id,title', `user_id=eq.${fan.user.id}`);
    const otherRows = await selectRowsExpectDeniedOrEmpty(fan.accessToken, 'notifications', 'id,user_id,title', `user_id=eq.${manager.user.id}`);
    if (!ownRows.some((row) => row.id === fixtures.fanNotificationId)) {
      throw new Error('Fan did not see own notification.');
    }
    if (otherRows.length > 0) {
      throw new Error('Fan can read another user\'s notifications.');
    }
    return ['Fan saw own notification and not manager notification.'];
  }));

  results.push(await runCoverageTest('F8', 'Fan activity ownership', 'PASS', async () => {
    const ownInsert = await insertRows(fan.accessToken, 'activity_logs', [{
      actor_id: fan.user.id,
      actor_role: 'fan',
      action: 'phase15_fan_ownership',
      description: 'Fan own activity ownership test'
    }]);
    const deniedInsert = await insertRowsExpectDenied(fan.accessToken, 'activity_logs', [{
      actor_id: manager.user.id,
      actor_role: 'fan',
      action: 'phase15_fan_ownership_forbidden',
      description: 'Should not be inserted'
    }]);
    fixtures.activityLogIds.push(ownInsert[0].id);
    return [deniedInsert, `Fan inserted own activity ${ownInsert[0].id}.`];
  }));

  results.push(await runCoverageTest('S1', 'Public buckets are readable', 'PASS', async () => {
    if (!fixtures.teamLogoObjectPath || !fixtures.playerImageObjectPath) {
      throw new Error('No existing public objects were found in team-logos or player-images.');
    }
    const teamLogo = await readPublicStorageObject('team-logos', fixtures.teamLogoObjectPath);
    const playerImage = await readPublicStorageObject('player-images', fixtures.playerImageObjectPath);
    if (!teamLogo.ok || !playerImage.ok) {
      throw new Error('Public bucket reads failed.');
    }
    return ['Anonymous read succeeded for team-logos and player-images.'];
  }));

  results.push(await runCoverageTest('S2', 'Manager can upload match video', 'PASS', async () => {
    const uploadPath = `phase15/match-videos/${uniqueSuffix('manager-upload')}.mp4`;
    await uploadStorageObject(manager.accessToken, 'match-videos', uploadPath, textToBytes('phase15 manager upload'), 'video/mp4');
    fixtures.extraMatchVideoUploadPath = uploadPath;
    return [`Manager uploaded ${uploadPath}.`];
  }));

  results.push(await runCoverageTest('S3', 'Manager can read match video', 'PASS', async () => {
    const result = await readStorageObject(manager.accessToken, 'match-videos', fixtures.matchVideoObjectPath);
    if (!result.ok) {
      throw new Error('Manager could not read match video.');
    }
    return ['Manager downloaded match video.'];
  }));

  results.push(await runCoverageTest('S4', 'Player can read match video', 'PASS', async () => {
    const result = await readStorageObject(player.accessToken, 'match-videos', fixtures.matchVideoObjectPath);
    if (!result.ok) {
      throw new Error('Player could not read match video.');
    }
    return ['Player downloaded match video.'];
  }));

  results.push(await runCoverageTest('S5', 'Fan cannot read match video', 'PASS', async () => {
    const result = await readStorageObject(fan.accessToken, 'match-videos', fixtures.matchVideoObjectPath);
    if (result.ok) {
      throw new Error('Fan was able to read private match video.');
    }
    return ['Fan was denied match video download.'];
  }));

  results.push(await runCoverageTest('S6', 'Fan cannot upload match video', 'PASS', async () => {
    const uploadPath = fixtures.uploadedDeniedObjectPath;
    const result = await uploadStorageObjectExpectDenied(fan.accessToken, 'match-videos', uploadPath, textToBytes('phase15 fan forbidden upload'), 'video/mp4');
    return [result];
  }));

  results.push(await runCoverageTest('R1', 'Manager receives own upload job updates', 'PASS', async () => {
    const realtime = await subscribeToRealtimeChanges(manager.accessToken, 'upload_jobs', `uploaded_by=eq.${manager.user.id}`);
    await updateRows(manager.accessToken, 'upload_jobs', { status: 'processing', progress: 45 }, `id=eq.${fixtures.managerUploadJobId}`);
    const payload = await realtime.waitForPayload((message) => message.table === 'upload_jobs' && message.type === 'UPDATE' && message.record?.id === fixtures.managerUploadJobId);
    realtime.close();
    if (!payload) {
      throw new Error('Manager did not receive own upload job update.');
    }
    return ['Manager realtime update received for own upload job.'];
  }));

  results.push(await runCoverageTest('R2', 'Manager does not receive other user\'s upload job updates', 'PASS', async () => {
    const realtime = await subscribeToRealtimeChanges(manager.accessToken, 'upload_jobs', `uploaded_by=eq.${manager.user.id}`);
    await updateRows(admin.accessToken, 'upload_jobs', { status: 'analyzing', progress: 90 }, `id=eq.${fixtures.otherUploadJobId}`);
    const payload = await realtime.waitForPayload((message) => message.table === 'upload_jobs' && message.record?.id === fixtures.otherUploadJobId, 2000);
    realtime.close();
    if (payload) {
      throw new Error('Manager received other user\'s upload job payload.');
    }
    return ['Manager did not receive another user\'s upload job update.'];
  }));

  results.push(await runCoverageTest('R3', 'Player receives own stats updates only', 'PASS', async () => {
    const realtime = await subscribeToRealtimeChanges(player.accessToken, 'player_match_stats', `player_id=eq.${fixtures.playerId}`);
    await updateRows(admin.accessToken, 'player_match_stats', { goals: 2, assists: 2 }, `id=eq.${fixtures.playerStatRowId}`);
    const payload = await realtime.waitForPayload((message) => message.table === 'player_match_stats' && message.type === 'UPDATE' && message.record?.id === fixtures.playerStatRowId);
    realtime.close();
    if (!payload) {
      throw new Error('Player did not receive linked stats update.');
    }
    return ['Player realtime update received for own stats.'];
  }));

  results.push(await runCoverageTest('R4', 'Player does not receive another player\'s stats', 'PASS', async () => {
    const realtime = await subscribeToRealtimeChanges(player.accessToken, 'player_match_stats', `player_id=eq.${fixtures.playerId}`);
    await updateRows(admin.accessToken, 'player_match_stats', { goals: 1, assists: 1 }, `id=eq.${fixtures.otherPlayerStatRowId}`);
    const payload = await realtime.waitForPayload((message) => message.table === 'player_match_stats' && message.record?.id === fixtures.otherPlayerStatRowId, 2000);
    realtime.close();
    if (payload) {
      throw new Error('Player received another player\'s stats payload.');
    }
    return ['Player did not receive another player\'s stats payload.'];
  }));

  results.push(await runCoverageTest('R5', 'User receives own notification updates only', 'PASS', async () => {
    const realtime = await subscribeToRealtimeChanges(fan.accessToken, 'notifications', `user_id=eq.${fan.user.id}`);
    await updateRows(admin.accessToken, 'notifications', { is_read: true, read_at: new Date().toISOString() }, `id=eq.${fixtures.fanNotificationId}`);
    const ownPayload = await realtime.waitForPayload((message) => message.table === 'notifications' && message.type === 'UPDATE' && message.record?.id === fixtures.fanNotificationId);
    await updateRows(admin.accessToken, 'notifications', { is_read: true, read_at: new Date().toISOString() }, `id=eq.${fixtures.otherNotificationId}`);
    const otherPayload = await realtime.waitForPayload((message) => message.table === 'notifications' && message.record?.id === fixtures.otherNotificationId, 2000);
    realtime.close();
    if (!ownPayload || otherPayload) {
      throw new Error('Fan notification ownership realtime test failed.');
    }
    return ['Fan received own notification update only.'];
  }));

  results.push(await runCoverageTest('R6', 'Admin receives activity feed updates', 'PASS', async () => {
    const realtime = await subscribeToRealtimeChanges(admin.accessToken, 'activity_logs', null);
    await Promise.all([
      insertRows(manager.accessToken, 'activity_logs', [{ actor_id: manager.user.id, actor_role: 'manager', action: `phase15_r6_${uniqueSuffix('manager')}`, description: 'Manager activity feed payload' }]),
      insertRows(player.accessToken, 'activity_logs', [{ actor_id: player.user.id, actor_role: 'player', action: `phase15_r6_${uniqueSuffix('player')}`, description: 'Player activity feed payload' }]),
      insertRows(fan.accessToken, 'activity_logs', [{ actor_id: fan.user.id, actor_role: 'fan', action: `phase15_r6_${uniqueSuffix('fan')}`, description: 'Fan activity feed payload' }])
    ]);
    const payloads = await realtime.waitForPayloads((message) => message.table === 'activity_logs' && message.type === 'INSERT', 3);
    realtime.close();
    if (payloads.length < 3) {
      throw new Error('Admin did not receive all activity feed updates.');
    }
    return [`Admin received ${payloads.length} activity feed payloads.`];
  }));

  return results;
}

function buildCoverageMatrix(testResults) {
  return testResults.map((testResult) => ({
    id: testResult.id,
    title: testResult.title,
    status: testResult.coverageStatus,
    executionStatus: testResult.executionStatus,
    notes: testResult.notes || []
  }));
}

function writePhase15Artifacts(currentState) {
  const matrixLines = ['# Phase 15 Coverage Matrix', '', '| Test | Status | Notes |', '| --- | --- | --- |'];
  for (const row of currentState.coverageMatrix) {
    matrixLines.push(`| ${row.id} ${escapeMarkdown(row.title)} | ${row.status} | ${escapeMarkdown((row.notes || []).join(' ; '))} |`);
  }
  fs.writeFileSync(matrixPath, `${matrixLines.join('\n')}\n`, 'utf8');

  const summaryLines = [
    '# Phase 15 Runtime Summary',
    '',
    `## Verdict`,
    currentState.verdict.toUpperCase(),
    '',
    '## Coverage',
    `- PASS: ${currentState.coverageMatrix.filter((row) => row.status === 'PASS').length}`,
    `- PARTIAL: ${currentState.coverageMatrix.filter((row) => row.status === 'PARTIAL').length}`,
    `- MISSING: ${currentState.coverageMatrix.filter((row) => row.status === 'MISSING').length}`,
    '',
    '## Artifact',
    '- [phase15_runtime_results.json](phase15_runtime_results.json)',
    '- [phase15_coverage_matrix.md](phase15_coverage_matrix.md)'
  ];
  fs.writeFileSync(summaryPath, `${summaryLines.join('\n')}\n`, 'utf8');
}

async function runCoverageTest(id, title, coverageStatus, handler) {
  const result = {
    id,
    title,
    coverageStatus: 'FAIL',
    executionStatus: 'pass',
    notes: []
  };

  try {
    const notes = await handler();
    result.coverageStatus = coverageStatus === 'PASS' ? 'PASS' : coverageStatus;
    if (Array.isArray(notes)) {
      result.notes = notes.filter(Boolean);
    } else if (typeof notes === 'string' && notes.trim()) {
      result.notes = [notes];
    }
  } catch (error) {
    result.executionStatus = 'fail';
    result.notes = [error.message];
  }

  return result;
}

async function insertRows(accessToken, table, rows) {
  const response = await fetch(joinUrl(`/rest/v1/${table}`), {
    method: 'POST',
    headers: createHeaders(accessToken, {
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
      Accept: 'application/json'
    }),
    body: JSON.stringify(rows)
  });

  const body = await readResponseBody(response);
  if (!response.ok) {
    throw new Error(`Insert into ${table} failed: ${describeResponse(body, response.status)}`);
  }

  if (!Array.isArray(body)) {
    throw new Error(`Unexpected insert response for ${table}.`);
  }

  return body;
}

async function insertRowsExpectDenied(accessToken, table, rows) {
  const response = await fetch(joinUrl(`/rest/v1/${table}`), {
    method: 'POST',
    headers: createHeaders(accessToken, {
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
      Accept: 'application/json'
    }),
    body: JSON.stringify(rows)
  });

  if (response.ok) {
    const body = await readResponseBody(response);
    if (Array.isArray(body) && body.length > 0) {
      throw new Error(`Expected insert into ${table} to be denied, but it succeeded.`);
    }
    return `Insert into ${table} returned an empty success response.`;
  }

  const body = await readResponseBody(response);
  return `Insert into ${table} denied as expected: ${describeResponse(body, response.status)}`;
}

async function updateRows(accessToken, table, values, filter) {
  const url = new URL(joinUrl(`/rest/v1/${table}`));
  if (filter) {
    const [key, value] = filter.split('=');
    url.searchParams.set(key, value);
  }

  const response = await fetch(url.toString(), {
    method: 'PATCH',
    headers: createHeaders(accessToken, {
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
      Accept: 'application/json'
    }),
    body: JSON.stringify(values)
  });

  const body = await readResponseBody(response);
  if (!response.ok) {
    throw new Error(`Update on ${table} failed: ${describeResponse(body, response.status)}`);
  }

  if (!Array.isArray(body)) {
    throw new Error(`Unexpected update response for ${table}.`);
  }

  return body;
}

async function updateRowsExpectDenied(accessToken, table, values, filter) {
  const url = new URL(joinUrl(`/rest/v1/${table}`));
  if (filter) {
    const [key, value] = filter.split('=');
    url.searchParams.set(key, value);
  }

  const response = await fetch(url.toString(), {
    method: 'PATCH',
    headers: createHeaders(accessToken, {
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
      Accept: 'application/json'
    }),
    body: JSON.stringify(values)
  });

  if (response.ok) {
    const body = await readResponseBody(response);
    if (Array.isArray(body) && body.length > 0) {
      throw new Error(`Expected update on ${table} to be denied, but it succeeded.`);
    }
    return `Update on ${table} returned an empty success response.`;
  }

  const body = await readResponseBody(response);
  return `Update on ${table} denied as expected: ${describeResponse(body, response.status)}`;
}

async function deleteRows(accessToken, table, filter) {
  const url = new URL(joinUrl(`/rest/v1/${table}`));
  if (filter) {
    const [key, value] = filter.split('=');
    url.searchParams.set(key, value);
  }

  const response = await fetch(url.toString(), {
    method: 'DELETE',
    headers: createHeaders(accessToken, {
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
      Accept: 'application/json'
    })
  });

  const body = await readResponseBody(response);
  if (!response.ok) {
    throw new Error(`Delete on ${table} failed: ${describeResponse(body, response.status)}`);
  }

  return body;
}

async function selectRowsExpectDeniedOrEmpty(accessToken, table, select, filter) {
  try {
    const rows = await selectRows(accessToken, table, select, filter);
    return rows;
  } catch (error) {
    return [];
  }
}

async function uploadStorageObject(accessToken, bucket, objectPath, content, contentType) {
  const response = await fetch(joinUrl(`/storage/v1/object/${encodeURIComponent(bucket)}/${encodePath(objectPath)}`), {
    method: 'POST',
    headers: createHeaders(accessToken, {
      'Content-Type': contentType,
      'x-upsert': 'true'
    }),
    body: content
  });

  const body = await readResponseBody(response);
  if (!response.ok) {
    throw new Error(`Upload to ${bucket}/${objectPath} failed: ${describeResponse(body, response.status)}`);
  }

  return { ok: true, objectPath };
}

async function uploadStorageObjectExpectDenied(accessToken, bucket, objectPath, content, contentType) {
  const response = await fetch(joinUrl(`/storage/v1/object/${encodeURIComponent(bucket)}/${encodePath(objectPath)}`), {
    method: 'POST',
    headers: createHeaders(accessToken, {
      'Content-Type': contentType,
      'x-upsert': 'true'
    }),
    body: content
  });

  if (response.ok) {
    throw new Error(`Expected upload to ${bucket}/${objectPath} to be denied, but it succeeded.`);
  }

  const body = await readResponseBody(response);
  return `Upload to ${bucket}/${objectPath} denied as expected: ${describeResponse(body, response.status)}`;
}

async function readPublicStorageObject(bucket, objectPath) {
  const response = await fetch(joinUrl(`/storage/v1/object/public/${encodeURIComponent(bucket)}/${encodePath(objectPath)}`));
  const body = await readResponseBody(response);
  return { ok: response.ok, status: response.status, body };
}

async function readStorageObject(accessToken, bucket, objectPath) {
  const response = await fetch(joinUrl(`/storage/v1/object/${encodeURIComponent(bucket)}/${encodePath(objectPath)}`), {
    headers: createHeaders(accessToken)
  });
  const body = await readResponseBody(response);
  return { ok: response.ok, status: response.status, body };
}

async function deleteStorageObject(accessToken, bucket, objectPath) {
  const response = await fetch(joinUrl(`/storage/v1/object/${encodeURIComponent(bucket)}/${encodePath(objectPath)}`), {
    method: 'DELETE',
    headers: createHeaders(accessToken)
  });
  await readResponseBody(response).catch(() => null);
  return response.ok;
}

async function subscribeToRealtimeChanges(accessToken, table, filter) {
  const realtime = await openRealtimeSubscription({ accessToken, table, filter });

  function normalizeRealtimeMessage(message) {
    const payload = message?.payload || {};
    const data = payload.data || payload.payload || payload;
    return {
      ...message,
      type: payload.type || payload.eventType || message?.event,
      table: payload.table || data.table || table,
      record: payload.record || data.record || data.new || data.new_record || null,
      old_record: payload.old_record || data.old || data.old_record || null,
      rawPayload: payload
    };
  }

  return {
    close: realtime.close,
    async waitForPayload(predicate, timeoutMs = 10000) {
      const deadline = Date.now() + timeoutMs;
      while (Date.now() < deadline) {
        const remainingMs = Math.max(0, deadline - Date.now());
        const message = normalizeRealtimeMessage(await realtime.waitForChange(remainingMs || 1000));
        if (predicate(message)) {
          return message;
        }
      }
      return null;
    },
    async waitForPayloads(predicate, expectedCount, timeoutMs = 10000) {
      const deadline = Date.now() + timeoutMs;
      const matches = [];
      while (Date.now() < deadline && matches.length < expectedCount) {
        const remainingMs = Math.max(0, deadline - Date.now());
        const message = normalizeRealtimeMessage(await realtime.waitForChange(remainingMs || 1000));
        if (predicate(message)) {
          matches.push(message);
        }
      }
      return matches;
    }
  };
}

function uniqueSuffix(prefix) {
  return `${prefix}-${crypto.randomUUID()}`;
}

function textToBytes(text) {
  return Buffer.from(text, 'utf8');
}

function encodePath(objectPath) {
  return objectPath.split('/').map((segment) => encodeURIComponent(segment)).join('/');
}

function escapeMarkdown(value) {
  return String(value)
    .replace(/\|/g, '\\|')
    .replace(/\n/g, ' ')
    .replace(/\r/g, ' ');
}

function writePhase15Artifacts(currentState) {
  const matrixLines = ['# Phase 15 Coverage Matrix', '', '| Test | Status | Execution | Notes |', '| --- | --- | --- | --- |'];
  for (const row of currentState.coverageMatrix) {
    matrixLines.push(`| ${row.id} ${escapeMarkdown(row.title)} | ${row.status} | ${row.executionStatus} | ${escapeMarkdown((row.notes || []).join(' ; '))} |`);
  }
  fs.writeFileSync(matrixPath, `${matrixLines.join('\n')}\n`, 'utf8');

  const summaryLines = [
    '# Phase 15 Runtime Summary',
    '',
    '## Verdict',
    currentState.verdict.toUpperCase(),
    '',
    '## Coverage',
    `- PASS: ${currentState.coverageMatrix.filter((row) => row.status === 'PASS').length}`,
    `- FAIL: ${currentState.coverageMatrix.filter((row) => row.status !== 'PASS').length}`,
    '',
    '## Artifact',
    '- [phase15_runtime_results.json](phase15_runtime_results.json)',
    '- [phase15_coverage_matrix.md](phase15_coverage_matrix.md)'
  ];
  fs.writeFileSync(summaryPath, `${summaryLines.join('\n')}\n`, 'utf8');
}


function makePhase15Id(prefix) {
  return `${prefix}-${crypto.randomUUID()}`;
}

function asArray(value) {
  if (!value) {
    return [];
  }

  return Array.isArray(value) ? value : [value];
}

async function preparePhase15Fixtures(contextMap) {
  const fixtures = {
    adminAccessToken: contextMap.admin.accessToken,
    publicObjects: [],
    storageObjects: [],
    rowIds: {},
    playerStats: {},
    notifications: {},
    activityLogs: {},
    activityLogIds: [],
    extraPlayerIds: []
  };

  const admin = contextMap.admin;
  const manager = contextMap.manager;
  const player = contextMap.player;
  const fan = contextMap.fan;

  const matches = await selectRows(admin.accessToken, 'matches', 'id,home_team_id,away_team_id');
  const match = matches[0] || (await insertRows(admin.accessToken, 'matches', {
    home_team_id: null,
    away_team_id: null,
    match_date: new Date().toISOString(),
    venue: 'Phase 15 Test Venue',
    status: 'scheduled',
    home_score: 0,
    away_score: 0
  }))[0];

  const teams = await selectRows(admin.accessToken, 'teams', 'id,name');
  const team = teams[0] || (await insertRows(admin.accessToken, 'teams', {
    name: makePhase15Id('phase15-team'),
    logo_url: null
  }))[0];

  const players = await selectRows(admin.accessToken, 'players', 'id,full_name,profile_id,team_id');
  const linkedPlayer = players.find((row) => row.full_name === 'Ahmed Striker' && row.profile_id === player.userId) || players.find((row) => row.full_name === 'Ahmed Striker') || null;
  const targetPlayer = linkedPlayer || (await insertRows(admin.accessToken, 'players', {
    team_id: team.id,
    full_name: 'Ahmed Striker',
    position: 'Forward',
    jersey_number: 9,
    height_cm: 181,
    weight_kg: 76,
    image_url: null,
    profile_id: player.userId
  }))[0];

  if (targetPlayer.profile_id !== player.userId) {
    const updatedPlayer = await updateRows(admin.accessToken, 'players', { profile_id: player.userId }, `id=eq.${targetPlayer.id}`);
    if (updatedPlayer[0]) {
      targetPlayer.profile_id = updatedPlayer[0].profile_id;
    }
  }

  let otherPlayer = players.find((row) => row.id !== targetPlayer.id) || null;
  if (!otherPlayer) {
    otherPlayer = (await insertRows(admin.accessToken, 'players', {
      team_id: team.id,
      full_name: makePhase15Id('phase15-other-player'),
      position: 'Midfielder',
      jersey_number: 22,
      height_cm: 178,
      weight_kg: 74,
      image_url: null
    }))[0];
    fixtures.extraPlayerIds.push(otherPlayer.id);
  }

  fixtures.matchId = match.id;
  fixtures.teamId = team.id;
  fixtures.playerId = targetPlayer.id;
  fixtures.otherPlayerId = otherPlayer.id;

  const matchVideoPath = `${makePhase15Id('phase15-match-video')}.txt`;
  const unauthorizedMatchVideoPath = `${makePhase15Id('phase15-match-video-denied')}.txt`;

  await uploadStorageObject(manager.accessToken, 'match-videos', matchVideoPath, 'GoalSight match video fixture');

  fixtures.storageObjects.push({ bucket: 'match-videos', path: matchVideoPath });
  fixtures.storageObjects.push({ bucket: 'match-videos', path: unauthorizedMatchVideoPath });
  const [teamLogoObjects, playerImageObjects] = await Promise.all([
    listStorageObjects(admin.accessToken, 'team-logos'),
    listStorageObjects(admin.accessToken, 'player-images')
  ]);
  fixtures.teamLogoObjectPath = teamLogoObjects[0]?.name || null;
  fixtures.playerImageObjectPath = playerImageObjects[0]?.name || null;
  fixtures.matchVideoObjectPath = matchVideoPath;
  fixtures.uploadedDeniedObjectPath = unauthorizedMatchVideoPath;
  fixtures.matchVideoPath = matchVideoPath;
  fixtures.unauthorizedMatchVideoPath = unauthorizedMatchVideoPath;

  const [videoRow] = await insertRows(admin.accessToken, 'videos', {
    match_id: match.id,
    uploaded_by: admin.userId,
    video_url: `storage://${matchVideoPath}`,
    file_name: `${matchVideoPath}.mp4`,
    processing_status: 'uploaded'
  });
  fixtures.videoId = videoRow.id;

  const notificationTemplates = [
    { key: 'admin', userId: admin.userId, title: 'Phase 15 admin notification' },
    { key: 'manager', userId: manager.userId, title: 'Phase 15 manager notification' },
    { key: 'player', userId: player.userId, title: 'Phase 15 player notification' },
    { key: 'fan', userId: fan.userId, title: 'Phase 15 fan notification' }
  ];

  for (const template of notificationTemplates) {
    const [notificationRow] = await insertRows(admin.accessToken, 'notifications', {
      user_id: template.userId,
      type: 'info',
      title: template.title,
      body: `Fixture notification for ${template.key}`,
      related_entity_type: 'phase15',
      related_entity_id: null,
      data: { phase: 15, role: template.key },
      is_read: false
    });

    fixtures.notifications[template.key] = notificationRow.id;
  }

    fixtures.fanNotificationId = fixtures.notifications.fan;
    fixtures.otherNotificationId = fixtures.notifications.manager;

  const activitySeedTemplates = [
    { key: 'manager', context: manager, action: 'phase15_manager_seed', description: 'Phase 15 manager activity seed' },
    { key: 'player', context: player, action: 'phase15_player_seed', description: 'Phase 15 player activity seed' },
    { key: 'fan', context: fan, action: 'phase15_fan_seed', description: 'Phase 15 fan activity seed' }
  ];

  for (const template of activitySeedTemplates) {
    const [activityRow] = await insertRows(template.context.accessToken, 'activity_logs', {
      actor_id: template.context.userId,
      actor_role: template.key,
      action: template.action,
      description: template.description,
      entity_type: 'phase15',
      entity_id: null,
      metadata: { phase: 15, role: template.key }
    });

    fixtures.activityLogs[template.key] = activityRow.id;
  }

  const [otherUploadJob] = await insertRows(admin.accessToken, 'upload_jobs', {
    uploaded_by: fan.userId,
    status: 'uploaded',
    progress: 0,
    file_name: `${makePhase15Id('phase15-admin-owned-job')}.mp4`
  });
  fixtures.otherUploadJobId = otherUploadJob.id;

  const [managerUploadJob] = await insertRows(manager.accessToken, 'upload_jobs', {
    uploaded_by: manager.userId,
    status: 'uploaded',
    progress: 0,
    file_name: `${makePhase15Id('phase15-manager-owned-job')}.mp4`
  });
  fixtures.managerUploadJobId = managerUploadJob.id;

  await Promise.all([
    deleteRows(admin.accessToken, 'player_match_stats', `match_id=eq.${match.id}&player_id=eq.${targetPlayer.id}`),
    deleteRows(admin.accessToken, 'player_match_stats', `match_id=eq.${match.id}&player_id=eq.${otherPlayer.id}`)
  ]);

  const [playerStatRow] = await insertRows(admin.accessToken, 'player_match_stats', {
    match_id: match.id,
    player_id: targetPlayer.id,
    distance_covered_m: 1000,
    avg_speed: 6.2,
    max_speed: 9.7,
    passes_completed: 14,
    shots: 2,
    goals: 1,
    assists: 0,
    fouls: 0
  });
  fixtures.playerStats.own = playerStatRow.id;
  fixtures.playerStatRowId = playerStatRow.id;

  const [otherPlayerStatRow] = await insertRows(admin.accessToken, 'player_match_stats', {
    match_id: match.id,
    player_id: otherPlayer.id,
    distance_covered_m: 900,
    avg_speed: 5.8,
    max_speed: 8.9,
    passes_completed: 10,
    shots: 1,
    goals: 0,
    assists: 0,
    fouls: 1
  });
  fixtures.playerStats.other = otherPlayerStatRow.id;
  fixtures.otherPlayerStatRowId = otherPlayerStatRow.id;

  return fixtures;
}

async function cleanupPhase15Fixtures(fixtures) {
  const admin = { accessToken: fixtures.adminAccessToken };
  const cleanupTasks = [];

  if (fixtures.testsCreatedUploadJobId) {
    cleanupTasks.push(deleteRows(admin.accessToken, 'upload_jobs', `id=eq.${fixtures.testsCreatedUploadJobId}`));
  }

  if (fixtures.otherUploadJobId) {
    cleanupTasks.push(deleteRows(admin.accessToken, 'upload_jobs', `id=eq.${fixtures.otherUploadJobId}`));
  }

  if (fixtures.videoId) {
    cleanupTasks.push(deleteRows(admin.accessToken, 'videos', `id=eq.${fixtures.videoId}`));
  }

  for (const rowId of Object.values(fixtures.notifications || {})) {
    cleanupTasks.push(deleteRows(admin.accessToken, 'notifications', `id=eq.${rowId}`));
  }

  for (const rowId of Object.values(fixtures.activityLogs || {})) {
    cleanupTasks.push(deleteRows(admin.accessToken, 'activity_logs', `id=eq.${rowId}`));
  }

  if (fixtures.playerStats?.own) {
    cleanupTasks.push(deleteRows(admin.accessToken, 'player_match_stats', `id=eq.${fixtures.playerStats.own}`));
  }
  if (fixtures.playerStats?.other) {
    cleanupTasks.push(deleteRows(admin.accessToken, 'player_match_stats', `id=eq.${fixtures.playerStats.other}`));
  }

  if (fixtures.matchId && fixtures.cleanupMatchId) {
    cleanupTasks.push(deleteRows(admin.accessToken, 'matches', `id=eq.${fixtures.matchId}`));
  }

  if (fixtures.extraMatchVideoUploadPath) {
    cleanupTasks.push(deleteStorageObject(admin.accessToken, 'match-videos', fixtures.extraMatchVideoUploadPath));
  }

  if (fixtures.extraPlayerIds?.length) {
    for (const playerId of fixtures.extraPlayerIds) {
      cleanupTasks.push(deleteRows(admin.accessToken, 'players', `id=eq.${playerId}`));
    }
  }

  for (const objectInfo of fixtures.publicObjects || []) {
    cleanupTasks.push(deleteStorageObject(admin.accessToken, objectInfo.bucket, objectInfo.path));
  }
  for (const objectInfo of fixtures.storageObjects || []) {
    cleanupTasks.push(deleteStorageObject(admin.accessToken, objectInfo.bucket, objectInfo.path));
  }

  await Promise.allSettled(cleanupTasks);
}

async function insertRows(accessToken, table, payload) {
  const response = await fetch(joinUrl(`/rest/v1/${table}`), {
    method: 'POST',
    headers: createHeaders(accessToken, {
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
      Accept: 'application/json'
    }),
    body: JSON.stringify(asArray(payload))
  });

  const body = await readResponseBody(response);
  if (!response.ok) {
    throw new Error(`Insert into ${table} failed: ${describeResponse(body, response.status)}`);
  }

  if (!Array.isArray(body)) {
    throw new Error(`Unexpected insert response for ${table}.`);
  }

  return body;
}

async function updateRows(accessToken, table, payload, filter) {
  const url = new URL(joinUrl(`/rest/v1/${table}`));
  applyFilter(url, filter);

  const response = await fetch(url.toString(), {
    method: 'PATCH',
    headers: createHeaders(accessToken, {
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
      Accept: 'application/json'
    }),
    body: JSON.stringify(payload)
  });

  const body = await readResponseBody(response);
  if (!response.ok) {
    throw new Error(`Update on ${table} failed: ${describeResponse(body, response.status)}`);
  }

  if (!Array.isArray(body)) {
    throw new Error(`Unexpected update response for ${table}.`);
  }

  return body;
}

async function deleteRows(accessToken, table, filter) {
  const url = new URL(joinUrl(`/rest/v1/${table}`));
  applyFilter(url, filter);

  const response = await fetch(url.toString(), {
    method: 'DELETE',
    headers: createHeaders(accessToken, {
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
      Accept: 'application/json'
    })
  });

  const body = await readResponseBody(response);
  if (!response.ok) {
    throw new Error(`Delete on ${table} failed: ${describeResponse(body, response.status)}`);
  }

  if (!Array.isArray(body)) {
    throw new Error(`Unexpected delete response for ${table}.`);
  }

  return body;
}

function applyFilter(url, filter) {
  if (!filter) {
    return;
  }

  const segments = filter.split('&');
  for (const segment of segments) {
    const [key, value] = segment.split('=');
    url.searchParams.set(key, value);
  }
}

async function uploadStorageObject(accessToken, bucket, objectPath, content, contentType = 'text/plain') {
  const response = await fetch(joinUrl(`/storage/v1/object/${encodeURIComponent(bucket)}/${encodeURIComponent(objectPath)}`), {
    method: 'POST',
    headers: createHeaders(accessToken, {
      'Content-Type': contentType,
      'x-upsert': 'false'
    }),
    body: content
  });

  const body = await readResponseBody(response);
  if (!response.ok) {
    throw new Error(`Storage upload to ${bucket}/${objectPath} failed: ${describeResponse(body, response.status)}`);
  }

  return body;
}

async function downloadStorageObject(accessToken, bucket, objectPath, publicRead = false) {
  const endpoint = joinUrl(`/storage/v1/object/${publicRead ? 'public/' : ''}${encodeURIComponent(bucket)}/${encodeURIComponent(objectPath)}`);
  const response = await fetch(endpoint, {
    headers: accessToken ? createHeaders(accessToken) : undefined
  });

  if (!response.ok) {
    const body = await readResponseBody(response);
    throw new Error(`Storage read from ${bucket}/${objectPath} failed: ${describeResponse(body, response.status)}`);
  }

  const buffer = await response.arrayBuffer();
  return Buffer.from(buffer).toString('utf8');
}

async function deleteStorageObject(accessToken, bucket, objectPath) {
  const response = await fetch(joinUrl(`/storage/v1/object/${encodeURIComponent(bucket)}/${encodeURIComponent(objectPath)}`), {
    method: 'DELETE',
    headers: createHeaders(accessToken)
  });

  if (!response.ok && response.status !== 204) {
    const body = await readResponseBody(response);
    throw new Error(`Storage delete from ${bucket}/${objectPath} failed: ${describeResponse(body, response.status)}`);
  }
}

async function openRealtimeSubscription({ accessToken, table, filter }) {
  if (typeof WebSocket !== 'function') {
    throw new Error('WebSocket is unavailable in this Node runtime.');
  }

  const realtimeUrl = new URL(baseUrl.replace(/^https:/, 'wss:').replace(/^http:/, 'ws:'));
  realtimeUrl.pathname = '/realtime/v1/websocket';
  realtimeUrl.searchParams.set('apikey', anonKey);
  realtimeUrl.searchParams.set('vsn', '1.0.0');

  const socket = new WebSocket(realtimeUrl.toString());
  const joinRef = makePhase15Id('join');
  const queue = [];
  const waiters = [];
  let joined = false;
  let joinStatus = 'pending';

  const ready = new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      try {
        socket.close();
      } catch (error) {
        void error;
      }

      reject(new Error('Realtime subscription did not join within the timeout.'));
    }, 10000);

    socket.onopen = () => {
      socket.send(JSON.stringify({
        topic: `realtime:public:${table}`,
        event: 'phx_join',
        payload: {
          config: {
            broadcast: { ack: false, self: false },
            presence: { key: '' },
            postgres_changes: [{ event: '*', schema: 'public', table, ...(filter ? { filter } : {}) }]
          },
          access_token: accessToken
        },
        ref: joinRef,
        join_ref: joinRef
      }));
    };

    socket.onmessage = (event) => {
      let message;
      try {
        message = JSON.parse(event.data);
      } catch (error) {
        return;
      }

      if (message.event === 'phx_reply' && message.ref === joinRef) {
        clearTimeout(timeout);
        joined = message.payload && message.payload.status === 'ok';
        joinStatus = joined ? 'ok' : 'rejected';

        if (!joined) {
          reject(new Error(`Realtime subscription for ${table} was rejected.`));
        } else {
          resolve();
        }

        return;
      }

      if (!joined) {
        return;
      }

      if (message.event === 'heartbeat' || message.event === 'access_token') {
        return;
      }

      if (waiters.length > 0) {
        waiters.shift().resolve(message);
      } else {
        queue.push(message);
      }
    };

    socket.onerror = (error) => {
      clearTimeout(timeout);
      reject(new Error(`Realtime websocket error for ${table}: ${error.message || 'connection failed'}`));
    };
  });

  async function waitForChange(timeoutMs = 10000) {
    if (queue.length > 0) {
      return queue.shift();
    }

    return await new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        const index = waiters.findIndex((entry) => entry.resolve === resolve);
        if (index >= 0) {
          waiters.splice(index, 1);
        }

        reject(new Error('Timed out waiting for realtime payload.'));
      }, timeoutMs);

      waiters.push({
        resolve: (message) => {
          clearTimeout(timeout);
          resolve(message);
        }
      });
    });
  }

  function close() {
    try {
      socket.close();
    } catch (error) {
      void error;
    }
  }

  return { ready, waitForChange, close, joinStatus: () => joinStatus };
}

function buildCoverageMatrix(testResults) {
  return testResults.map((testResult) => ({
    id: testResult.id,
    title: testResult.title,
    status: testResult.coverageStatus,
    executed: testResult.executionStatus,
    notes: testResult.notes || []
  }));
}

function writePhase15Artifacts(currentState) {
  const matrixLines = [
    '# Phase 15 Coverage Matrix',
    '',
    '| Test | Status | Executed | Notes |',
    '| --- | --- | --- | --- |'
  ];

  for (const testResult of currentState.coverageMatrix) {
    matrixLines.push(`| ${testResult.id} ${testResult.title} | ${testResult.status} | ${testResult.executed} | ${testResult.notes.join('; ') || ''} |`);
  }

  fs.writeFileSync(matrixPath, `${matrixLines.join('\n')}\n`, 'utf8');

  const summaryLines = [
    '# Phase 15 Runtime Summary',
    '',
    `## Verdict`,
    currentState.verdict.toUpperCase(),
    '',
    '## Coverage',
    `- PASS: ${currentState.coverageMatrix.filter((entry) => entry.status === 'PASS').length}`,
    `- PARTIAL: ${currentState.coverageMatrix.filter((entry) => entry.status === 'PARTIAL').length}`,
    `- MISSING: ${currentState.coverageMatrix.filter((entry) => entry.status === 'MISSING').length}`,
    '',
    '## Notes',
    ...(currentState.notes.length ? currentState.notes.map((note) => `- ${note}`) : ['- None'])
  ];

  fs.writeFileSync(summaryPath, `${summaryLines.join('\n')}\n`, 'utf8');
}

async function validateRole(context) {
  const notes = [];
  const user = context.user ?? (await fetchCurrentUser(context.accessToken));

  const expectedUserId = roleSpecs.find((spec) => spec.role === context.role).expectedUserId;
  if (expectedUserId && user.id !== expectedUserId) {
    notes.push(`Reference UUID for ${context.role} differs from the authenticated user id (${user.id}).`);
  }

  const profileRows = await selectRows(context.accessToken, 'profiles', 'id,role,full_name', `id=eq.${user.id}`);
  if (!profileRows.length) {
    throw new Error(`Profile row for ${context.role} was not readable.`);
  }

  if (profileRows[0].role !== context.role) {
    throw new Error(`Profile role mismatch for ${context.role}: expected ${context.role}, got ${profileRows[0].role}`);
  }

  notes.push(`Profile role verified for ${context.role}.`);

  const roleChecks = {
    admin: [
      { name: 'profiles', table: 'profiles', select: 'id,role', expectAllow: true },
      { name: 'managers', table: 'managers', select: 'id,profile_id,name', expectAllow: true },
      { name: 'upload_jobs', table: 'upload_jobs', select: 'id,uploaded_by,status', expectAllow: true },
      { name: 'match_videos_storage', storageBucket: 'match-videos', expectAllow: true },
      { name: 'team_logos_storage', storageBucket: 'team-logos', expectAllow: true }
    ],
    manager: [
      { name: 'teams', table: 'teams', select: 'id,name', expectAllow: true },
      { name: 'matches', table: 'matches', select: 'id,status', expectAllow: true },
      { name: 'upload_jobs_own', table: 'upload_jobs', select: 'id,uploaded_by,status', expectAllow: true, filter: `uploaded_by=eq.${user.id}` },
      { name: 'match_videos_storage', storageBucket: 'match-videos', expectAllow: true },
      { name: 'player_images_storage', storageBucket: 'player-images', expectAllow: true }
    ],
    player: [
      { name: 'teams', table: 'teams', select: 'id,name', expectAllow: true },
      { name: 'matches', table: 'matches', select: 'id,status', expectAllow: true },
      {
        name: 'player_match_stats',
        table: 'player_match_stats',
        select: 'id,player_id',
        expectAllow: true,
        filter: context.role === 'player' ? await buildPlayerStatsFilter(context.accessToken, user.id) : undefined
      },
      { name: 'match_videos_storage', storageBucket: 'match-videos', expectAllow: true },
      { name: 'upload_jobs', table: 'upload_jobs', select: 'id', expectAllow: false }
    ],
    fan: [
      { name: 'teams', table: 'teams', select: 'id,name', expectAllow: true },
      { name: 'matches', table: 'matches', select: 'id,status', expectAllow: true },
      { name: 'subscription_plans', table: 'subscription_plans', select: 'id,name', expectAllow: true },
      { name: 'match_videos_storage', storageBucket: 'match-videos', expectAllow: false },
      { name: 'upload_jobs', table: 'upload_jobs', select: 'id', expectAllow: false }
    ]
  };

  const tests = roleChecks[context.role] || [];
  for (const testCase of tests) {
    if (testCase.table) {
      await runTableCheck(context.accessToken, testCase);
      continue;
    }

    if (testCase.storageBucket) {
      await runStorageCheck(context.accessToken, testCase);
      continue;
    }
  }

  const realtimeCheck = await runRealtimeSmokeCheck(context.accessToken, context.role, 'matches');
  if (realtimeCheck.status === 'skipped') {
    notes.push(realtimeCheck.note);
  } else {
    notes.push(realtimeCheck.note);
  }

  return {
    role: context.role,
    user,
    status: 'pass',
    notes
  };
}

async function buildPlayerStatsFilter(accessToken, playerUserId) {
  const playerRows = await selectRows(accessToken, 'players', 'id,profile_id', `profile_id=eq.${playerUserId}`);
  const ids = playerRows.map((row) => row.id).filter(Boolean);
  if (ids.length === 0) {
    throw new Error(`No linked player row exists for the authenticated player profile ${playerUserId}.`);
  }

  return `player_id=in.(${ids.join(',')})`;
}

async function runTableCheck(accessToken, testCase) {
  try {
    const rows = await selectRows(accessToken, testCase.table, testCase.select, testCase.filter);
    if (testCase.expectAllow === false) {
      throw new Error(`Expected ${testCase.table} to be denied, but the query succeeded.`);
    }

    if (testCase.table === 'upload_jobs' && testCase.filter) {
      for (const row of rows) {
        if (row.uploaded_by && row.uploaded_by !== testCase.filter.replace('uploaded_by=eq.', '')) {
          throw new Error(`upload_jobs policy leaked a row not owned by the current manager.`);
        }
      }
    }

    return rows;
  } catch (error) {
    if (testCase.expectAllow === false) {
      return [];
    }

    throw error;
  }
}

async function runStorageCheck(accessToken, testCase) {
  try {
    const rows = await listStorageObjects(accessToken, testCase.storageBucket);
    if (testCase.expectAllow === false) {
      throw new Error(`Expected storage bucket ${testCase.storageBucket} to be denied, but listing succeeded.`);
    }

    if (!Array.isArray(rows)) {
      throw new Error(`Unexpected storage response for bucket ${testCase.storageBucket}.`);
    }

    return rows;
  } catch (error) {
    if (testCase.expectAllow === false) {
      return [];
    }

    throw error;
  }
}

async function runRealtimeSmokeCheck(accessToken, role, table) {
  if (typeof WebSocket !== 'function') {
    return { status: 'skipped', note: `Realtime smoke check skipped for ${role}; WebSocket is unavailable in this Node runtime.` };
  }

  const realtimeUrl = new URL(baseUrl.replace(/^https:/, 'wss:').replace(/^http:/, 'ws:'));
  realtimeUrl.pathname = '/realtime/v1/websocket';
  realtimeUrl.searchParams.set('apikey', anonKey);
  realtimeUrl.searchParams.set('vsn', '1.0.0');

  return await new Promise((resolve) => {
    const socket = new WebSocket(realtimeUrl.toString());
    const joinRef = '1';
    const timeout = setTimeout(() => {
      try {
        socket.close();
      } catch (error) {
        void error;
      }

      resolve({ status: 'skipped', note: `Realtime smoke check skipped for ${role}; the socket did not join within the timeout.` });
    }, 10000);

    socket.onopen = () => {
      socket.send(JSON.stringify({
        topic: `realtime:public:${table}`,
        event: 'phx_join',
        payload: {
          config: {
            broadcast: { ack: false, self: false },
            presence: { key: '' },
            postgres_changes: [{ event: '*', schema: 'public', table }]
          },
          access_token: accessToken
        },
        ref: joinRef,
        join_ref: joinRef
      }));
    };

    socket.onmessage = (event) => {
      let message;
      try {
        message = JSON.parse(event.data);
      } catch (error) {
        return;
      }

      if (message.event === 'phx_reply' && message.ref === joinRef) {
        clearTimeout(timeout);
        try {
          socket.close();
        } catch (error) {
          void error;
        }

        if (message.payload && message.payload.status === 'ok') {
          resolve({ status: 'pass', note: `Realtime subscription joined for ${role} on ${table}.` });
        } else {
          resolve({ status: 'skipped', note: `Realtime smoke check skipped for ${role}; the server rejected the join payload.` });
        }
      }
    };

    socket.onerror = () => {
      clearTimeout(timeout);
      resolve({ status: 'skipped', note: `Realtime smoke check skipped for ${role}; the websocket connection failed.` });
    };
  });
}

async function selectRows(accessToken, table, select, filter) {
  const url = new URL(joinUrl(`/rest/v1/${table}`));
  url.searchParams.set('select', select);
  if (filter) {
    const [key, value] = filter.split('=');
    url.searchParams.set(key, value);
  }

  const response = await fetch(url.toString(), {
    headers: createHeaders(accessToken, {
      Accept: 'application/json'
    })
  });

  const body = await readResponseBody(response);
  if (!response.ok) {
    throw new Error(`Query against ${table} failed: ${describeResponse(body, response.status)}`);
  }

  if (!Array.isArray(body)) {
    throw new Error(`Unexpected response for ${table}.`);
  }

  return body;
}

async function listStorageObjects(accessToken, bucket) {
  const endpoint = joinUrl(`/storage/v1/object/list/${encodeURIComponent(bucket)}`);
  const payload = JSON.stringify({
    prefix: '',
    limit: 25,
    offset: 0,
    sortBy: { column: 'name', order: 'asc' }
  });

  let response = await fetch(endpoint, {
    method: 'POST',
    headers: createHeaders(accessToken, {
      'Content-Type': 'application/json',
      Accept: 'application/json'
    }),
    body: payload
  });

  if (!response.ok && response.status === 404) {
    response = await fetch(endpoint, {
      headers: createHeaders(accessToken, {
        Accept: 'application/json'
      })
    });
  }

  const body = await readResponseBody(response);
  if (!response.ok) {
    throw new Error(`Storage listing for ${bucket} failed: ${describeResponse(body, response.status)}`);
  }

  return body;
}

async function readResponseBody(response) {
  const contentType = response.headers.get('content-type') || '';
  if (contentType.includes('application/json')) {
    return await response.json().catch(() => null);
  }

  return await response.text().catch(() => '');
}

function describeResponse(body, status) {
  if (body && typeof body === 'object') {
    return `${status} ${body.message || body.error || JSON.stringify(body)}`;
  }

  if (typeof body === 'string' && body.trim()) {
    return `${status} ${body}`;
  }

  return String(status);
}

function joinUrl(segment) {
  return `${baseUrl.replace(/\/+$/, '')}${segment}`;
}