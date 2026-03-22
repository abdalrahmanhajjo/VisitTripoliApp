/**
 * Seed sample coupons and offers for testing.
 * Run: node src/scripts/seed-coupons-offers.js
 * Requires: DATABASE_URL in .env, places and tours to exist.
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const { pool } = require('../src/db/index.js');

async function seed() {
  const client = await pool.connect();
  try {
    const places = (await client.query("SELECT id, name FROM places WHERE category_id = 'food' LIMIT 5")).rows;
    const tours = (await client.query('SELECT id, name FROM tours LIMIT 2')).rows;

    if (places.length === 0) {
      console.log('No restaurant places found. Run full-seed.sql or add food/restaurant places first.');
      return;
    }

    const placeId = places[0].id;
    const tourId = tours[0]?.id;

    for (const row of [
      ['WELCOME10', 'percent', 10, 0, placeId],
      ['TRIPOLI20', 'percent', 20, 50, placeId],
      ['SAVE5', 'fixed', 5, 20, null],
    ]) {
      await client.query(
        `INSERT INTO coupons (code, discount_type, discount_value, min_purchase, valid_until, place_id)
         VALUES ($1, $2, $3, $4, NOW() + INTERVAL '30 days', $5)
         ON CONFLICT (code) DO NOTHING`,
        [row[0], row[1], row[2], row[3], row[4]]
      );
    }
    console.log('Coupons seeded.');

    // Remove offers from non-restaurant places (keeps only food/restaurant offers)
    await client.query(`DELETE FROM place_offers WHERE place_id IN (SELECT id FROM places WHERE category_id IS NULL OR category_id != 'food')`);
    const existing = (await client.query('SELECT 1 FROM place_offers WHERE place_id = $1 LIMIT 1', [placeId])).rows[0];
    if (!existing) {
      await client.query(`
        INSERT INTO place_offers (place_id, title, description, discount_type, discount_value, expires_at)
        VALUES 
          ($1, 'Lunch Special', '20% off lunch menu Mon-Fri', 'percent', 20, NOW() + INTERVAL '14 days'),
          ($1, 'Happy Hour', 'Buy one get one free on drinks 4-6pm', 'bogo', NULL, NOW() + INTERVAL '7 days')
      `, [placeId]);
    }
    console.log('Offers seeded.');

    console.log('Done.');
  } catch (err) {
    console.error(err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

seed();
