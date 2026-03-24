-- Discover feed: users with 15+ distinct check-ins can post; posts need admin approval.
ALTER TABLE users ADD COLUMN IF NOT EXISTS feed_discoverable BOOLEAN DEFAULT false;

ALTER TABLE feed_posts ADD COLUMN IF NOT EXISTS moderation_status VARCHAR(20) DEFAULT 'approved';

UPDATE feed_posts SET moderation_status = 'approved' WHERE moderation_status IS NULL;

-- Users who already qualify
UPDATE users u
SET feed_discoverable = true
WHERE COALESCE(u.feed_discoverable, false) IS NOT TRUE
  AND (
    SELECT COUNT(DISTINCT c.place_id)::int
    FROM check_ins c
    WHERE c.user_id = u.id
  ) >= 15;

CREATE INDEX IF NOT EXISTS idx_feed_posts_pending_review
  ON feed_posts (created_at DESC)
  WHERE moderation_status = 'pending' AND author_role = 'discoverer';

INSERT INTO badges (name, icon, description, criteria)
SELECT 'Pathfinder', 'explore', 'Visited 15 places — you can share posts (reviewed by admins)', 'place_15'
WHERE NOT EXISTS (SELECT 1 FROM badges WHERE criteria = 'place_15');
