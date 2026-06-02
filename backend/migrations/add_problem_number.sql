ALTER TABLE problems
  ADD COLUMN IF NOT EXISTS problem_number INT;

-- Backfill existing problems with sequential numbers by id order
WITH numbered AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
  FROM problems
)
UPDATE problems SET problem_number = numbered.rn
FROM numbered WHERE problems.id = numbered.id;

-- Add unique constraint
CREATE UNIQUE INDEX IF NOT EXISTS uq_problem_number
  ON problems (problem_number);
