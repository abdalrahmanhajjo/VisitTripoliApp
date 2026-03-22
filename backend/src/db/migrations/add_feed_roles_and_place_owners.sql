-- Feed: only admins and business owners can post. Users see only their posts.
-- Author role: 'admin' | 'business_owner' | 'regular'
-- GET feed returns only posts from admin or business_owner.

-- Add is_admin to users (for app admins who can post to feed)
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;

-- place_owners: links users to places they own (business owners)
CREATE TABLE IF NOT EXISTS place_owners (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  place_id VARCHAR(50) NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, place_id)
);
CREATE INDEX IF NOT EXISTS idx_place_owners_user_id ON place_owners(user_id);
CREATE INDEX IF NOT EXISTS idx_place_owners_place_id ON place_owners(place_id);

-- Add author_role to feed_posts
ALTER TABLE feed_posts ADD COLUMN IF NOT EXISTS author_role VARCHAR(20) DEFAULT 'regular';

-- Backfill: posts with place_id are business_owner
UPDATE feed_posts SET author_role = 'business_owner' WHERE place_id IS NOT NULL AND (author_role IS NULL OR author_role = 'regular');
