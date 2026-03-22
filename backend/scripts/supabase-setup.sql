-- Optional: run in Supabase Dashboard → SQL Editor for a one-shot schema + seed.
-- For full schema and migrations, use: npm run db:migrate (see README).

-- Users
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User profiles (extends users)
CREATE TABLE IF NOT EXISTS profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  username VARCHAR(100),
  city VARCHAR(255),
  bio TEXT,
  mood VARCHAR(50) DEFAULT 'mixed',
  pace VARCHAR(50) DEFAULT 'normal',
  analytics BOOLEAN DEFAULT true,
  show_tips BOOLEAN DEFAULT true,
  app_rating INT DEFAULT 0 CHECK (app_rating >= 0 AND app_rating <= 5),
  onboarding_completed BOOLEAN DEFAULT FALSE,
  onboarding_completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Categories (for places)
CREATE TABLE IF NOT EXISTS categories (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  icon VARCHAR(50) NOT NULL,
  description TEXT,
  tags JSONB DEFAULT '[]',
  count INT DEFAULT 0,
  color VARCHAR(20)
);

-- Places
CREATE TABLE IF NOT EXISTS places (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  location VARCHAR(255),
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  search_name VARCHAR(255),
  images JSONB DEFAULT '[]',
  category VARCHAR(100),
  category_id VARCHAR(50),
  duration VARCHAR(50),
  price VARCHAR(50),
  best_time VARCHAR(100),
  rating DOUBLE PRECISION,
  review_count INT,
  hours JSONB,
  tags JSONB
);

-- Tours
CREATE TABLE IF NOT EXISTS tours (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  duration VARCHAR(50) NOT NULL,
  duration_hours INT NOT NULL,
  locations INT NOT NULL,
  rating DOUBLE PRECISION NOT NULL,
  reviews INT NOT NULL,
  price DOUBLE PRECISION NOT NULL,
  currency VARCHAR(10) NOT NULL,
  price_display VARCHAR(50) NOT NULL,
  badge VARCHAR(50),
  badge_color VARCHAR(20),
  description TEXT NOT NULL,
  image VARCHAR(500) NOT NULL,
  difficulty VARCHAR(50) NOT NULL,
  languages JSONB DEFAULT '[]',
  includes JSONB DEFAULT '[]',
  excludes JSONB DEFAULT '[]',
  highlights JSONB DEFAULT '[]',
  itinerary JSONB DEFAULT '[]',
  place_ids JSONB DEFAULT '[]'
);

-- Events
CREATE TABLE IF NOT EXISTS events (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  location VARCHAR(255) NOT NULL,
  image VARCHAR(500),
  category VARCHAR(100) NOT NULL,
  organizer VARCHAR(255),
  price DOUBLE PRECISION,
  price_display VARCHAR(50),
  status VARCHAR(50),
  place_id VARCHAR(50)
);

-- Interests (for onboarding)
CREATE TABLE IF NOT EXISTS interests (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  icon VARCHAR(50) NOT NULL,
  description TEXT,
  color VARCHAR(20) NOT NULL,
  count INT DEFAULT 0,
  popularity INT DEFAULT 0,
  tags JSONB DEFAULT '[]'
);

-- User trips
CREATE TABLE IF NOT EXISTS trips (
  id VARCHAR(50) PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  description TEXT,
  days JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Saved places / tours / events
CREATE TABLE IF NOT EXISTS saved_places (user_id UUID REFERENCES users(id) ON DELETE CASCADE, place_id VARCHAR(50) REFERENCES places(id) ON DELETE CASCADE, PRIMARY KEY (user_id, place_id));
CREATE TABLE IF NOT EXISTS saved_tours (user_id UUID REFERENCES users(id) ON DELETE CASCADE, tour_id VARCHAR(50) REFERENCES tours(id) ON DELETE CASCADE, PRIMARY KEY (user_id, tour_id));
CREATE TABLE IF NOT EXISTS saved_events (user_id UUID REFERENCES users(id) ON DELETE CASCADE, event_id VARCHAR(50) REFERENCES events(id) ON DELETE CASCADE, PRIMARY KEY (user_id, event_id));

-- Indexes
CREATE INDEX IF NOT EXISTS idx_places_category ON places(category_id);
CREATE INDEX IF NOT EXISTS idx_places_category_name ON places(category);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);
CREATE INDEX IF NOT EXISTS idx_trips_user_id ON trips(user_id);

-- Seed: Categories, Places, Interests
INSERT INTO categories (id, name, icon, description, tags, count, color) VALUES
  ('historic', 'Historic Sites', 'landmark', 'Historic landmarks and monuments', '["history","heritage"]', 0, '#8B4513'),
  ('food', 'Food & Dining', 'utensils', 'Restaurants and cafes', '["food","dining"]', 0, '#CD853F'),
  ('markets', 'Markets & Souks', 'shopping-bag', 'Traditional markets', '["shopping","souks"]', 0, '#D2691E')
ON CONFLICT (id) DO NOTHING;
INSERT INTO places (id, name, description, location, latitude, longitude, images, category, category_id, duration, price, best_time, rating, review_count, tags) VALUES
  ('place_1', 'Citadel of Tripoli', 'Historic fortress overlooking the city', 'Tripoli', 34.43692, 35.83846, '[]', 'Historic Sites', 'historic', '2-3 hours', 'Free', 'Morning', 4.8, 120, '["castle","view"]'),
  ('place_2', 'Khan al-Saboun', 'Traditional soap market', 'Old City', 34.435, 35.839, '[]', 'Markets & Souks', 'markets', '1 hour', 'varies', 'Any', 4.5, 85, '["soap","souvenirs"]')
ON CONFLICT (id) DO NOTHING;
INSERT INTO interests (id, name, icon, description, color, count, popularity, tags) VALUES
  ('culture', 'Culture & Heritage', 'landmark', 'Historic sites and traditions', '#8B4513', 0, 10, '[]'),
  ('food', 'Food & Dining', 'utensils', 'Local cuisine', '#CD853F', 0, 9, '[]'),
  ('shopping', 'Shopping', 'shopping-bag', 'Markets and souks', '#D2691E', 0, 8, '[]')
ON CONFLICT (id) DO NOTHING;

-- OAuth support
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(50) DEFAULT 'email';
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider_id VARCHAR(255);
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;
UPDATE users SET auth_provider = 'email' WHERE auth_provider IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_oauth ON users(auth_provider, auth_provider_id) WHERE auth_provider_id IS NOT NULL;
