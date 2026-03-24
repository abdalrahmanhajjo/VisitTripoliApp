CREATE TABLE IF NOT EXISTS user_push_tokens (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform VARCHAR(32) DEFAULT 'android',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
