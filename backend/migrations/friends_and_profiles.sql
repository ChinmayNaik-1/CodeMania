-- 1. Extend users table
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS username       VARCHAR(30) UNIQUE,
  ADD COLUMN IF NOT EXISTS avatar_url     TEXT,
  ADD COLUMN IF NOT EXISTS bio            TEXT,
  ADD COLUMN IF NOT EXISTS global_rank    INT;

-- 2. Friendships
CREATE TABLE IF NOT EXISTS friendships (
  id              SERIAL PRIMARY KEY,
  requester_id    INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  addressee_id    INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status          VARCHAR(10) NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','accepted','rejected')),
  created_at      TIMESTAMP DEFAULT NOW(),
  updated_at      TIMESTAMP DEFAULT NOW(),
  UNIQUE(requester_id, addressee_id)
);

-- 3. Daily activity (heatmap)
CREATE TABLE IF NOT EXISTS user_daily_activity (
  user_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity_date   DATE NOT NULL,
  submission_count INT DEFAULT 0,
  PRIMARY KEY (user_id, activity_date)
);

-- 4. Streaks
CREATE TABLE IF NOT EXISTS user_streaks (
  user_id           INT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  current_streak    INT DEFAULT 0,
  max_streak        INT DEFAULT 0,
  last_active_date  DATE
);

-- 5. Contest rating history
CREATE TABLE IF NOT EXISTS user_contest_history (
  id               SERIAL PRIMARY KEY,
  user_id          INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  contest_id       INT NOT NULL REFERENCES contests(id) ON DELETE CASCADE,
  rank             INT,
  score            INT,
  rating_change    INT DEFAULT 0,
  rating_after     INT DEFAULT 1500,
  participated_at  TIMESTAMP DEFAULT NOW()
);

-- 6. Activity feed
CREATE TABLE IF NOT EXISTS user_activity_feed (
  id              SERIAL PRIMARY KEY,
  user_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity_type   VARCHAR(30) NOT NULL
                  CHECK (activity_type IN (
                    'solved','contest_joined','contest_finished','friend_added'
                  )),
  problem_id      INT REFERENCES problems(id) ON DELETE SET NULL,
  contest_id      INT REFERENCES contests(id) ON DELETE SET NULL,
  meta            JSONB DEFAULT '{}',
  created_at      TIMESTAMP DEFAULT NOW()
);
