-- Business owners are a distinct user type (not regular users).
-- Only business owners can access /api/business/* and post to the feed.

ALTER TABLE users ADD COLUMN IF NOT EXISTS is_business_owner BOOLEAN DEFAULT false;

-- Backfill: users with at least one place in place_owners are business owners
UPDATE users u
SET is_business_owner = true
WHERE EXISTS (SELECT 1 FROM place_owners po WHERE po.user_id = u.id);
