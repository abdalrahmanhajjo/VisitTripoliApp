const { Pool } = require('pg');

let connectionString = process.env.DATABASE_URL || '';
const isSupabase = connectionString.includes('supabase');
const isProd = process.env.NODE_ENV === 'production';
// Allow self-signed DB cert in dev (Supabase pooler). Set DB_ACCEPT_SELF_SIGNED=1 in .env if you still see cert errors.
const acceptSelfSigned = !isProd || process.env.DB_ACCEPT_SELF_SIGNED === '1';

// Normalize SSL in connection string so Pool.ssl controls TLS.
if (connectionString) {
  try {
    const url = new URL(connectionString);
    if (isProd && !acceptSelfSigned) {
      url.searchParams.set('sslmode', 'verify-full');
    } else {
      url.searchParams.delete('sslmode');
    }
    connectionString = url.toString();
  } catch (_) { /* keep original */ }
}

const pool = new Pool({
  connectionString: connectionString || undefined,
  max: process.env.DB_POOL_SIZE ? parseInt(process.env.DB_POOL_SIZE, 10) : 20,
  min: 2,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 20000,
  statement_timeout: 15000,
  allowExitOnIdle: true,
  // SSL: in prod verify certs unless DB_ACCEPT_SELF_SIGNED=1; in dev allow self-signed chain.
  ssl: isSupabase
    ? { rejectUnauthorized: !acceptSelfSigned }
    : isProd
      ? { rejectUnauthorized: true }
      : false,
});

pool.on('error', (err) => {
  console.error('Unexpected DB pool error:', err.message);
});

module.exports = { pool, query: (text, params) => pool.query(text, params) };
