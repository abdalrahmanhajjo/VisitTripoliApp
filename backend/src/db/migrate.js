/**
 * Run schema + all migrations in order (creates/updates all tables).
 * Usage: node src/db/migrate.js
 */
require('dotenv').config();
const { pool } = require('./index.js');
const fs = require('fs');
const path = require('path');

const MIGRATIONS_ORDER = [
  'add_password_reset_tokens',
  'add_email_phone_verification',
  'add_onboarding_completed',
  'add_feed_roles_and_place_owners',
  'add_is_business_owner',
  'add_oauth_auth_provider',
  'add_feed_posts',
  'add_feed_likes_comments',
  'add_feed_saves',
  'add_feed_posts_index',
  'add_feed_reports',
  'add_feed_post_options',
  'add_user_avatar',
  'add_translations_tables',
  'add_coupons_and_offers',
  'add_offer_proposals',
  'add_offer_proposals_phone',
  'add_offer_proposals_restaurant_response',
  'add_bookings_and_badges',
  'add_trip_shares_and_audio',
];

async function migrate() {
  if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL not set in .env');
    process.exit(1);
  }
  const client = await pool.connect();
  try {
    const schemaPath = path.join(__dirname, 'schema.sql');
    await client.query(fs.readFileSync(schemaPath, 'utf8'));
    console.log('Schema applied.');
    for (const name of MIGRATIONS_ORDER) {
      const sqlPath = path.join(__dirname, 'migrations', `${name}.sql`);
      if (fs.existsSync(sqlPath)) {
        await client.query(fs.readFileSync(sqlPath, 'utf8'));
        console.log('Migration applied:', name);
      }
    }
    console.log('Migration complete.');
  } catch (err) {
    console.error('Migration failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

migrate();
