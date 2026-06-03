import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { dbPool } from '../index.js';

const router = Router();
router.use(authMiddleware);

// ─── GET /api/friends/ping ────────────────────────────────────────────────────
router.get('/ping', (req, res) => {
  res.json({ ok: true, userId: req.user.id });
});

// ─── GET /api/friends/requests/incoming ─────────────────────────────────────
router.get('/requests/incoming', async (req, res) => {
  try {
    const result = await dbPool.query(
      `SELECT f.id, f.requester_id AS sender_id, f.created_at,
              u.username AS sender_username,
              u.avatar_url AS sender_avatar_url
       FROM friendships f
       JOIN users u ON u.id = f.requester_id
       WHERE f.addressee_id = $1 AND f.status = 'pending'
       ORDER BY f.created_at DESC`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error('GET /api/friends/requests/incoming error:', err);
    res.status(500).json({ error: 'Failed to load requests' });
  }
});

// ─── POST /api/friends/request ───────────────────────────────────────────────
router.post('/request', async (req, res) => {
  try {
    const targetUserId = parseInt(req.body.targetUserId, 10);
    if (!targetUserId || isNaN(targetUserId)) {
      return res.status(400).json({ error: 'targetUserId required' });
    }
    if (targetUserId === req.user.id) {
      return res.status(400).json({ error: 'Cannot send request to yourself' });
    }

    const check = await dbPool.query(
      `SELECT id FROM friendships
       WHERE (requester_id = $1 AND addressee_id = $2)
          OR (requester_id = $2 AND addressee_id = $1)`,
      [req.user.id, targetUserId]
    );
    if (check.rows.length > 0) {
      return res.status(400).json({ error: 'Already requested or friends' });
    }

    await dbPool.query(
      `INSERT INTO friendships (requester_id, addressee_id, status) VALUES ($1, $2, 'pending')`,
      [req.user.id, targetUserId]
    );
    res.json({ success: true });
  } catch (err) {
    console.error('POST /api/friends/request error:', err);
    res.status(500).json({ error: 'Failed to send request' });
  }
});

// ─── POST /api/friends/respond ───────────────────────────────────────────────
router.post('/respond', async (req, res) => {
  try {
    const requestId = parseInt(req.body.requestId, 10);
    const action = req.body.action;

    if (!requestId || !['accept', 'decline'].includes(action)) {
      return res.status(400).json({ error: 'requestId and action (accept|decline) required' });
    }

    if (action === 'accept') {
      await dbPool.query(
        `UPDATE friendships SET status = 'accepted', updated_at = NOW() WHERE id = $1 AND addressee_id = $2`,
        [requestId, req.user.id]
      );
    } else {
      await dbPool.query(
        `DELETE FROM friendships WHERE id = $1 AND addressee_id = $2`,
        [requestId, req.user.id]
      );
    }
    res.json({ success: true });
  } catch (err) {
    console.error('POST /api/friends/respond error:', err);
    res.status(500).json({ error: 'Failed to respond to request' });
  }
});

// ─── GET /api/friends (list all friends) ─────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const result = await dbPool.query(
      `SELECT 
        CASE 
          WHEN f.requester_id = $1 THEN u2.id
          ELSE u1.id
        END AS id,
        CASE 
          WHEN f.requester_id = $1 THEN u2.username
          ELSE u1.username
        END AS username,
        CASE 
          WHEN f.requester_id = $1 THEN u2.avatar_url
          ELSE u1.avatar_url
        END AS avatar_url,
        COALESCE(
          (SELECT COUNT(*) FROM submissions s 
           WHERE s.user_id = CASE WHEN f.requester_id = $1 THEN u2.id ELSE u1.id END 
           AND s.verdict = 'Accepted'), 0
        ) AS solved_count,
        0 AS current_streak,
        false AS is_online
       FROM friendships f
       JOIN users u1 ON u1.id = f.requester_id
       JOIN users u2 ON u2.id = f.addressee_id
       WHERE (f.requester_id = $1 OR f.addressee_id = $1) 
       AND f.status = 'accepted'
       ORDER BY username`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error('GET /api/friends error:', err);
    res.status(500).json({ error: 'Failed to load friends' });
  }
});

