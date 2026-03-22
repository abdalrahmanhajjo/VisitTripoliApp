/**
 * Run a single migration file (no psql required).
 * Usage: node src/db/run-migration.js add_password_reset_tokens
 * or:    npm run db:migrate:reset-tokens
 */
require('dotenv').config();
const { pool } = require('./index.js');
const fs = require('fs');
const path = require('path');

const name = process.argv[2] || 'add_password_reset_tokens';
const sqlPath = path.join(__dirname, 'migrations', `${name}.sql`);

if (!fs.existsSync(sqlPath)) {
  console.error(`Migration not found: ${sqlPath}`);
  process.exit(1);
}

async function run() {
  if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL not set in .env');
    process.exit(1);
  }
  const client = await pool.connect();
  try {
    const sql = fs.readFileSync(sqlPath, 'utf8');
    await client.query(sql);
    console.log(`Migration complete: ${name}`);
  } catch (err) {
    console.error('Migration failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

run();
