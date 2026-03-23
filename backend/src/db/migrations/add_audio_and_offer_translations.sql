-- Optional translations for audio guide titles and restaurant offer copy (ar, fr, en rows).

CREATE TABLE IF NOT EXISTS audio_guide_translations (
  audio_guide_id UUID NOT NULL REFERENCES audio_guides(id) ON DELETE CASCADE,
  lang VARCHAR(5) NOT NULL,
  title VARCHAR(200),
  PRIMARY KEY (audio_guide_id, lang)
);
CREATE INDEX IF NOT EXISTS idx_audio_guide_translations_lang ON audio_guide_translations(lang);

CREATE TABLE IF NOT EXISTS place_offer_translations (
  offer_id UUID NOT NULL REFERENCES place_offers(id) ON DELETE CASCADE,
  lang VARCHAR(5) NOT NULL,
  title VARCHAR(200),
  description TEXT,
  PRIMARY KEY (offer_id, lang)
);
CREATE INDEX IF NOT EXISTS idx_place_offer_translations_lang ON place_offer_translations(lang);
