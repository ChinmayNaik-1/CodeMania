CREATE TABLE IF NOT EXISTS driver_code (
  id SERIAL PRIMARY KEY,
  problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
  language VARCHAR(50) NOT NULL,
  driver_prefix TEXT NOT NULL DEFAULT '',
  driver_suffix TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(problem_id, language)
);
