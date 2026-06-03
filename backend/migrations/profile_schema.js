import { Client } from 'pg';

const statements = [
  {
    label: 'users.bio',
    sql: 'ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT;'
  },
  {
    label: 'users.avatar_url',
    sql: 'ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;'
  },
  {
    label: 'users.google_uid',
    sql: 'ALTER TABLE users ADD COLUMN IF NOT EXISTS google_uid TEXT;'
  },
  {
    label: 'users.global_rank',
    sql: 'ALTER TABLE users ADD COLUMN IF NOT EXISTS global_rank INTEGER;'
  },
  {
    label: 'users.rating',
    sql: 'ALTER TABLE users ADD COLUMN IF NOT EXISTS rating INTEGER DEFAULT 1200;'
  },
  {
    label: 'problems.topics',
    sql: "ALTER TABLE problems ADD COLUMN IF NOT EXISTS topics JSONB DEFAULT '[]';"
  },
  {
    label: 'user_daily_activity',
    sql: `CREATE TABLE IF NOT EXISTS user_daily_activity (
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  activity_date DATE NOT NULL,
  submission_count INTEGER DEFAULT 0,
  PRIMARY KEY (user_id, activity_date)
);`
  },
  {
    label: 'user_streaks',
    sql: `CREATE TABLE IF NOT EXISTS user_streaks (
  user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  max_streak INTEGER DEFAULT 0,
  last_active_date DATE
);`
  },
  {
    label: 'user_activity_feed',
    sql: `CREATE TABLE IF NOT EXISTS user_activity_feed (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL,
  problem_id INTEGER REFERENCES problems(id) ON DELETE SET NULL,
  meta JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);`
  },
  {
    label: 'friendships',
    sql: `CREATE TABLE IF NOT EXISTS friendships (
  id SERIAL PRIMARY KEY,
  requester_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  addressee_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(requester_id, addressee_id)
);`
  }
];

async function run() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    for (const stmt of statements) {
      try {
        await client.query(stmt.sql);
        console.log(`OK: ${stmt.label}`);
      } catch (err) {
        console.error(`ERROR: ${stmt.label} - ${err.message}`);
      }
    }
  } catch (err) {
    console.error(`ERROR: connection - ${err.message}`);
  } finally {
    await client.end();
  }
}

run();
