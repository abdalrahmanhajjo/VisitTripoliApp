-- Feed saves (bookmarks): one row per user per post
CREATE TABLE IF NOT EXISTS feed_saves (
  post_id UUID NOT NULL REFERENCES feed_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (post_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_feed_saves_post_id ON feed_saves(post_id);
CREATE INDEX IF NOT EXISTS idx_feed_saves_user_id ON feed_saves(user_id);
