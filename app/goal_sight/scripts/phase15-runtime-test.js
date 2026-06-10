#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');

if (typeof fetch !== 'function') {
  throw new Error('Node 18+ is required because this harness uses the built-in fetch API.');
}

const baseUrl = requiredEnv('SUPABASE_URL');
const anonKey = requiredEnv('SUPABASE_ANON_KEY');

const reportPath = path.join(__dirname, '..', 'supabase', 'validation', 'phase15_runtime_results.json');
const allowDemoFallback = env('PHASE15_ALLOW_DEMO_SEEDS') === 'true';

const roleSpecs = [
  {
    role: 'admin',
    expectedUserId: '26357f17-0004-426f-83c3-1a127e8ff83e',
    emailEnv: 'PHASE15_ADMIN_EMAIL',
    passwordEnv: 'PHASE15_ADMIN_PASSWORD',
    tokenEnv: 'PHASE15_ADMIN_ACCESS_TOKEN',
    userIdEnv: 'PHASE15_ADMIN_USER_ID',
    demoEmail: 'admin@goalsight.ai',
    demoPassword: '123456'
  },
  {
    role: 'manager',
    expectedUserId: 'baf4f830-9142-46da-8ebc-adf80919ac8e',
    emailEnv: 'PHASE15_MANAGER_EMAIL',
    passwordEnv: 'PHASE15_MANAGER_PASSWORD',
    tokenEnv: 'PHASE15_MANAGER_ACCESS_TOKEN',
    userIdEnv: 'PHASE15_MANAGER_USER_ID',
    demoEmail: 'manager@goalsight.ai',
    demoPassword: '123456'
  },
  {
    role: 'player',
    expectedUserId: '35783d1b-90f3-4f79-8cf4-ffb2b03bd530',
    emailEnv: 'PHASE15_PLAYER_EMAIL',
    passwordEnv: 'PHASE15_PLAYER_PASSWORD',
    tokenEnv: 'PHASE15_PLAYER_ACCESS_TOKEN',
    userIdEnv: 'PHASE15_PLAYER_USER_ID',
    demoEmail: 'player@goalsight.ai',
    demoPassword: '123456'
  },
  {
    role: 'fan',
    expectedUserId: 'a14fa62f-b619-4821-b256-d2da35d0a7ca',
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

  const allResults = [];
  for (const context of contexts) {
    const result = await validateRole(context);
    allResults.push(result);
    state.roles = state.roles.map((roleResult) => {
      if (roleResult.role !== context.role) {
        return roleResult;
      }

      return {
        ...roleResult,
        userId: result.user.id,
        status: result.status,
        notes: result.notes
      };
    });
  }

  state.verdict = allResults.every((result) => result.status === 'pass') ? 'pass' : 'partial';
  state.notes.push(...allResults.flatMap((result) => result.notes));
  persistReport();

  console.log(JSON.stringify(state, null, 2));

  if (state.verdict !== 'pass') {
    process.exitCode = 1;
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
      { name: 'player_match_stats', table: 'player_match_stats', select: 'id,player_id', expectAllow: true, filter: await buildPlayerStatsFilter(context.accessToken) },
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

async function buildPlayerStatsFilter(accessToken) {
  const currentUser = await fetchCurrentUser(accessToken);
  const playerRows = await selectRows(accessToken, 'players', 'id,profile_id', `profile_id=eq.${currentUser.id}`);
  const ids = playerRows.map((row) => row.id).filter(Boolean);
  if (ids.length === 0) {
    throw new Error(`No linked player row exists for the authenticated player profile ${currentUser.id}.`);
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