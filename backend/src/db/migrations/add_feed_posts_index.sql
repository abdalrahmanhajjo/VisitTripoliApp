-- Index for fast feed list query (visible posts: admin/business_owner or place-linked)
CREATE INDEX IF NOT EXISTS idx_feed_posts_visible_created
  ON feed_posts(created_at DESC)
  WHERE (author_role IN ('admin', 'business_owner') OR (author_role IS NULL AND place_id IS NOT NULL));
