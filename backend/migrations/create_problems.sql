CREATE TABLE IF NOT EXISTS problems (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  difficulty VARCHAR(10) CHECK (difficulty IN ('easy','medium','hard')),
  tags TEXT[],
  created_by INT REFERENCES users(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  code_stubs JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON COLUMN problems.code_stubs IS
  'Per-language starter code shown in editor. Keys: cpp, python, java, javascript. Values: stub string.';
