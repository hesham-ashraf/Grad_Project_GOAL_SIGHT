/**
 * Match Model
 * PostgreSQL-backed match service (replaces Mongoose model)
 */

import { query } from '../config/database.js';

// ─── helpers ────────────────────────────────────────────────────────────────

const DEFAULT_STATISTICS = {
  possession:    { home: 0, away: 0 },
  shots:         { home: 0, away: 0 },
  shotsOnTarget: { home: 0, away: 0 },
  corners:       { home: 0, away: 0 },
  fouls:         { home: 0, away: 0 },
  yellowCards:   { home: 0, away: 0 },
  redCards:      { home: 0, away: 0 },
};

/** Map a raw DB row to a camelCase JS object */
const toMatch = (row) => {
  if (!row) return null;
  return {
    id:         row.id,
    homeTeam: {
      name:  row.home_team_name,
      logo:  row.home_team_logo,
      score: row.home_team_score,
    },
    awayTeam: {
      name:  row.away_team_name,
      logo:  row.away_team_logo,
      score: row.away_team_score,
    },
    date:       row.date,
    venue:      row.venue,
    league:     row.league,
    season:     row.season,
    status:     row.status,
    statistics: row.statistics ?? DEFAULT_STATISTICS,
    events:     row.events ?? [],
    createdBy:  row.created_by_id
      ? { id: row.created_by_id, username: row.created_by_username, email: row.created_by_email }
      : row.created_by,
    createdAt:  row.created_at,
    updatedAt:  row.updated_at,
  };
};

/** Base SELECT with creator join */
const BASE_SELECT = `
  SELECT
    m.*,
    u.id   AS created_by_id,
    u.username AS created_by_username,
    u.email    AS created_by_email
  FROM matches m
  LEFT JOIN users u ON u.id = m.created_by
`;

// ─── CRUD ────────────────────────────────────────────────────────────────────

const create = async (data) => {
  const {
    homeTeam, awayTeam, date, venue, league,
    season = '2025/2026', status = 'scheduled',
    statistics = DEFAULT_STATISTICS,
    events = [],
    createdBy,
  } = data;

  const { rows } = await query(
    `INSERT INTO matches
       (home_team_name, home_team_logo, home_team_score,
        away_team_name, away_team_logo, away_team_score,
        date, venue, league, season, status, statistics, events, created_by)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
     RETURNING *`,
    [
      homeTeam.name, homeTeam.logo ?? '⚽', homeTeam.score ?? 0,
      awayTeam.name, awayTeam.logo ?? '⚽', awayTeam.score ?? 0,
      date, venue, league, season, status,
      JSON.stringify(statistics), JSON.stringify(events),
      createdBy,
    ]
  );
  return toMatch(rows[0]);
};

const findById = async (id) => {
  const { rows } = await query(`${BASE_SELECT} WHERE m.id = $1`, [id]);
  return toMatch(rows[0]);
};

