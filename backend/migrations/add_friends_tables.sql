-- Migration: add_friends_tables
-- Safe to run multiple times (IF NOT EXISTS guards)

-- Friend requests table (pending invitations)
CREATE TABLE IF NOT EXISTS friend_requests (
  id          SERIAL PRIMARY KEY,
  sender_id   INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status      VARCHAR(20) NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at  TIMESTAMP DEFAULT NOW(),
  UNIQUE(sender_id, receiver_id)
);

-- Accepted friends table (bidirectional — both rows always inserted)
CREATE TABLE IF NOT EXISTS friends (
  user_id    INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id  INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, friend_id)
);

-- Indexes for fast look-ups
CREATE INDEX IF NOT EXISTS idx_friend_requests_receiver ON friend_requests(receiver_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_sender   ON friend_requests(sender_id);
CREATE INDEX IF NOT EXISTS idx_friends_user             ON friends(user_id);
CREATE INDEX IF NOT EXISTS idx_friends_friend           ON friends(friend_id);

-- User search helper index (case-insensitive prefix search)
CREATE INDEX IF NOT EXISTS idx_users_username_lower ON users(LOWER(username));
