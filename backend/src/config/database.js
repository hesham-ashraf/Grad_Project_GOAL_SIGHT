/**
 * Database Configuration
 * PostgreSQL connection pool via the `pg` package (Supabase-compatible)
 */

import pg from 'pg';

const { Pool } = pg;

let pool = null;

/**
 * Returns the shared connection pool, creating it on first call.
 * @returns {pg.Pool}
 */
export const getPool = () => {
  if (!pool) {
    pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false }, // required for Supabase
      max: 10,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    });

    pool.on('error', (err) => {
      console.error('❌ Unexpected PostgreSQL pool error:', err);
    });
  }
  return pool;
};

/**
 * Convenience wrapper: run a single query on the pool.
 * @param {string} text   - SQL query string
 * @param {Array}  params - Query parameters
 * @returns {Promise<pg.QueryResult>}
 */
export const query = (text, params) => getPool().query(text, params);

/**
 * Test the connection and log the result.
 */
export const connectDB = async () => {
  try {
    const result = await query('SELECT current_database(), version()');
    const { current_database, version } = result.rows[0];
    console.log(`✅ PostgreSQL Connected`);
    console.log(`📊 Database: ${current_database}`);
    console.log(`🔖 ${version.split(' ').slice(0, 2).join(' ')}\n`);
  } catch (error) {
    console.error('❌ PostgreSQL Connection Error:', error.message);
    process.exit(1);
  }
};

/**
 * Gracefully close all pool connections.
 */
export const disconnectDB = async () => {
  if (pool) {
    await pool.end();
    pool = null;
    console.log('✅ PostgreSQL pool closed');
  }
};

export default { connectDB, disconnectDB, query, getPool };
