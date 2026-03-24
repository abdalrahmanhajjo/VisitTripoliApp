-- Tripoli Explorer+ PostgreSQL Schema

-- Users (email/password, phone, or OAuth)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL,
  email_verified BOOLEAN DEFAULT false,
  phone VARCHAR(20),
  phone_verified BOOLEAN DEFAULT false,
  password_hash VARCHAR(255),
  name VARCHAR(255),
  auth_provider VARCHAR(50) DEFAULT 'email',
  auth_provider_id VARCHAR(255),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(LOWER(email));
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_oauth ON users(auth_provider, auth_provider_id) WHERE auth_provider_id IS NOT NULL;

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

-- Categories (for places - e.g. Historic, Food, Markets)
CREATE TABLE IF NOT EXISTS categories (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  icon VARCHAR(50) NOT NULL,
  description TEXT,
  tags JSONB DEFAULT '[]',
  count INT DEFAULT 0,
  color VARCHAR(20)
);

-- Places (tourist locations, landmarks, etc.)
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
  tags JSONB,
  checkin_token VARCHAR(64) NOT NULL UNIQUE DEFAULT (
    lower(replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''))
  )
);

-- Place reviews (per user, per place)
CREATE TABLE IF NOT EXISTS place_reviews (
  id BIGSERIAL PRIMARY KEY,
  place_id VARCHAR(50) NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title TEXT,
  review TEXT,
  visit_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
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

-- Saved places (user <-> place)
CREATE TABLE IF NOT EXISTS saved_places (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  place_id VARCHAR(50) REFERENCES places(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, place_id)
);

-- Saved tours
CREATE TABLE IF NOT EXISTS saved_tours (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  tour_id VARCHAR(50) REFERENCES tours(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, tour_id)
);

-- Saved events
CREATE TABLE IF NOT EXISTS saved_events (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  event_id VARCHAR(50) REFERENCES events(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, event_id)
);

-- Password reset tokens (secure: hash-only storage, short expiry)
CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(64) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_token_hash ON password_reset_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_user_id ON password_reset_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_expires_at ON password_reset_tokens(expires_at);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_places_category ON places(category_id);
CREATE INDEX IF NOT EXISTS idx_places_category_name ON places(category);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);
CREATE INDEX IF NOT EXISTS idx_trips_user_id ON trips(user_id);

-- Email verification tokens
CREATE TABLE IF NOT EXISTS email_verification_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(64) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_email_verification_token_hash ON email_verification_tokens(token_hash);

-- Phone OTP codes
CREATE TABLE IF NOT EXISTS phone_otp_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(20) NOT NULL,
  code_hash VARCHAR(64) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  attempts INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_phone_otp_phone ON phone_otp_codes(phone);

-- FCM / push notification tokens (one row per user)
CREATE TABLE IF NOT EXISTS user_push_tokens (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform VARCHAR(32) DEFAULT 'android',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
