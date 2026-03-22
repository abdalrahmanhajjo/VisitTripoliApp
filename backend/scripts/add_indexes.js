const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const { query, pool } = require('../src/db');

async function main() {
  console.log('Adding performance indexes to the database...');
  try {
    const indexes = [
      // Feed optimization (Newest to oldest)
      'CREATE INDEX IF NOT EXISTS idx_feed_posts_created_at_id ON feed_posts (created_at DESC, id DESC)',
      'CREATE INDEX IF NOT EXISTS idx_feed_posts_place_id ON feed_posts (place_id)',
      'CREATE INDEX IF NOT EXISTS idx_feed_likes_post_id ON feed_likes (post_id)',
      'CREATE INDEX IF NOT EXISTS idx_feed_comments_post_id ON feed_comments (post_id)',
      'CREATE INDEX IF NOT EXISTS idx_feed_saves_user_id ON feed_saves (user_id)',

      // Places and Searches optimization
      'CREATE INDEX IF NOT EXISTS idx_places_rating ON places (rating DESC NULLS LAST)',
      'CREATE INDEX IF NOT EXISTS idx_places_category ON places (category)',

      // Tours and Events
      'CREATE INDEX IF NOT EXISTS idx_tours_rating ON tours (rating DESC NULLS LAST)',
      'CREATE INDEX IF NOT EXISTS idx_events_start_date ON events (start_date DESC)',

      // Reviews
      'CREATE INDEX IF NOT EXISTS idx_place_reviews_place_id ON place_reviews (place_id)'
    ];

    for (const sql of indexes) {
      console.log(`Executing: ${sql}`);
      await query(sql);
    }

    console.log('Indexes added successfully!');
  } catch (err) {
    console.error('Failed to add indexes:', err);
  } finally {
    pool.end();
  }
}

main();
