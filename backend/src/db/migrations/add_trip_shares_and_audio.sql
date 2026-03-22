-- Trip sharing
CREATE TABLE IF NOT EXISTS trip_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id VARCHAR(50) NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  share_token VARCHAR(64) NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ,
  can_edit BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_trip_shares_token ON trip_shares(share_token);

-- Audio guides for places & tours
CREATE TABLE IF NOT EXISTS audio_guides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id VARCHAR(50) REFERENCES places(id) ON DELETE CASCADE,
  tour_id VARCHAR(50) REFERENCES tours(id) ON DELETE CASCADE,
  language VARCHAR(10) NOT NULL DEFAULT 'en',
  audio_url VARCHAR(500) NOT NULL,
  duration_seconds INT,
  title VARCHAR(200),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audio_guides_place ON audio_guides(place_id);
CREATE INDEX IF NOT EXISTS idx_audio_guides_tour ON audio_guides(tour_id);
