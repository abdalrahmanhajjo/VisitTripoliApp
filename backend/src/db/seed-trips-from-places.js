/**
 * Seed trips from current places in the database.
 * Creates sample trips for the first user (or a new demo user if none exist).
 * Run: node src/db/seed-trips-from-places.js
 * or:  npm run db:seed-trips
 */
require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const { pool } = require('./index.js');
const bcrypt = require('bcryptjs');

async function getOrCreateUser(client) {
  const usersResult = await client.query('SELECT id FROM users ORDER BY created_at ASC LIMIT 1');
  if (usersResult.rows.length > 0) {
    return usersResult.rows[0].id;
  }
  // Create demo user
  const hash = await bcrypt.hash('demo123', 12);
  const insert = await client.query(
    `INSERT INTO users (email, password_hash, name, auth_provider, email_verified)
     VALUES ($1, $2, $3, 'email', true)
     RETURNING id`,
    ['demo@tripoli.com', hash, 'Demo User']
  );
  console.log('Created demo user: demo@tripoli.com / demo123');
  return insert.rows[0].id;
}

async function getPlaceIds(client) {
  const result = await client.query('SELECT id, category_id FROM places ORDER BY name');
  return result.rows;
}

function buildTripDays(placeIds, placesPerDay = 3) {
  const days = [];
  const startDate = new Date();
  startDate.setDate(startDate.getDate() + 7);
  for (let d = 0; d < 3; d++) {
    const date = new Date(startDate);
    date.setDate(date.getDate() + d);
    const dateStr = date.toISOString().slice(0, 10);
    const start = d * placesPerDay;
    const chunk = placeIds.slice(start, start + placesPerDay);
    const slots = chunk.map((p, i) => ({
      placeId: typeof p === 'string' ? p : p.id,
      startTime: `${9 + i * 2}:00`,
      endTime: `${11 + i * 2}:00`,
    }));
    if (slots.length > 0) {
      days.push({ date: dateStr, slots });
    }
  }
  return days;
}

async function seedTrips() {
  if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL not set in .env');
    process.exit(1);
  }

  const client = await pool.connect();
  try {
    const userId = await getOrCreateUser(client);
    const places = await getPlaceIds(client);

    if (places.length === 0) {
      console.error('No places in database. Run full-seed.sql or add places first.');
      process.exit(1);
    }

    console.log(`Found ${places.length} places. Creating trips for user ${userId}`);

    // Group places by category for themed trips
    const byCategory = {};
    for (const p of places) {
      const cat = p.category_id || 'other';
      if (!byCategory[cat]) byCategory[cat] = [];
      byCategory[cat].push(p);
    }

    const allIds = places.map((p) => p.id);
    const historicalIds = (byCategory.historical || []).concat(byCategory.architecture || []).map((p) => p.id);
    const souksIds = (byCategory.souks || []).map((p) => p.id);
    const foodIds = (byCategory.food || []).map((p) => p.id);
    const cultureIds = (byCategory.cultural || []).concat(byCategory.mosques || []).map((p) => p.id);

    const trips = [
      {
        name: 'Old City Highlights',
        startDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
        endDate: new Date(Date.now() + 9 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
        description: 'Must-see historic sites, citadel, mosques, and the Clock Tower.',
        places: historicalIds.length >= 6 ? historicalIds.slice(0, 6) : allIds.slice(0, 6),
      },
      {
        name: 'Souks & Food Tour',
        startDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
        endDate: new Date(Date.now() + 16 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
        description: 'Markets, souks, and authentic Lebanese dining.',
        places: [...souksIds, ...foodIds].slice(0, 8).filter((id, i, arr) => arr.indexOf(id) === i),
      },
      {
        name: 'Culture & Architecture',
        startDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
        endDate: new Date(Date.now() + 23 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
        description: 'Museums, madrasas, mosques, and Mamluk architecture.',
        places: cultureIds.length >= 6 ? cultureIds.slice(0, 6) : allIds.slice(6, 12),
      },
    ];

    // Fallback: use first N places if category groups are too small
    for (const t of trips) {
      if (t.places.length < 3) {
        t.places = allIds.slice(0, 8);
      }
    }

    let created = 0;
    for (const t of trips) {
      const days = buildTripDays(t.places, 3);

      if (days.length === 0) continue;

      const id = `trip_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
      await client.query(
        `INSERT INTO trips (id, user_id, name, start_date, end_date, description, days)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [id, userId, t.name, t.startDate, t.endDate, t.description, JSON.stringify(days)]
      );
      created++;
      console.log(`  Created: ${t.name} (${t.places.length} places)`);
    }

    console.log(`\nDone. Created ${created} trips from ${places.length} places.`);
  } catch (err) {
    console.error('Seed failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

seedTrips();
