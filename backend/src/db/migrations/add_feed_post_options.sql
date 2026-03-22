-- Instagram-like post options
ALTER TABLE feed_posts ADD COLUMN IF NOT EXISTS hide_likes BOOLEAN DEFAULT false;
ALTER TABLE feed_posts ADD COLUMN IF NOT EXISTS comments_disabled BOOLEAN DEFAULT false;
