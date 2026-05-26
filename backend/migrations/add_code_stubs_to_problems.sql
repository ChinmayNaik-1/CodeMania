ALTER TABLE problems
  ADD COLUMN IF NOT EXISTS code_stubs JSONB NOT NULL DEFAULT '{}';

COMMENT ON COLUMN problems.code_stubs IS
  'Per-language starter code shown in editor. Keys: cpp, python, java, javascript. Values: stub string.';
