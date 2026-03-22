/**
 * Seed the database with sample data for development.
 * Run: node src/db/seed.js (after setting DATABASE_URL and running schema)
 */
require('dotenv').config();
const { pool } = require('./index.js');

async function seed() {
  const client = await pool.connect();
  try {
    // Categories
    await client.query(`
      INSERT INTO categories (id, name, icon, description, tags, count, color) VALUES
      ('historic', 'Historic Sites', 'landmark', 'Historic landmarks and monuments', '["history","heritage"]', 0, '#8B4513'),
      ('food', 'Food & Dining', 'utensils', 'Restaurants and cafes', '["food","dining"]', 0, '#CD853F'),
      ('markets', 'Markets & Souks', 'shopping-bag', 'Traditional markets', '["shopping","souks"]', 0, '#D2691E')
      ON CONFLICT (id) DO NOTHING
    `);

    // Sample places
    await client.query(`
      INSERT INTO places (id, name, description, location, latitude, longitude, images, category, category_id, duration, price, best_time, rating, review_count, tags) VALUES
      ('place_1', 'Citadel of Tripoli', 'Historic fortress overlooking the city', 'Tripoli', 34.43692, 35.83846, '[]', 'Historic Sites', 'historic', '2-3 hours', 'Free', 'Morning', 4.8, 120, '["castle","view"]'),
      ('place_2', 'Khan al-Saboun', 'Traditional soap market', 'Old City', 34.435, 35.839, '[]', 'Markets & Souks', 'markets', '1 hour', 'varies', 'Any', 4.5, 85, '["soap","souvenirs"]')
      ON CONFLICT (id) DO NOTHING
    `);

    // Sample interests
    await client.query(`
      INSERT INTO interests (id, name, icon, description, color, count, popularity, tags) VALUES
      ('culture', 'Culture & Heritage', 'landmark', 'Historic sites and traditions', '#8B4513', 0, 10, '[]'),
      ('food', 'Food & Dining', 'utensils', 'Local cuisine', '#CD853F', 0, 9, '[]'),
      ('shopping', 'Shopping', 'shopping-bag', 'Markets and souks', '#D2691E', 0, 8, '[]')
      ON CONFLICT (id) DO NOTHING
    `);

    console.log('Seed completed successfully.');
  } catch (err) {
    console.error('Seed failed:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

seed();
