-- 1. Contests table
CREATE TABLE IF NOT EXISTS contests (
  id              SERIAL PRIMARY KEY,
  title           VARCHAR(255) NOT NULL,
  description     TEXT,
  status          VARCHAR(20) NOT NULL DEFAULT 'upcoming'
                    CHECK (status IN ('upcoming', 'registration_open', 'in_progress', 'ended')),
  max_team_size   INT NOT NULL DEFAULT 1 CHECK (max_team_size BETWEEN 1 AND 4),
  scoring_type    VARCHAR(10) NOT NULL DEFAULT 'icpc' CHECK (scoring_type IN ('icpc')),
  penalty_minutes INT NOT NULL DEFAULT 20,
  starts_at       TIMESTAMPTZ NOT NULL,
  ends_at         TIMESTAMPTZ NOT NULL,
  created_by      INT REFERENCES users(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Backfill/extend existing contests table (if created previously)
ALTER TABLE contests
  ADD COLUMN IF NOT EXISTS starts_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS ends_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS max_team_size INT NOT NULL DEFAULT 1 CHECK (max_team_size BETWEEN 1 AND 4),
  ADD COLUMN IF NOT EXISTS scoring_type VARCHAR(10) NOT NULL DEFAULT 'icpc' CHECK (scoring_type IN ('icpc')),
  ADD COLUMN IF NOT EXISTS penalty_minutes INT NOT NULL DEFAULT 20;

UPDATE contests
SET starts_at = COALESCE(starts_at, start_time),
    ends_at = COALESCE(ends_at, end_time)
WHERE (starts_at IS NULL OR ends_at IS NULL)
  AND (start_time IS NOT NULL OR end_time IS NOT NULL);

ALTER TABLE contests
  ALTER COLUMN status TYPE VARCHAR(20);

UPDATE contests
SET status = 'in_progress'
WHERE status = 'running';

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'contests_status_check'
  ) THEN
    EXECUTE 'ALTER TABLE contests DROP CONSTRAINT contests_status_check';
  END IF;
END $$;

ALTER TABLE contests
  ADD CONSTRAINT contests_status_check
  CHECK (status IN ('upcoming', 'registration_open', 'in_progress', 'ended'));

-- 2. Extend problems table for contest-only visibility
ALTER TABLE problems
  ADD COLUMN IF NOT EXISTS visibility VARCHAR(20) NOT NULL DEFAULT 'public'
    CHECK (visibility IN ('public', 'contest_only')),
  ADD COLUMN IF NOT EXISTS contest_id INT REFERENCES contests(id) ON DELETE SET NULL;

-- 3. Teams table
CREATE TABLE IF NOT EXISTS teams (
  id          SERIAL PRIMARY KEY,
  contest_id  INT NOT NULL REFERENCES contests(id) ON DELETE CASCADE,
  name        VARCHAR(100) NOT NULL,
  leader_id   INT NOT NULL REFERENCES users(id),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(contest_id, name)
);

-- Backfill/extend existing teams table (if created previously)
ALTER TABLE teams
  ADD COLUMN IF NOT EXISTS leader_id INT REFERENCES users(id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_teams_contest_name ON teams(contest_id, name);

-- 4. Team members
CREATE TABLE IF NOT EXISTS team_members (
  team_id    INT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  user_id    INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at  TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (team_id, user_id)
);

-- 5. Team invites
CREATE TABLE IF NOT EXISTS team_invites (
  id          SERIAL PRIMARY KEY,
  team_id     INT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  invitee_id  INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status      VARCHAR(10) NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'accepted', 'declined')),
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(team_id, invitee_id)
);

-- 6. ICPC per-team per-problem tracking
CREATE TABLE IF NOT EXISTS team_problem_status (
  team_id         INT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  problem_id      INT NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
  contest_id      INT NOT NULL REFERENCES contests(id) ON DELETE CASCADE,
  wrong_attempts  INT NOT NULL DEFAULT 0,
  solved_at       TIMESTAMPTZ,
  penalty_minutes INT NOT NULL DEFAULT 0,
  PRIMARY KEY (team_id, problem_id)
);

-- 7. Extend submissions for contest tracking
ALTER TABLE submissions
  ADD COLUMN IF NOT EXISTS contest_id INT REFERENCES contests(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS team_id    INT REFERENCES teams(id)    ON DELETE SET NULL;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_submissions_contest  ON submissions(contest_id);
CREATE INDEX IF NOT EXISTS idx_tps_team_contest     ON team_problem_status(team_id, contest_id);
CREATE INDEX IF NOT EXISTS idx_teams_contest        ON teams(contest_id);
