-- Migration 002: Enforce required local credentials for all users
-- This migration assumes the users table has been cleared before execution.

BEGIN;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

ALTER TABLE users
  ALTER COLUMN password_hash SET NOT NULL;

ALTER TABLE users
  DROP CONSTRAINT IF EXISTS users_auth_provider_check;

ALTER TABLE users
  DROP COLUMN IF EXISTS auth_provider;

COMMIT;
