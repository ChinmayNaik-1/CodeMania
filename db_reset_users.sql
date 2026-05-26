-- Deletes all users and dependent rows, then resets ID sequence.
TRUNCATE TABLE users RESTART IDENTITY CASCADE;

-- Verification query
SELECT COUNT(*) AS users_count FROM users;
SELECT last_value, is_called FROM users_id_seq;
