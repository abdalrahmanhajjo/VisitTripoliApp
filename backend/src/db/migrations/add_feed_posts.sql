-- Feed posts from places and business owners
CREATE TABLE IF NOT EXISTS feed_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  author_name VARCHAR(255) NOT NULL,
  place_id VARCHAR(50) REFERENCES places(id) ON DELETE SET NULL,
  caption TEXT,
  image_url VARCHAR(500),
  video_url VARCHAR(500),
  type VARCHAR(20) DEFAULT 'image' CHECK (type IN ('image', 'video', 'news')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_feed_posts_created_at ON feed_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feed_posts_user_id ON feed_posts(user_id);
