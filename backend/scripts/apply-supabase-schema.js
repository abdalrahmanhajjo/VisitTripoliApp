/**
 * Apply backend/supabase_schema.sql to the database (DATABASE_URL in .env).
 * Use this to sync your DB with the dumped Supabase schema.
 *
 * Run: cd backend && node scripts/apply-supabase-schema.js
 * Or:  npm run db:apply-supabase-schema
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const { pool } = require('../src/db');
const fs = require('fs');
const path = require('path');

const SCHEMA_FILE = path.join(__dirname, '../supabase_schema.sql');

async function main() {
  if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL not set. Add it to backend/.env');
    process.exit(1);
  }
  if (!fs.existsSync(SCHEMA_FILE)) {
    console.error('Not found:', SCHEMA_FILE);
    console.error('Run npm run db:dump-schema first to generate it from your DB.');
    process.exit(1);
  }
  const sql = fs.readFileSync(SCHEMA_FILE, 'utf8');
  const client = await pool.connect();
  try {
    await client.query(sql);
    console.log('Supabase schema applied successfully.');
  } catch (err) {
    console.error('Apply failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

main();
