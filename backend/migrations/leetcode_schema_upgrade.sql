-- Add all missing LeetCode-style fields to problems table
ALTER TABLE problems
  ADD COLUMN IF NOT EXISTS constraints     TEXT,
  ADD COLUMN IF NOT EXISTS hints           JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS follow_up       TEXT,
  ADD COLUMN IF NOT EXISTS topics          TEXT[] DEFAULT '{}';

-- description column already exists as TEXT; no change needed
-- code_stubs JSONB already exists; no change needed

-- Simplify test_cases: remove is_sample, keep only is_hidden
ALTER TABLE test_cases DROP COLUMN IF EXISTS is_sample;
ALTER TABLE test_cases ADD COLUMN IF NOT EXISTS is_hidden    BOOLEAN DEFAULT false;
ALTER TABLE test_cases ADD COLUMN IF NOT EXISTS image_url    TEXT;

-- explanation column may already exist; guard with IF NOT EXISTS
ALTER TABLE test_cases ADD COLUMN IF NOT EXISTS explanation  TEXT;
