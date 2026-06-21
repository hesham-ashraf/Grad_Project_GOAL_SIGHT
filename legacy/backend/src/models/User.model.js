/**
 * User Model
 * PostgreSQL-backed user service (replaces Mongoose model)
 */

import bcrypt from 'bcryptjs';
import { query } from '../config/database.js';

// ─── helpers ────────────────────────────────────────────────────────────────

/** Map a raw DB row to a camelCase JS object */
const toUser = (row) => {
  if (!row) return null;
  return {
    id:           row.id,
    username:     row.username,
    email:        row.email,
    password:     row.password,   // only present when explicitly selected
    role:         row.role,
    favoriteTeam: row.favorite_team,
    isActive:     row.is_active,
    lastLogin:    row.last_login,
    createdAt:    row.created_at,
    updatedAt:    row.updated_at,
  };
};

/** Strip the password field from a user object */
const toSafeObject = (user) => {
  const safe = { ...user };
  delete safe.password;
  return safe;
};

// ─── static queries ──────────────────────────────────────────────────────────

/**
 * Create a new user. Hashes the password before inserting.
 */
const create = async ({ username, email, password, role = 'fan' }) => {
  const salt = await bcrypt.genSalt(10);
  const hashed = await bcrypt.hash(password, salt);

  const { rows } = await query(
    `INSERT INTO users (username, email, password, role)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [username, email.toLowerCase(), hashed, role]
  );
  return toUser(rows[0]);
};

/**
 * Find a user by ID (without password).
 */
const findById = async (id) => {
  const { rows } = await query(
    `SELECT id, username, email, role, favorite_team, is_active, last_login, created_at, updated_at
     FROM users WHERE id = $1`,
    [id]
  );
  return toUser(rows[0]);
};

/**
 * Find a user by ID including the password field.
 */
const findByIdWithPassword = async (id) => {
  const { rows } = await query(`SELECT * FROM users WHERE id = $1`, [id]);
  return toUser(rows[0]);
};

/**
 * Find a user by email (without password).
 */
const findByEmail = async (email) => {
  const { rows } = await query(
    `SELECT id, username, email, role, favorite_team, is_active, last_login, created_at, updated_at
     FROM users WHERE email = $1`,
    [email.toLowerCase()]
  );
  return toUser(rows[0]);
};

/**
 * Find a user by email including the password field.
 */
const findByEmailWithPassword = async (email) => {
  const { rows } = await query(`SELECT * FROM users WHERE email = $1`, [email.toLowerCase()]);
  return toUser(rows[0]);
};

/**
 * Find all active users with a given role.
 */
const findByRole = async (role) => {
  const { rows } = await query(
    `SELECT id, username, email, role, favorite_team, is_active, last_login, created_at, updated_at
     FROM users WHERE role = $1 AND is_active = true`,
    [role]
  );
  return rows.map(toUser);
};

/**
 * Paginated list of users with optional role/isActive filters.
 */
const find = async ({ role, isActive, skip = 0, limit = 10 } = {}) => {
  const conditions = [];
  const params = [];

  if (role !== undefined) {
    params.push(role);
    conditions.push(`role = $${params.length}`);
  }
  if (isActive !== undefined) {
    params.push(isActive);
    conditions.push(`is_active = $${params.length}`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  params.push(limit, skip);

  const { rows } = await query(
    `SELECT id, username, email, role, favorite_team, is_active, last_login, created_at, updated_at
     FROM users ${where}
     ORDER BY created_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );
  return rows.map(toUser);
};

/**
 * Count users matching optional role/isActive filters.
 */
const countUsers = async ({ role, isActive } = {}) => {
  const conditions = [];
  const params = [];

  if (role !== undefined) {
    params.push(role);
    conditions.push(`role = $${params.length}`);
  }
  if (isActive !== undefined) {
    params.push(isActive);
    conditions.push(`is_active = $${params.length}`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const { rows } = await query(`SELECT COUNT(*) FROM users ${where}`, params);
  return parseInt(rows[0].count, 10);
};

/**
 * Update a user by ID. Returns the updated user (without password).
 */
const findByIdAndUpdate = async (id, updates) => {
  const fields = [];
  const params = [];

  const columnMap = {
    username:     'username',
    favoriteTeam: 'favorite_team',
    role:         'role',
    isActive:     'is_active',
    lastLogin:    'last_login',
  };

  for (const [key, col] of Object.entries(columnMap)) {
    if (updates[key] !== undefined) {
      params.push(updates[key]);
      fields.push(`${col} = $${params.length}`);
    }
  }

  if (fields.length === 0) return findById(id);

  params.push(id);
  const { rows } = await query(
    `UPDATE users SET ${fields.join(', ')}
     WHERE id = $${params.length}
     RETURNING id, username, email, role, favorite_team, is_active, last_login, created_at, updated_at`,
    params
  );
  return toUser(rows[0]);
};

/**
 * Update a user's password (hashes first).
 */
const updatePassword = async (id, newPassword) => {
  const salt = await bcrypt.genSalt(10);
  const hashed = await bcrypt.hash(newPassword, salt);
  await query(`UPDATE users SET password = $1 WHERE id = $2`, [hashed, id]);
};

/**
 * Return stats grouped by role plus total/active/inactive counts.
 */
const getStatistics = async () => {
  const { rows: roleRows } = await query(
    `SELECT role, COUNT(*) AS count FROM users GROUP BY role`
  );
  const total  = await countUsers();
  const active = await countUsers({ isActive: true });

  return {
    total,
    active,
    inactive: total - active,
    byRole: roleRows.reduce((acc, r) => {
      acc[r.role] = parseInt(r.count, 10);
      return acc;
    }, {}),
  };
};

// ─── instance-style helpers ───────────────────────────────────────────────────

/**
 * Compare a candidate password against a stored hash.
 */
const comparePassword = async (candidatePassword, hashedPassword) => {
  return bcrypt.compare(candidatePassword, hashedPassword);
};

// ─── exports ─────────────────────────────────────────────────────────────────

const User = {
  create,
  findById,
  findByIdWithPassword,
  findByEmail,
  findByEmailWithPassword,
  findByRole,
  find,
  countUsers,
  findByIdAndUpdate,
  updatePassword,
  getStatistics,
  comparePassword,
  toSafeObject,
};

export default User;