const findAll = async ({ status, league, season, team, skip = 0, limit = 10, sortBy = 'date', order = 'DESC' } = {}) => {
  const conditions = [];
  const params = [];

  if (status) { params.push(status);         conditions.push(`m.status = $${params.length}`); }
  if (league) { params.push(league);         conditions.push(`m.league = $${params.length}`); }
  if (season) { params.push(season);         conditions.push(`m.season = $${params.length}`); }
  if (team) {
    params.push(`%${team}%`);
    const idx = params.length;
    conditions.push(`(m.home_team_name ILIKE $${idx} OR m.away_team_name ILIKE $${idx})`);
  }

  const where   = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const safeCol = ['date', 'league', 'status', 'created_at'].includes(sortBy) ? sortBy : 'date';
  const safeDir = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

  params.push(limit, skip);
  const { rows } = await query(
    `${BASE_SELECT} ${where}
     ORDER BY m.${safeCol} ${safeDir}
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );
  return rows.map(toMatch);
};

const countMatches = async ({ status, league, season, team } = {}) => {
  const conditions = [];
  const params = [];

  if (status) { params.push(status); conditions.push(`status = $${params.length}`); }
  if (league) { params.push(league); conditions.push(`league = $${params.length}`); }
  if (season) { params.push(season); conditions.push(`season = $${params.length}`); }
  if (team) {
    params.push(`%${team}%`);
    const idx = params.length;
    conditions.push(`(home_team_name ILIKE $${idx} OR away_team_name ILIKE $${idx})`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const { rows } = await query(`SELECT COUNT(*) FROM matches ${where}`, params);
  return parseInt(rows[0].count, 10);
};

const findByIdAndUpdate = async (id, updates) => {
  const fields = [];
  const params = [];

  const columnMap = {
    status:        'status',
    venue:         'venue',
    league:        'league',
    season:        'season',
    date:          'date',
    statistics:    'statistics',
    events:        'events',
  };

  // Flat fields
  for (const [key, col] of Object.entries(columnMap)) {
    if (updates[key] !== undefined) {
      const val = (col === 'statistics' || col === 'events') ? JSON.stringify(updates[key]) : updates[key];
      params.push(val);
      fields.push(`${col} = $${params.length}`);
    }
  }

  // Nested homeTeam / awayTeam
  if (updates.homeTeam) {
    const t = updates.homeTeam;
    if (t.name  !== undefined) { params.push(t.name);  fields.push(`home_team_name  = $${params.length}`); }
    if (t.logo  !== undefined) { params.push(t.logo);  fields.push(`home_team_logo  = $${params.length}`); }
    if (t.score !== undefined) { params.push(t.score); fields.push(`home_team_score = $${params.length}`); }
  }
  if (updates.awayTeam) {
    const t = updates.awayTeam;
    if (t.name  !== undefined) { params.push(t.name);  fields.push(`away_team_name  = $${params.length}`); }
    if (t.logo  !== undefined) { params.push(t.logo);  fields.push(`away_team_logo  = $${params.length}`); }
    if (t.score !== undefined) { params.push(t.score); fields.push(`away_team_score = $${params.length}`); }
  }

  if (fields.length === 0) return findById(id);

  params.push(id);
  const { rows } = await query(
    `UPDATE matches SET ${fields.join(', ')}
     WHERE id = $${params.length}
     RETURNING *`,
    params
  );
  return toMatch(rows[0]);
};

const findByIdAndDelete = async (id) => {
  const { rows } = await query(`DELETE FROM matches WHERE id = $1 RETURNING *`, [id]);
  return toMatch(rows[0]);
};

// ─── specialised finders ─────────────────────────────────────────────────────

const findUpcoming = async (limit = 10) => {
  const { rows } = await query(
    `${BASE_SELECT}
     WHERE m.date >= NOW() AND m.status = 'scheduled'
     ORDER BY m.date ASC
     LIMIT $1`,
    [limit]
  );
  return rows.map(toMatch);
};

const findLive = async () => {
  const { rows } = await query(`${BASE_SELECT} WHERE m.status = 'live' ORDER BY m.date DESC`);
  return rows.map(toMatch);
};

const findCompleted = async (limit = 10) => {
  const { rows } = await query(
    `${BASE_SELECT}
     WHERE m.status = 'completed'
     ORDER BY m.date DESC
     LIMIT $1`,
    [limit]
  );
  return rows.map(toMatch);
};

const findByTeam = async (teamName) => {
  const { rows } = await query(
    `${BASE_SELECT}
     WHERE m.home_team_name ILIKE $1 OR m.away_team_name ILIKE $1
     ORDER BY m.date DESC`,
    [`%${teamName}%`]
  );
  return rows.map(toMatch);
};

// ─── event handling ───────────────────────────────────────────────────────────

/**
 * Append an event and update scores/stats in a single atomic transaction.
 */
const addEvent = async (id, event) => {
  const client = await (await import('../config/database.js')).getPool().connect();
  try {
    await client.query('BEGIN');

    // Fetch current match
    const { rows } = await client.query(`SELECT * FROM matches WHERE id = $1 FOR UPDATE`, [id]);
    const match = rows[0];
    if (!match) throw new Error('Match not found');

    const events    = Array.isArray(match.events) ? match.events : JSON.parse(match.events ?? '[]');
    const stats     = match.statistics && typeof match.statistics === 'object' ? match.statistics : JSON.parse(match.statistics ?? '{}');

    // Augment event with timestamp
    const newEvent = { ...event, timestamp: new Date().toISOString() };
    events.push(newEvent);

    // Update scores
    let homeScore = match.home_team_score;
    let awayScore = match.away_team_score;

    if (event.type === 'goal' || event.type === 'own_goal') {
      if (event.team === 'home') homeScore += 1;
      else awayScore += 1;
    }

    // Update card stats
    if (event.type === 'yellow_card') {
      stats.yellowCards = stats.yellowCards ?? { home: 0, away: 0 };
      if (event.team === 'home') stats.yellowCards.home += 1;
      else stats.yellowCards.away += 1;
    }
    if (event.type === 'red_card') {
      stats.redCards = stats.redCards ?? { home: 0, away: 0 };
      if (event.team === 'home') stats.redCards.home += 1;
      else stats.redCards.away += 1;
    }

    await client.query(
      `UPDATE matches
       SET events = $1, statistics = $2, home_team_score = $3, away_team_score = $4
       WHERE id = $5`,
      [JSON.stringify(events), JSON.stringify(stats), homeScore, awayScore, id]
    );

    await client.query('COMMIT');
    return findById(id);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

// ─── statistics ───────────────────────────────────────────────────────────────

const getLeagueStatistics = async (league, season) => {
  const { rows } = await query(
    `SELECT
       COUNT(*)                                      AS total_matches,
       SUM(home_team_score + away_team_score)        AS total_goals
     FROM matches
     WHERE league = $1 AND season = $2 AND status = 'completed'`,
    [league, season]
  );
  const { total_matches, total_goals } = rows[0];
  const totalMatches = parseInt(total_matches, 10);
  const totalGoals   = parseInt(total_goals ?? 0, 10);

  return {
    totalMatches,
    totalGoals,
    averageGoals: totalMatches > 0 ? (totalGoals / totalMatches).toFixed(2) : 0,
  };
};

// ─── exports ─────────────────────────────────────────────────────────────────

const Match = {
  create,
  findById,
  findAll,
  countMatches,
  findByIdAndUpdate,
  findByIdAndDelete,
  findUpcoming,
  findLive,
  findCompleted,
  findByTeam,
  addEvent,
  getLeagueStatistics,
};

export default Match;
