/**
 * Fix places.images column type - ensure it is JSONB.
 * Run if you get type errors when saving place images.
 * Usage: node src/db/fix-places-images-type.js
 */
require('dotenv').config();
const { pool } = require('./index.js');

async function fix() {
  if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL not set in .env');
    process.exit(1);
  }
  const client = await pool.connect();
  try {
    const r = await client.query(`
      SELECT data_type FROM information_schema.columns
      WHERE table_name = 'places' AND column_name = 'images'
    `);
    if (r.rows.length === 0) {
      console.log('places.images column not found - run schema migration first.');
      return;
    }
    const currentType = r.rows[0].data_type;
    if (currentType === 'jsonb') {
      console.log('places.images is already JSONB - no change needed.');
      return;
    }
    console.log(`Current type: ${currentType}. Converting to JSONB...`);
    await client.query(`
      ALTER TABLE places
      ALTER COLUMN images TYPE jsonb
      USING COALESCE(images::text::jsonb, '[]'::jsonb)
    `);
    console.log('Done: places.images is now JSONB.');
  } catch (err) {
    console.error('Migration failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

fix();
