import { dbPool } from '../index.js';
import { getRedisClient } from './leaderboardService.js';

// ─── recordContestSubmission ──────────────────────────────────────────────────

/**
 * Called from submissionQueue after judging resolves.
 * Records the submission and, if Accepted, awards points.
 */
export async function recordContestSubmission(
  contestId, problemId, userId, teamId, verdict, language, code, io
) {
  // 1. Fetch contest type
  const contestResult = await dbPool.query(
    `SELECT contest_type FROM contests WHERE id = $1`,
    [contestId]
  );
  if (contestResult.rows.length === 0) return;

  const contestType = contestResult.rows[0].contest_type;
  const isTeam = contestType === 'team' && teamId != null;

  // 2. Insert into contest_submissions
  const insertResult = await dbPool.query(
    `INSERT INTO contest_submissions
       (contest_id, problem_id, user_id, team_id, language, code, verdict, score_awarded, first_solve)
     VALUES ($1, $2, $3, $4, $5, $6, $7, 0, false)
     RETURNING id`,
    [contestId, problemId, userId, teamId ?? null, language, code, verdict]
  );
  const submissionId = insertResult.rows[0].id;

  // 3. Only score if Accepted
  const accepted = verdict === 'Accepted' || verdict === 'accepted';
  if (!accepted) return;

  // 4. Get points for this problem
  const pointsResult = await dbPool.query(
    `SELECT points FROM contest_problems WHERE contest_id = $1 AND problem_id = $2`,
    [contestId, problemId]
  );
  if (pointsResult.rows.length === 0) return;
  const points = pointsResult.rows[0].points;

  if (isTeam) {
    // ── Team path ─────────────────────────────────────────────────────────────
    // Check if team already solved this problem
    const solveCheck = await dbPool.query(
      `SELECT 1 FROM contest_problem_solves
       WHERE contest_id = $1 AND problem_id = $2 AND team_id = $3`,
      [contestId, problemId, teamId]
    );
    if (solveCheck.rows.length > 0) {
      // Already solved by team — no additional score
      return;
    }

    // First solve by team
    const client = await dbPool.connect();
    try {
      await client.query('BEGIN');

      // Record solve
      await client.query(
        `INSERT INTO contest_problem_solves
           (contest_id, problem_id, team_id, user_id, score_awarded)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT DO NOTHING`,
        [contestId, problemId, teamId, userId, points]
      );

      // Mark submission as first_solve
      await client.query(
        `UPDATE contest_submissions SET first_solve = true, score_awarded = $1
         WHERE id = $2`,
        [points, submissionId]
      );

      // Upsert leaderboard (team row)
      const lbResult = await client.query(
        `INSERT INTO contest_leaderboard
           (contest_id, team_id, total_score, problems_solved, last_accepted_at)
         VALUES ($1, $2, $3, 1, NOW())
         ON CONFLICT (contest_id, team_id) WHERE user_id IS NULL
         DO UPDATE SET
           total_score = contest_leaderboard.total_score + $3,
           problems_solved = contest_leaderboard.problems_solved + 1,
           last_accepted_at = NOW()
         RETURNING *`,
        [contestId, teamId, points]
      );

      await client.query('COMMIT');

      // Emit leaderboard_update
      if (io && lbResult.rows.length > 0) {
        io.to(`contest:${contestId}`).emit('leaderboard_update', lbResult.rows[0]);
      }

      // Invalidate Redis leaderboard cache
      const redis = getRedisClient();
      if (redis) {
        await redis.del(`leaderboard:${contestId}`).catch(() => {});
      }
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } else {
    // ── Solo path ─────────────────────────────────────────────────────────────
    const solveCheck = await dbPool.query(
      `SELECT 1 FROM contest_problem_solves
       WHERE contest_id = $1 AND problem_id = $2 AND user_id = $3 AND team_id IS NULL`,
      [contestId, problemId, userId]
    );
    if (solveCheck.rows.length > 0) return;

    const client = await dbPool.connect();
    try {
      await client.query('BEGIN');

      await client.query(
        `INSERT INTO contest_problem_solves
           (contest_id, problem_id, user_id, team_id, score_awarded)
         VALUES ($1, $2, $3, NULL, $4)
         ON CONFLICT DO NOTHING`,
        [contestId, problemId, userId, points]
      );

      await client.query(
        `UPDATE contest_submissions SET first_solve = true, score_awarded = $1
         WHERE id = $2`,
        [points, submissionId]
      );

      const lbResult = await client.query(
        `INSERT INTO contest_leaderboard
           (contest_id, user_id, total_score, problems_solved, last_accepted_at)
         VALUES ($1, $2, $3, 1, NOW())
         ON CONFLICT (contest_id, user_id) WHERE team_id IS NULL
         DO UPDATE SET
           total_score = contest_leaderboard.total_score + $3,
           problems_solved = contest_leaderboard.problems_solved + 1,
           last_accepted_at = NOW()
         RETURNING *`,
        [contestId, userId, points]
      );

      await client.query('COMMIT');

      if (io && lbResult.rows.length > 0) {
        io.to(`contest:${contestId}`).emit('leaderboard_update', lbResult.rows[0]);
      }

      const redis = getRedisClient();
      if (redis) {
        await redis.del(`leaderboard:${contestId}`).catch(() => {});
      }
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }
}

// ─── getLeaderboard ───────────────────────────────────────────────────────────

export async function getLeaderboard(contestId) {
  // Check Redis cache
  const redis = getRedisClient();
  const cacheKey = `leaderboard:${contestId}`;
  if (redis) {
    try {
      const cached = await redis.get(cacheKey);
      if (cached) return JSON.parse(cached);
    } catch (_) {}
  }

  // Determine contest type
  const contestResult = await dbPool.query(
    `SELECT contest_type FROM contests WHERE id = $1`,
    [contestId]
  );
  if (contestResult.rows.length === 0) return [];

  const contestType = contestResult.rows[0].contest_type;
  let data;

  if (contestType === 'team') {
    const result = await dbPool.query(
      `SELECT
         cl.team_id,
         ct.name AS team_name,
         cl.total_score,
         cl.problems_solved,
         cl.last_accepted_at,
         COALESCE(
           json_agg(
             json_build_object(
               'user_id', ctm.user_id,
               'username', u.username,
               'avatar_url', u.avatar_url,
               'problems_solved', (
                 SELECT COUNT(*) FROM contest_submissions cs
                 WHERE cs.contest_id = $1
                   AND cs.team_id = cl.team_id
                   AND cs.user_id = ctm.user_id
                   AND cs.verdict IN ('Accepted','accepted')
                   AND cs.first_solve = true
               ),
               'score_contributed', (
                 SELECT COALESCE(SUM(score_awarded), 0)
                 FROM contest_submissions cs
                 WHERE cs.contest_id = $1
                   AND cs.team_id = cl.team_id
                   AND cs.user_id = ctm.user_id
                   AND cs.first_solve = true
               )
             )
           ) FILTER (WHERE ctm.user_id IS NOT NULL),
           '[]'::json
         ) AS members
       FROM contest_leaderboard cl
       JOIN contest_teams ct ON ct.id = cl.team_id
       LEFT JOIN contest_team_members ctm ON ctm.team_id = cl.team_id
       LEFT JOIN users u ON u.id = ctm.user_id
       WHERE cl.contest_id = $1 AND cl.user_id IS NULL
       GROUP BY cl.team_id, ct.name, cl.total_score, cl.problems_solved, cl.last_accepted_at
       ORDER BY cl.total_score DESC, cl.last_accepted_at ASC NULLS LAST`,
      [contestId]
    );
    data = result.rows;
  } else {
    const result = await dbPool.query(
      `SELECT
         cl.user_id,
         u.username,
         u.avatar_url,
         cl.total_score,
         cl.problems_solved,
         cl.last_accepted_at
       FROM contest_leaderboard cl
       JOIN users u ON u.id = cl.user_id
       WHERE cl.contest_id = $1 AND cl.team_id IS NULL
       ORDER BY cl.total_score DESC, cl.last_accepted_at ASC NULLS LAST`,
      [contestId]
    );
    data = result.rows;
  }

  // Cache for 10 seconds
  if (redis) {
    try {
      await redis.set(cacheKey, JSON.stringify(data), { EX: 10 });
    } catch (_) {}
  }

  return data;
}
