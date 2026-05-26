-- Migration: Add Google Sign-In support and dual authentication
-- Adds google_uid, avatar_url, auth_provider columns and makes password_hash nullable

-- Add google_uid column if it doesn't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_uid VARCHAR(255) UNIQUE;

-- Add avatar_url column if it doesn't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Add auth_provider column if it doesn't exist (default to 'email')
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(20) DEFAULT 'email' CHECK (auth_provider IN ('email', 'google', 'both'));

-- Make password_hash nullable (for Google Sign-In users who don't have a password)
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;

-- Create index on google_uid for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_google_uid ON users(google_uid);

-- Update existing users to have correct auth_provider
UPDATE users 
SET auth_provider = CASE 
  WHEN password_hash IS NOT NULL AND google_uid IS NOT NULL THEN 'both'
  WHEN google_uid IS NOT NULL THEN 'google'
  ELSE 'email'
END
WHERE auth_provider = 'email';
