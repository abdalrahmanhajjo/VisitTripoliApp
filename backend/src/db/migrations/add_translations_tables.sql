-- Translations stored in DB (no external API). One row per entity per language (ar, fr).
-- Source content is in the main tables (e.g. English); fill these tables manually or via admin.

CREATE TABLE IF NOT EXISTS place_translations (
  place_id VARCHAR(50) NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  lang VARCHAR(5) NOT NULL,
  name VARCHAR(255),
  description TEXT,
  location VARCHAR(255),
  category VARCHAR(100),
  duration VARCHAR(50),
  price VARCHAR(50),
  best_time VARCHAR(100),
  tags JSONB,
  PRIMARY KEY (place_id, lang)
);

CREATE TABLE IF NOT EXISTS category_translations (
  category_id VARCHAR(50) NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  lang VARCHAR(5) NOT NULL,
  name VARCHAR(100),
  description TEXT,
  tags JSONB,
  PRIMARY KEY (category_id, lang)
);

CREATE TABLE IF NOT EXISTS event_translations (
  event_id VARCHAR(50) NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  lang VARCHAR(5) NOT NULL,
  name VARCHAR(255),
  description TEXT,
  location VARCHAR(255),
  category VARCHAR(100),
  organizer VARCHAR(255),
  price_display VARCHAR(50),
  status VARCHAR(50),
  PRIMARY KEY (event_id, lang)
);

CREATE TABLE IF NOT EXISTS tour_translations (
  tour_id VARCHAR(50) NOT NULL REFERENCES tours(id) ON DELETE CASCADE,
  lang VARCHAR(5) NOT NULL,
  name VARCHAR(255),
  description TEXT,
  difficulty VARCHAR(50),
  badge VARCHAR(50),
  duration VARCHAR(50),
  price_display VARCHAR(50),
  includes JSONB,
  excludes JSONB,
  highlights JSONB,
  itinerary JSONB,
  PRIMARY KEY (tour_id, lang)
);

CREATE TABLE IF NOT EXISTS interest_translations (
  interest_id VARCHAR(50) NOT NULL REFERENCES interests(id) ON DELETE CASCADE,
  lang VARCHAR(5) NOT NULL,
  name VARCHAR(100),
  description TEXT,
  tags JSONB,
  PRIMARY KEY (interest_id, lang)
);

CREATE INDEX IF NOT EXISTS idx_place_translations_lang ON place_translations(lang);
CREATE INDEX IF NOT EXISTS idx_category_translations_lang ON category_translations(lang);
CREATE INDEX IF NOT EXISTS idx_event_translations_lang ON event_translations(lang);
CREATE INDEX IF NOT EXISTS idx_tour_translations_lang ON tour_translations(lang);
CREATE INDEX IF NOT EXISTS idx_interest_translations_lang ON interest_translations(lang);
