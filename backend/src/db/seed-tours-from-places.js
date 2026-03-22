/**
 * Seed tours from current places in the database.
 * Creates themed guided tours using places from the places table.
 *
 * Run from backend directory (cd backend first):
 *   npm run db:seed-tours
 *   or: node src/db/seed-tours-from-places.js
 */
const path = require('path');
const backendDir = path.join(__dirname, '../..');
require('dotenv').config({ path: path.join(backendDir, '.env') });
const { pool } = require('./index.js');

function safeParseImages(val) {
  if (Array.isArray(val)) return val;
  if (typeof val !== 'string') return [];
  try {
    const p = JSON.parse(val);
    return Array.isArray(p) ? p : [];
  } catch {
    return [];
  }
}

async function getPlaces(client) {
  const result = await client.query(
    'SELECT id, name, description, images, category_id FROM places ORDER BY name'
  );
  return result.rows.map((r) => ({
    id: r.id,
    name: r.name,
    description: r.description || '',
    images: safeParseImages(r.images),
    categoryId: r.category_id || 'other',
  }));
}

function getFirstImage(place) {
  const imgs = place.images || [];
  if (imgs.length > 0 && imgs[0]) return imgs[0];
  return 'https://images.unsplash.com/photo-1548013146-72479768bada?w=800'; // fallback
}

function buildItinerary(places, startHour = 9) {
  return places.map((p, i) => ({
    time: `${String(startHour + i * 2).padStart(2, '0')}:00`,
    activity: p.name,
    description: (p.description || '').slice(0, 120) + (p.description?.length > 120 ? '...' : ''),
  }));
}

async function seedTours() {
  if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL not set in .env');
    process.exit(1);
  }

  const client = await pool.connect();
  try {
    const places = await getPlaces(client);

    if (places.length === 0) {
      console.error('No places in database. Run full-seed.sql or add places first.');
      process.exit(1);
    }

    console.log(`Found ${places.length} places. Creating tours...`);

    const byCategory = {};
    for (const p of places) {
      const cat = p.categoryId;
      if (!byCategory[cat]) byCategory[cat] = [];
      byCategory[cat].push(p);
    }

    const allPlaces = places;
    const historical = (byCategory.historical || []).concat(byCategory.architecture || []);
    const souks = byCategory.souks || [];
    const food = byCategory.food || [];
    const culture = (byCategory.cultural || []).concat(byCategory.mosques || []);

    const tourDefs = [
      {
        id: 'tour_old_city',
        name: 'Old City Highlights',
        description:
          'Discover Tripoli\'s most iconic historic sites: the Citadel, Clock Tower, and stunning Mamluk mosques. A guided journey through centuries of history.',
        places:
          historical.length >= 5
            ? historical.slice(0, 5)
            : allPlaces.slice(0, 5),
        duration: '4-5 hours',
        durationHours: 5,
        price: 15,
        badge: 'Popular',
        badgeColor: '#0F766E',
        difficulty: 'Easy',
      },
      {
        id: 'tour_souks_markets',
        name: 'Souks & Markets Tour',
        description:
          'Explore the vibrant souks: Khan al-Khayyatin, Soap Khan, Spice Market, and Gold Souk. Experience authentic Tripoli shopping and crafts.',
        places:
          souks.length >= 5
            ? souks.slice(0, 5)
            : allPlaces.slice(0, 5),
        duration: '3-4 hours',
        durationHours: 4,
        price: 0,
        badge: 'Free',
        badgeColor: '#059669',
        difficulty: 'Easy',
      },
      {
        id: 'tour_food_tasting',
        name: 'Tripoli Food Tour',
        description:
          'Taste authentic Lebanese cuisine: Hallab sweets, street food, traditional cafés, and local restaurants. A culinary journey through Tripoli.',
        places:
          food.length >= 5
            ? food.slice(0, 5)
            : allPlaces.slice(5, 10).length >= 5
              ? allPlaces.slice(5, 10)
              : allPlaces.slice(0, 5),
        duration: '3-4 hours',
        durationHours: 4,
        price: 25,
        badge: 'Foodie',
        badgeColor: '#D97706',
        difficulty: 'Easy',
      },
      {
        id: 'tour_culture_architecture',
        name: 'Culture & Architecture',
        description:
          'Museums, madrasas, mosques, and Mamluk mansions. Dive into Tripoli\'s rich cultural heritage and architectural marvels.',
        places:
          culture.length >= 5
            ? culture.slice(0, 5)
            : allPlaces.slice(10, 15).length >= 5
              ? allPlaces.slice(10, 15)
              : allPlaces.slice(0, 5),
        duration: '4-5 hours',
        durationHours: 5,
        price: 10,
        badge: 'Cultural',
        badgeColor: '#4B0082',
        difficulty: 'Moderate',
      },
    ];

    let created = 0;
    for (const t of tourDefs) {
      const tourPlaces = t.places.filter(Boolean);
      if (tourPlaces.length < 2) continue;

      const placeIds = tourPlaces.map((p) => p.id);
      const image = getFirstImage(tourPlaces[0]);
      const itinerary = buildItinerary(tourPlaces);

      await client.query(
        `INSERT INTO tours (
          id, name, duration, duration_hours, locations,
          rating, reviews, price, currency, price_display,
          badge, badge_color, description, image, difficulty,
          languages, includes, excludes, highlights, itinerary, place_ids
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name, duration = EXCLUDED.duration, duration_hours = EXCLUDED.duration_hours,
          locations = EXCLUDED.locations, rating = EXCLUDED.rating, reviews = EXCLUDED.reviews,
          price = EXCLUDED.price, currency = EXCLUDED.currency, price_display = EXCLUDED.price_display,
          badge = EXCLUDED.badge, badge_color = EXCLUDED.badge_color, description = EXCLUDED.description,
          image = EXCLUDED.image, difficulty = EXCLUDED.difficulty, itinerary = EXCLUDED.itinerary,
          place_ids = EXCLUDED.place_ids`,
        [
          t.id,
          t.name,
          t.duration,
          t.durationHours,
          tourPlaces.length,
          4.7,
          128,
          t.price,
          'USD',
          t.price === 0 ? 'Free' : `$${t.price}`,
          t.badge,
          t.badgeColor,
          t.description,
          image,
          t.difficulty,
          JSON.stringify(['English', 'Arabic']),
          JSON.stringify(['Expert local guide', 'Walking tour']),
          JSON.stringify([]),
          JSON.stringify(placeIds.slice(0, 3).map((id) => {
            const p = tourPlaces.find((x) => x.id === id);
            return p ? `Visit ${p.name}` : '';
          }).filter(Boolean)),
          JSON.stringify(itinerary),
          JSON.stringify(placeIds),
        ]
      );
      created++;
      console.log(`  Created: ${t.name} (${tourPlaces.length} stops)`);
    }

    console.log(`\nDone. Created ${created} tours from ${places.length} places.`);
  } catch (err) {
    console.error('Seed failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

seedTours();
