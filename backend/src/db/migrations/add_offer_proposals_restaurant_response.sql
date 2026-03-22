-- Restaurant can respond to user proposals
ALTER TABLE offer_proposals ADD COLUMN IF NOT EXISTS restaurant_response TEXT;
ALTER TABLE offer_proposals ADD COLUMN IF NOT EXISTS restaurant_responded_at TIMESTAMPTZ;