// ─── DELETE /api/friends/:userId (unfriend) ─────────────────────────────────
router.delete('/:userId', async (req, res) => {
  try {
    const userId = parseInt(req.params.userId, 10);
    if (!userId || isNaN(userId)) {
      return res.status(400).json({ error: 'userId required' });
    }

    await dbPool.query(
      `DELETE FROM friendships 
       WHERE ((requester_id = $1 AND addressee_id = $2) 
           OR (requester_id = $2 AND addressee_id = $1))
       AND status = 'accepted'`,
      [req.user.id, userId]
    );
    res.json({ success: true });
  } catch (err) {
    console.error('DELETE /api/friends/:userId error:', err);
    res.status(500).json({ error: 'Failed to unfriend' });
  }
});

// ─── GET /api/friends/feed (activity feed) ──────────────────────────────────
router.get('/feed', async (req, res) => {
  try {
    // Return empty array for now - can be implemented later
    res.json([]);
  } catch (err) {
    console.error('GET /api/friends/feed error:', err);
    res.status(500).json({ error: 'Failed to load feed' });
  }
});

// ─── GET /api/friends/leaderboard ───────────────────────────────────────────
router.get('/leaderboard', async (req, res) => {
  try {
    const result = await dbPool.query(
      `SELECT 
        CASE 
          WHEN f.requester_id = $1 THEN u2.id
          ELSE u1.id
        END AS id,
        CASE 
          WHEN f.requester_id = $1 THEN u2.username
          ELSE u1.username
        END AS username,
        CASE 
          WHEN f.requester_id = $1 THEN u2.avatar_url
          ELSE u1.avatar_url
        END AS avatar_url,
        COALESCE(
          (SELECT COUNT(*) FROM submissions s 
           WHERE s.user_id = CASE WHEN f.requester_id = $1 THEN u2.id ELSE u1.id END 
           AND s.verdict = 'Accepted'), 0
        ) AS solved_count,
        0 AS current_streak,
        false AS is_online
       FROM friendships f
       JOIN users u1 ON u1.id = f.requester_id
       JOIN users u2 ON u2.id = f.addressee_id
       WHERE (f.requester_id = $1 OR f.addressee_id = $1) 
       AND f.status = 'accepted'
       ORDER BY solved_count DESC, username
       LIMIT 50`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error('GET /api/friends/leaderboard error:', err);
    res.status(500).json({ error: 'Failed to load leaderboard' });
  }
});

// ─── GET /api/friends/search/users (search for users to add) ────────────────
router.get('/search/users', async (req, res) => {
  try {
    const query = req.query.q;
    if (!query || typeof query !== 'string' || query.trim().length === 0) {
      return res.json({ users: [] });
    }

    const result = await dbPool.query(
      `SELECT 
        u.id,
        u.username,
        u.avatar_url,
        COALESCE(
          (SELECT COUNT(*) FROM submissions s 
           WHERE s.user_id = u.id AND s.verdict = 'Accepted'), 0
        ) AS solved_count,
        EXISTS(
          SELECT 1 FROM friendships f 
          WHERE ((f.requester_id = $1 AND f.addressee_id = u.id) 
              OR (f.requester_id = u.id AND f.addressee_id = $1))
          AND f.status = 'accepted'
        ) AS is_friend,
        EXISTS(
          SELECT 1 FROM friendships f 
          WHERE f.requester_id = $1 AND f.addressee_id = u.id 
          AND f.status = 'pending'
        ) AS request_sent
       FROM users u
       WHERE LOWER(u.username) LIKE LOWER($2) 
       AND u.id != $1
       ORDER BY u.username
       LIMIT 20`,
      [req.user.id, `%${query.trim()}%`]
    );
    res.json({ users: result.rows });
  } catch (err) {
    console.error('GET /api/friends/search/users error:', err);
    res.status(500).json({ error: 'Failed to search users' });
  }
});

export default router;
