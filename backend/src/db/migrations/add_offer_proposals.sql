-- User proposals: send offer request TO a restaurant
CREATE TABLE IF NOT EXISTS offer_proposals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  place_id VARCHAR(50) NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  suggested_discount_type VARCHAR(20) CHECK (suggested_discount_type IN ('percent', 'fixed', 'bogo', 'free_item')),
  suggested_discount_value DECIMAL(10,2),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_offer_proposals_place ON offer_proposals(place_id);
CREATE INDEX IF NOT EXISTS idx_offer_proposals_user ON offer_proposals(user_id);
