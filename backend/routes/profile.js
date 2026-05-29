import express from 'express';
import { dbPool } from '../index.js';
import { authMiddleware } from '../middleware/auth.js';
import { getProfileData } from '../services/profileService.js';
import { getRedisClient } from '../services/leaderboardService.js';
import { getContestIo } from '../socket/contestSocket.js';

const router = express.Router();

router.use(authMiddleware);

router.get('/profile/:userId', async (req, res) => {
  try {
    const data = await getProfileData(req.params.userId, req.user.id);
    if (!data) return res.status(404).json({ error: 'User not found' });
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.put('/profile', async (req, res) => {
  try {
    const { username, bio, avatar_url } = req.body;
    if (username && !/^[a-zA-Z0-9_]{3,20}$/.test(username)) {
      return res.status(400).json({ error: 'Invalid username format' });
    }
    const result = await dbPool.query(
      `UPDATE users SET username = COALESCE($1, username), bio = COALESCE($2, bio), avatar_url = COALESCE($3, avatar_url)
       WHERE id = $4 RETURNING id, username, bio, avatar_url`,
      [username, bio, avatar_url, req.user.id]
    );
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/friends', async (req, res) => {
  try {
    const result = await dbPool.query(
      `SELECT u.id, u.username, u.avatar_url, u.global_rank,
              us.current_streak,
              (SELECT COUNT(*) FROM submissions
               WHERE user_id = u.id AND (verdict = 'accepted' OR verdict = 'Accepted')) as solved_count
       FROM friendships f
       JOIN users u ON (
         CASE WHEN f.requester_id = $1 THEN f.addressee_id
              ELSE f.requester_id END = u.id
       )
       LEFT JOIN user_streaks us ON us.user_id = u.id
       WHERE (f.requester_id = $1 OR f.addressee_id = $1)
         AND f.status = 'accepted'`,
      [req.user.id]
    );
    const friends = result.rows;
    const redis = getRedisClient();
    for (let f of friends) {
      const isOnline = await redis.get(`online:${f.id}`);
      f.is_online = !!isOnline;
      f.solved_count = parseInt(f.solved_count, 10) || 0;
    }
    res.json(friends);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/friends/requests', async (req, res) => {
  try {
    const result = await dbPool.query(
      `SELECT f.id, f.created_at, u.id as requester_id, u.username, u.avatar_url
       FROM friendships f
       JOIN users u ON u.id = f.requester_id
       WHERE f.addressee_id = $1 AND f.status = 'pending'`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/friends/request/:userId', async (req, res) => {
  try {
    const targetId = parseInt(req.params.userId, 10);
    if (targetId === req.user.id) return res.status(400).json({ error: 'Cannot add self' });
    
    const check = await dbPool.query(
      `SELECT id FROM friendships
       WHERE (requester_id = $1 AND addressee_id = $2)
          OR (requester_id = $2 AND addressee_id = $1)`,
      [req.user.id, targetId]
    );
    if (check.rows.length > 0) return res.status(400).json({ error: 'Already requested or friends' });

    await dbPool.query(
      `INSERT INTO friendships (requester_id, addressee_id, status) VALUES ($1, $2, 'pending')`,
      [req.user.id, targetId]
    );

    await dbPool.query(
      `INSERT INTO user_activity_feed (user_id, activity_type, meta) VALUES ($1, 'friend_added', $2)`,
      [targetId, JSON.stringify({ from_user_id: req.user.id })]
    );

    const io = getContestIo();
    if (io) {
      io.to(`user:${targetId}`).emit('friend_request', { from: req.user.id });
    }

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.put('/friends/request/:requestId', async (req, res) => {
  try {
    const { action } = req.body;
    if (action !== 'accept' && action !== 'reject') return res.status(400).json({ error: 'Invalid action' });

    const result = await dbPool.query(
      `UPDATE friendships SET status = $1, updated_at = NOW()
       WHERE id = $2 AND addressee_id = $3 RETURNING requester_id`,
      [action === 'accept' ? 'accepted' : 'rejected', req.params.requestId, req.user.id]
    );

    if (result.rows.length === 0) return res.status(404).json({ error: 'Request not found' });

    if (action === 'accept') {
      const io = getContestIo();
      if (io) {
        io.to(`user:${result.rows[0].requester_id}`).emit('friend_accepted', { from: req.user.id });
      }
    }

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.delete('/friends/:userId', async (req, res) => {
  try {
    const targetId = req.params.userId;
    await dbPool.query(
      `DELETE FROM friendships
       WHERE (requester_id = $1 AND addressee_id = $2)
          OR (requester_id = $2 AND addressee_id = $1)`,
      [req.user.id, targetId]
    );
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/friends/feed', async (req, res) => {
  try {
    const friendsRes = await dbPool.query(
      `SELECT CASE WHEN requester_id = $1 THEN addressee_id ELSE requester_id END as friend_id
       FROM friendships WHERE (requester_id = $1 OR addressee_id = $1) AND status = 'accepted'`,
      [req.user.id]
    );
    const friendIds = friendsRes.rows.map(r => r.friend_id);
    friendIds.push(req.user.id);

    const feed = await dbPool.query(
      `SELECT f.id, f.user_id, f.activity_type, f.created_at, u.username, u.avatar_url, p.title as problem_title,
              c.title as contest_title, f.problem_id, f.contest_id
       FROM user_activity_feed f
       JOIN users u ON u.id = f.user_id
       LEFT JOIN problems p ON p.id = f.problem_id
       LEFT JOIN contests c ON c.id = f.contest_id
       WHERE f.user_id = ANY($1)
       ORDER BY f.created_at DESC
       LIMIT 30`,
      [friendIds]
    );
    res.json(feed.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/leaderboard/friends', async (req, res) => {
  try {
    const friendsRes = await dbPool.query(
      `SELECT CASE WHEN requester_id = $1 THEN addressee_id ELSE requester_id END as friend_id
       FROM friendships WHERE (requester_id = $1 OR addressee_id = $1) AND status = 'accepted'`,
      [req.user.id]
    );
    const friendIds = friendsRes.rows.map(r => r.friend_id);
    friendIds.push(req.user.id);

    const result = await dbPool.query(
      `SELECT u.id, u.username, u.avatar_url, u.global_rank,
              COUNT(DISTINCT s.problem_id) as solved_count,
              COALESCE(us.current_streak, 0) as current_streak
       FROM users u
       LEFT JOIN submissions s ON s.user_id = u.id AND (s.verdict = 'accepted' OR s.verdict = 'Accepted')
       LEFT JOIN user_streaks us ON us.user_id = u.id
       WHERE u.id = ANY($1)
       GROUP BY u.id, us.current_streak
       ORDER BY solved_count DESC`,
      [friendIds]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
