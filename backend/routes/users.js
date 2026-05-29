import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { dbPool } from '../index.js';

const router = Router();
router.use(authMiddleware);

// ─── GET /api/users/ping ─────────────────────────────────────────────────────
router.get('/ping', (req, res) => {
  res.json({ ok: true, userId: req.user.id, username: req.user.username });
});

// ─── GET /api/users/search?q=:query ──────────────────────────────────────────
router.get('/search', async (req, res) => {
  const q = (req.query.q || '').toString().trim();
  if (q.length < 1) return res.json({ users: [] });

  try {
    const result = await dbPool.query(
      `SELECT
         u.id,
         u.username,
         u.avatar_url,
         (SELECT COUNT(*) FROM submissions s
          WHERE s.user_id = u.id
            AND (s.verdict = 'accepted' OR s.status = 'Accepted')) AS solved_count,
         (SELECT 1 FROM friendships f
          WHERE (f.requester_id = $2 AND f.addressee_id = u.id OR f.requester_id = u.id AND f.addressee_id = $2)
            AND f.status = 'accepted' LIMIT 1) AS is_friend,
         (SELECT 1 FROM friendships f
          WHERE f.requester_id = $2 AND f.addressee_id = u.id
            AND f.status = 'pending' LIMIT 1) AS request_sent
       FROM users u
       WHERE u.username ILIKE $1
         AND u.id != $2
       ORDER BY u.username ASC
       LIMIT 20`,
      [`%${q}%`, req.user.id]
    );

    res.json({
      users: result.rows.map(r => ({
        id: r.id,
        username: r.username,
        avatar_url: r.avatar_url,
        solved_count: parseInt(r.solved_count, 10) || 0,
        is_friend: !!r.is_friend,
        request_sent: !!r.request_sent,
      })),
    });
  } catch (err) {
    console.error('GET /api/users/search error:', err);
    res.status(500).json({ error: err.message });
  }
});

export default router;
