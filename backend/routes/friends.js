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

export default router;
