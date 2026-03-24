-- Unique public usernames (case-insensitive, stored without @ prefix in profiles.username)
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_username_lower_unique
ON profiles (LOWER(REGEXP_REPLACE(TRIM(username), '^@+', '')))
WHERE username IS NOT NULL AND LENGTH(TRIM(REGEXP_REPLACE(username, '^@+', ''))) >= 3;
