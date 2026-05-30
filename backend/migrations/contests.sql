-- ================================================================
-- CodeMania Contests Migration — Full Rebuild
-- Drop old tables and create new contest schema
-- ================================================================

-- 1. Drop old contest-related tables (in reverse FK order)
DROP TABLE IF EXISTS team_problem_status CASCADE;
DROP TABLE IF EXISTS team_invites CASCADE;
DROP TABLE IF EXISTS team_members CASCADE;
DROP TABLE IF EXISTS teams CASCADE;
DROP TABLE IF EXISTS user_contest_history CASCADE;
DROP TABLE IF EXISTS contest_problems CASCADE;
DROP TABLE IF EXISTS contests CASCADE;

-- ================================================================
-- NEW SCHEMA
-- ================================================================

-- 2. Add contest_exclusive flag to problems (idempotent)
ALTER TABLE problems
  ADD COLUMN IF NOT EXISTS is_contest_exclusive BOOLEAN DEFAULT false;

-- 3. Contests master table
CREATE TABLE contests (
  id               SERIAL PRIMARY KEY,
  title            VARCHAR(255) NOT NULL,
  description      TEXT,
  contest_type     VARCHAR(10) NOT NULL DEFAULT 'solo'
                   CHECK (contest_type IN ('solo','team')),
  max_team_size    INT DEFAULT 1,
  start_time       TIMESTAMP NOT NULL,
  end_time         TIMESTAMP NOT NULL,
  status           VARCHAR(10) NOT NULL DEFAULT 'draft'
                   CHECK (status IN ('draft','upcoming','live','ended')),
  created_by       INT REFERENCES users(id),
  created_at       TIMESTAMP DEFAULT NOW()
);

-- 4. Problems in a contest (with points)
CREATE TABLE contest_problems (
  contest_id     INT NOT NULL REFERENCES contests(id) ON DELETE CASCADE,
  problem_id     INT NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
  points         INT NOT NULL DEFAULT 100,
  problem_order  INT NOT NULL DEFAULT 1,
  PRIMARY KEY (contest_id, problem_id)
);

-- 5. Teams (team contests only)
CREATE TABLE contest_teams (
  id           SERIAL PRIMARY KEY,
  contest_id   INT NOT NULL REFERENCES contests(id) ON DELETE CASCADE,
  name         VARCHAR(100) NOT NULL,
  created_by   INT NOT NULL REFERENCES users(id),
  created_at   TIMESTAMP DEFAULT NOW(),
  UNIQUE (contest_id, name)
);

-- 6. Team members
CREATE TABLE contest_team_members (
  team_id    INT NOT NULL REFERENCES contest_teams(id) ON DELETE CASCADE,
  user_id    INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at  TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (team_id, user_id)
);

-- 7. Team invitations
CREATE TABLE contest_team_invitations (
  id           SERIAL PRIMARY KEY,
  team_id      INT NOT NULL REFERENCES contest_teams(id) ON DELETE CASCADE,
  contest_id   INT NOT NULL REFERENCES contests(id) ON DELETE CASCADE,
  invitee_id   INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  inviter_id   INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status       VARCHAR(10) NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending','accepted','rejected')),
  created_at   TIMESTAMP DEFAULT NOW(),
  UNIQUE (contest_id, invitee_id)
);

-- 8. Solo registrations
CREATE TABLE contest_registrations (
  id            SERIAL PRIMARY KEY,
  contest_id    INT NOT NULL REFERENCES contests(id) ON DELETE CASCADE,
  user_id       INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  registered_at TIMESTAMP DEFAULT NOW(),
  UNIQUE (contest_id, user_id)
);

-- 9. Contest submissions (separate from global submissions)
CREATE TABLE contest_submissions (
  id            SERIAL PRIMARY KEY,
  contest_id    INT NOT NULL REFERENCES contests(id),
  problem_id    INT NOT NULL REFERENCES problems(id),
  user_id       INT NOT NULL REFERENCES users(id),
  team_id       INT REFERENCES contest_teams(id),
  language      VARCHAR(20),
  code          TEXT,
  verdict       VARCHAR(30),
  score_awarded INT DEFAULT 0,
  first_solve   BOOLEAN DEFAULT false,
  submitted_at  TIMESTAMP DEFAULT NOW()
);

-- 10. Contest leaderboard
CREATE TABLE contest_leaderboard (
  contest_id       INT NOT NULL REFERENCES contests(id) ON DELETE CASCADE,
  user_id          INT REFERENCES users(id),
  team_id          INT REFERENCES contest_teams(id),
  total_score      INT DEFAULT 0,
  problems_solved  INT DEFAULT 0,
  last_accepted_at TIMESTAMP
);

CREATE UNIQUE INDEX uq_leaderboard_solo
  ON contest_leaderboard (contest_id, user_id) WHERE team_id IS NULL;
CREATE UNIQUE INDEX uq_leaderboard_team
  ON contest_leaderboard (contest_id, team_id) WHERE user_id IS NULL;

-- 11. Per-problem solve tracking
CREATE TABLE contest_problem_solves (
  contest_id    INT NOT NULL REFERENCES contests(id) ON DELETE CASCADE,
  problem_id    INT NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
  team_id       INT REFERENCES contest_teams(id),
  user_id       INT REFERENCES users(id),
  solved_at     TIMESTAMP DEFAULT NOW(),
  score_awarded INT DEFAULT 0
);

CREATE UNIQUE INDEX uq_problem_solve_team
  ON contest_problem_solves (contest_id, problem_id, team_id)
  WHERE team_id IS NOT NULL;

CREATE UNIQUE INDEX uq_problem_solve_solo
  ON contest_problem_solves (contest_id, problem_id, user_id)
  WHERE team_id IS NULL;
