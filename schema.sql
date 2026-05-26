-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  google_uid VARCHAR(255) UNIQUE,
  avatar_url TEXT,
  role VARCHAR(10) DEFAULT 'user' CHECK (role IN ('admin','user')),
  rating INT DEFAULT 1200,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for performance
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_google_uid ON users(google_uid) WHERE google_uid IS NOT NULL;

-- Create problems table
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

-- Create test_cases table
CREATE TABLE IF NOT EXISTS test_cases (
  id SERIAL PRIMARY KEY,
  problem_id INT REFERENCES problems(id) ON DELETE CASCADE,
  input TEXT NOT NULL,
  expected_output TEXT NOT NULL,
  is_sample BOOLEAN DEFAULT false
);

-- Create contests table
CREATE TABLE IF NOT EXISTS contests (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP NOT NULL,
  status VARCHAR(10) DEFAULT 'upcoming' CHECK (status IN ('upcoming','running','ended')),
  created_by INT REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create contest_problems table
CREATE TABLE IF NOT EXISTS contest_problems (
  contest_id INT REFERENCES contests(id) ON DELETE CASCADE,
  problem_id INT REFERENCES problems(id) ON DELETE CASCADE,
  points INT DEFAULT 100,
  problem_order INT,
  PRIMARY KEY (contest_id, problem_id)
);

-- Create teams table
CREATE TABLE IF NOT EXISTS teams (
  id SERIAL PRIMARY KEY,
  contest_id INT REFERENCES contests(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  join_code VARCHAR(8) UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create team_members table
CREATE TABLE IF NOT EXISTS team_members (
  team_id INT REFERENCES teams(id) ON DELETE CASCADE,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (team_id, user_id)
);

-- Create submissions table
CREATE TABLE IF NOT EXISTS submissions (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  problem_id INT REFERENCES problems(id),
  contest_id INT REFERENCES contests(id),
  team_id INT REFERENCES teams(id),
  language VARCHAR(30) NOT NULL,
  language_version VARCHAR(20) NOT NULL,
  code TEXT NOT NULL,
  verdict VARCHAR(30) NOT NULL,
  passed_cases INT DEFAULT 0,
  total_cases INT DEFAULT 0,
  time_ms INT,
  memory_kb INT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create driver_code table
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

-- Create indexes for performance
CREATE INDEX idx_problems_difficulty ON problems(difficulty);
CREATE INDEX idx_problems_tags ON problems USING GIN(tags);
CREATE INDEX idx_submissions_user ON submissions(user_id);
CREATE INDEX idx_submissions_problem ON submissions(problem_id);
CREATE INDEX idx_submissions_contest ON submissions(contest_id);
CREATE INDEX idx_team_members_user ON team_members(user_id);
CREATE INDEX idx_team_members_team ON team_members(team_id);
CREATE INDEX idx_contests_status ON contests(status);
