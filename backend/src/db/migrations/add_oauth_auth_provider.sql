-- Add OAuth support: auth_provider, auth_provider_id, nullable password_hash
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(50) DEFAULT 'email';
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider_id VARCHAR(255);
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;
UPDATE users SET auth_provider = 'email' WHERE auth_provider IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_oauth ON users(auth_provider, auth_provider_id) WHERE auth_provider_id IS NOT NULL;
