/**
 * Seed sample reviews for all places (and demo user if needed).
 * Works with both place_reviews and Supabase "reviews" table.
 *
 * Run: npm run db:seed-reviews  (from backend directory)
 */
require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const { pool } = require('./index.js');
const bcrypt = require('bcryptjs');

async function getOrCreateDemoUser(client) {
  const r = await client.query('SELECT id FROM users ORDER BY created_at ASC LIMIT 1');
  if (r.rows.length > 0) return r.rows[0].id;
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
  const r = await client.query('SELECT id FROM places ORDER BY name');
  return r.rows.map((row) => row.id);
}

const SAMPLE_REVIEWS = [
  { rating: 5, title: 'Amazing experience', review: 'A must-visit in Tripoli. Beautiful and well preserved.' },
  { rating: 4, title: 'Worth the visit', review: 'Great for history lovers. Allow a few hours to explore.' },
  { rating: 5, title: 'Best place to eat sweets in Tripoli.', review: null },
  { rating: 4, title: 'Lovely spot', review: 'Friendly staff and good atmosphere.' },
  { rating: 5, title: 'Highly recommend', review: 'One of the highlights of our trip.' },
];

async function seedReviews() {
  if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL not set in .env');
    process.exit(1);
  }
  const client = await pool.connect();
  try {
    const userId = await getOrCreateDemoUser(client);
    const placeIds = await getPlaceIds(client);
    if (placeIds.length === 0) {
      console.log('No places found. Run db:seed first.');
      return;
    }

    let useReviewsTable = false;
    try {
      await client.query(
        `INSERT INTO place_reviews (place_id, user_id, rating, title, review, visit_date)
         VALUES ($1, $2, $3, $4, $5, CURRENT_DATE - (random() * 90)::int)`,
        [placeIds[0], userId, SAMPLE_REVIEWS[0].rating, SAMPLE_REVIEWS[0].title || null, SAMPLE_REVIEWS[0].review || null]
      );
      for (let i = 1; i < placeIds.length; i++) {
        const sample = SAMPLE_REVIEWS[i % SAMPLE_REVIEWS.length];
        await client.query(
          `INSERT INTO place_reviews (place_id, user_id, rating, title, review, visit_date)
           VALUES ($1, $2, $3, $4, $5, CURRENT_DATE - (random() * 90)::int)`,
          [placeIds[i], userId, sample.rating, sample.title || null, sample.review || null]
        );
      }
      console.log('Seeded reviews into "place_reviews" table.');
    } catch (e) {
      const msg = (e && e.message) || '';
      if (/relation ["']?place_reviews["']? does not exist/i.test(msg)) {
        useReviewsTable = true;
      } else {
        throw e;
      }
    }

    if (useReviewsTable) {
      for (let i = 0; i < placeIds.length; i++) {
        const sample = SAMPLE_REVIEWS[i % SAMPLE_REVIEWS.length];
        await client.query(
          `INSERT INTO reviews (place_id, user_id, rating, title, review)
           VALUES ($1, $2, $3, $4, $5)`,
          [placeIds[i], userId, sample.rating, sample.title || null, sample.review || null]
        );
      }
      console.log('Seeded reviews into "reviews" table.');
    }

    for (const placeId of placeIds) {
      const aggQuery = useReviewsTable
        ? 'SELECT AVG(rating)::float AS rating, COUNT(*)::int AS count FROM reviews WHERE place_id = $1'
        : 'SELECT AVG(rating)::float AS rating, COUNT(*)::int AS count FROM place_reviews WHERE place_id = $1';
      const agg = await client.query(aggQuery, [placeId]);
      const row = agg.rows[0];
      if (row) {
        await client.query(
          'UPDATE places SET rating = $1, review_count = $2 WHERE id = $3',
          [row.rating, row.count, placeId]
        );
      }
    }
    console.log('Reviews seed completed. Updated place rating/review_count.');
  } catch (err) {
    console.error('Seed failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

seedReviews();
