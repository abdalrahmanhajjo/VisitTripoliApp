-- Coupons & promo codes
CREATE TABLE IF NOT EXISTS coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(32) NOT NULL UNIQUE,
  discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percent', 'fixed')),
  discount_value DECIMAL(10,2) NOT NULL,
  min_purchase DECIMAL(10,2) DEFAULT 0,
  valid_from TIMESTAMPTZ DEFAULT NOW(),
  valid_until TIMESTAMPTZ NOT NULL,
  usage_limit INT DEFAULT NULL,
  place_id VARCHAR(50) REFERENCES places(id) ON DELETE SET NULL,
  tour_id VARCHAR(50) REFERENCES tours(id) ON DELETE SET NULL,
  event_id VARCHAR(50) REFERENCES events(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_coupons_code ON coupons(code);
CREATE INDEX IF NOT EXISTS idx_coupons_valid ON coupons(valid_until);

CREATE TABLE IF NOT EXISTS coupon_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  coupon_id UUID NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
  redeemed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, coupon_id)
);
CREATE INDEX IF NOT EXISTS idx_coupon_redemptions_user ON coupon_redemptions(user_id);

-- Restaurant & place offers
CREATE TABLE IF NOT EXISTS place_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id VARCHAR(50) NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percent', 'fixed', 'bogo', 'free_item')),
  discount_value DECIMAL(10,2),
  valid_days INT[],
  start_time TIME,
  end_time TIME,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_place_offers_place ON place_offers(place_id);
CREATE INDEX IF NOT EXISTS idx_place_offers_expires ON place_offers(expires_at);
