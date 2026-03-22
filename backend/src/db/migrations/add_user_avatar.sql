-- Profile image URL for users (stored in users for auth/display)
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
