process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function runMigration() {
  try {
    console.log('Running comment migration...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS "feed_comment_likes" (
        "comment_id" UUID NOT NULL,
        "user_id" UUID NOT NULL,
        "created_at" TIMESTAMPTZ DEFAULT now(),
        PRIMARY KEY ("comment_id", "user_id")
      );
    `);
    
    // Add columns dynamically safely inside a block
    await pool.query(`
      DO $$ 
      BEGIN 
        BEGIN
          ALTER TABLE feed_comments ADD COLUMN updated_at TIMESTAMPTZ;
        EXCEPTION
          WHEN duplicate_column THEN RAISE NOTICE 'column updated_at already exists in feed_comments.';
        END;
        BEGIN
          ALTER TABLE feed_comments ADD COLUMN parent_comment_id UUID;
        EXCEPTION
          WHEN duplicate_column THEN RAISE NOTICE 'column parent_comment_id already exists in feed_comments.';
        END;
      END $$;
    `);

    console.log('Migration completed successfully.');
  } catch (err) {
    console.error('Migration failed:', err);
  } finally {
    await pool.end();
  }
}

runMigration();
