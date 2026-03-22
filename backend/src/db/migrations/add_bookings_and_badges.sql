-- Place bookings & reservations
CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  place_id VARCHAR(50) REFERENCES places(id) ON DELETE SET NULL,
  tour_id VARCHAR(50) REFERENCES tours(id) ON DELETE SET NULL,
  booking_type VARCHAR(20) NOT NULL CHECK (booking_type IN ('place', 'tour')),
  booking_date DATE NOT NULL,
  time_slot VARCHAR(50),
  party_size INT DEFAULT 1,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_date ON bookings(booking_date);

-- Gamification: badges & check-ins
CREATE TABLE IF NOT EXISTS badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  icon VARCHAR(50),
  description TEXT,
  criteria VARCHAR(100)
);
INSERT INTO badges (name, icon, description, criteria) VALUES
  ('First Visit', 'place', 'Visited your first place', 'place_1'),
  ('Explorer', 'explore', 'Visited 5 places', 'place_5'),
  ('Adventurer', 'hiking', 'Visited 10 places', 'place_10'),
  ('Foodie', 'restaurant', 'Checked in at 3 restaurants', 'restaurant_3'),
  ('Culture Buff', 'museum', 'Visited 3 cultural sites', 'culture_3'),
  ('Trip Planner', 'route', 'Created your first trip', 'trip_1'),
  ('Social Butterfly', 'people', 'Shared a trip', 'share_1')
ON CONFLICT (name) DO NOTHING;

CREATE TABLE IF NOT EXISTS user_badges (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, badge_id)
);

CREATE TABLE IF NOT EXISTS check_ins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  place_id VARCHAR(50) NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  checked_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_check_ins_user ON check_ins(user_id);
CREATE INDEX IF NOT EXISTS idx_check_ins_place ON check_ins(place_id);
