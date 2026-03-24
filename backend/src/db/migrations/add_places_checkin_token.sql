-- Secret token for official door QR; never exposed on public /api/places routes.
ALTER TABLE places ADD COLUMN IF NOT EXISTS checkin_token VARCHAR(64);

UPDATE places
SET checkin_token = lower(replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''))
WHERE checkin_token IS NULL;

ALTER TABLE places ALTER COLUMN checkin_token SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_places_checkin_token ON places(checkin_token);
