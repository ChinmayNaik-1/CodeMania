-- Remove is_sample (replaced by is_hidden=false)
ALTER TABLE test_cases DROP COLUMN IF EXISTS is_sample;

-- Ensure is_hidden exists with default false
ALTER TABLE test_cases
  ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN DEFAULT false;

-- description is already TEXT; no change needed for markdown support
-- (markdown is stored as plain text and rendered on the frontend)
