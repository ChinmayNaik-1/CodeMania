-- Drop old contest_submissions if it exists (wrong schema)
DROP TABLE IF EXISTS contest_submissions CASCADE;

-- Clean separate table for contest submissions only
CREATE TABLE contest_submissions (
  id               SERIAL PRIMARY KEY,
  contest_id       INT NOT NULL REFERENCES contests(id) ON DELETE CASCADE,
  problem_id       INT NOT NULL REFERENCES problems(id) ON DELETE CASCADE,

  -- Who submitted
  user_id          INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  username         VARCHAR(100) NOT NULL,   -- denormalized for fast leaderboard

  -- Team info (NULL for solo contests)
  team_id          INT REFERENCES contest_teams(id) ON DELETE SET NULL,
  team_name        VARCHAR(100),            -- denormalized, NULL for solo

  -- Submission content
  language         VARCHAR(20) NOT NULL,
  code             TEXT NOT NULL,

  -- Result
  verdict          VARCHAR(30),             -- Accepted | Wrong Answer | TLE | CE | RE
  stdout           TEXT,
  stderr           TEXT,
  compile_output   TEXT,
  time_ms          INT,
  memory_kb        INT,

  -- Scoring
  score_awarded    INT DEFAULT 0,
  first_solve      BOOLEAN DEFAULT false,
  -- first_solve = true means this user was first on their team to solve this problem

  submitted_at     TIMESTAMP DEFAULT NOW()
);

-- Indexes for fast leaderboard queries
CREATE INDEX IF NOT EXISTS idx_cs_contest   ON contest_submissions(contest_id);
CREATE INDEX IF NOT EXISTS idx_cs_user      ON contest_submissions(contest_id, user_id);
CREATE INDEX IF NOT EXISTS idx_cs_team      ON contest_submissions(contest_id, team_id);
CREATE INDEX IF NOT EXISTS idx_cs_verdict   ON contest_submissions(contest_id, verdict);
