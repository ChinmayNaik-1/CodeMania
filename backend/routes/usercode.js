import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { dbPool } from '../index.js';

const router = Router();

router.get('/:problemId', authMiddleware, async (req, res) => {
  try {
    const problemId = parseInt(req.params.problemId, 10);
    const language = (req.query.language || '').toString();

    if (Number.isNaN(problemId) || !language) {
      return res.status(400).json({ error: 'problemId and language are required', code: 'INVALID_INPUT' });
    }

    const result = await dbPool.query(
      `SELECT code, updated_at
       FROM user_code
       WHERE user_id = $1 AND problem_id = $2 AND language = $3
       LIMIT 1`,
      [req.user.id, problemId, language]
    );

    if (result.rows.length === 0) {
      return res.json({ code: null });
    }

    return res.json({
      code: result.rows[0].code,
      updated_at: result.rows[0].updated_at,
    });
  } catch (error) {
    console.error('Fetch user code error:', error);
    return res.status(500).json({ error: 'Failed to fetch saved code', code: 'USER_CODE_FETCH_ERROR' });
  }
});

router.post('/:problemId', authMiddleware, async (req, res) => {
  try {
    const problemId = parseInt(req.params.problemId, 10);
    const { language, code } = req.body;

    if (Number.isNaN(problemId) || !language || typeof code !== 'string') {
      return res.status(400).json({ error: 'problemId, language and code are required', code: 'INVALID_INPUT' });
    }

    await dbPool.query(
      `INSERT INTO user_code (user_id, problem_id, language, code)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, problem_id, language)
       DO UPDATE SET code = EXCLUDED.code, updated_at = NOW()`,
      [req.user.id, problemId, language, code]
    );

    return res.json({ success: true });
  } catch (error) {
    console.error('Save user code error:', error);
    return res.status(500).json({ error: 'Failed to save code', code: 'USER_CODE_SAVE_ERROR' });
  }
});

export default router;
