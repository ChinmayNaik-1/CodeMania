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

// ─── GET /api/users/:userId/submission-heatmap ───────────────────────────────
router.get('/:userId/submission-heatmap', async (req, res) => {
  const userId = parseInt(req.params.userId, 10);
  if (req.user.id !== userId) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  try {
    const result = await dbPool.query(
      `SELECT
         DATE(created_at AT TIME ZONE 'UTC') AS day,
         COUNT(*) AS submission_count
       FROM submissions
       WHERE
         user_id = $1
         AND created_at >= NOW() - INTERVAL '365 days'
       GROUP BY day
       ORDER BY day;`,
      [userId]
    );

    const heatmap = {};
    let totalSubmissions = 0;
    const totalActiveDays = result.rows.length;

    for (const row of result.rows) {
      const d = new Date(row.day);
      const key = d.toISOString().split('T')[0];
      const count = parseInt(row.submission_count, 10);
      heatmap[key] = count;
      totalSubmissions += count;
    }

    let maxStreak = 0;
    const keys = Object.keys(heatmap).sort();
    if (keys.length > 0) {
      let currentRun = 1;
      maxStreak = 1;
      for (let i = 1; i < keys.length; i++) {
        const prev = new Date(keys[i - 1]);
        const curr = new Date(keys[i]);
        const diffDays = Math.round((curr - prev) / (1000 * 60 * 60 * 24));
        if (diffDays === 1) {
          currentRun++;
          if (currentRun > maxStreak) maxStreak = currentRun;
        } else {
          currentRun = 1;
        }
      }
    }

    res.json({
      totalSubmissions,
      totalActiveDays,
      maxStreak,
      heatmap
    });
  } catch (err) {
    console.error('GET /api/users/:userId/submission-heatmap error:', err);
    res.status(500).json({ error: err.message });
  }
});

export default router;
