import { dbPool } from '../index.js';
import { getRedisClient } from './leaderboardService.js';
import { getContestIo } from '../socket/contestSocket.js';

export async function processContestSubmission({
  submissionId,
  userId,
  problemId,
  contestId,
  teamId,
  verdict,
  submittedAt,
}) {
  const contestResult = await dbPool.query(
    `SELECT id, starts_at, penalty_minutes
     FROM contests
     WHERE id = $1`,
    [contestId]
  );

  if (contestResult.rows.length === 0) {
    return { skipped: true };
  }

  const contest = contestResult.rows[0];

  const statusResult = await dbPool.query(
    `SELECT team_id, problem_id, contest_id, wrong_attempts, solved_at, penalty_minutes
     FROM team_problem_status
     WHERE team_id = $1 AND problem_id = $2
     LIMIT 1`,
    [teamId, problemId]
  );

  if (statusResult.rows.length === 0) {
    await dbPool.query(
      `INSERT INTO team_problem_status
       (team_id, problem_id, contest_id, wrong_attempts, solved_at, penalty_minutes)
       VALUES ($1, $2, $3, 0, NULL, 0)`,
      [teamId, problemId, contestId]
    );
  } else if (statusResult.rows[0].solved_at) {
    return { alreadySolved: true };
  }

  if (verdict !== 'Accepted' && verdict !== 'accepted') {
    await dbPool.query(
      `UPDATE team_problem_status
       SET wrong_attempts = wrong_attempts + 1
       WHERE team_id = $1 AND problem_id = $2`,
      [teamId, problemId]
    );
    return { penaltyAdded: false };
  }

  const currentStatusResult = await dbPool.query(
    `SELECT wrong_attempts, solved_at
     FROM team_problem_status
     WHERE team_id = $1 AND problem_id = $2
     LIMIT 1`,
    [teamId, problemId]
  );

  const currentStatus = currentStatusResult.rows[0] || { wrong_attempts: 0, solved_at: null };
  if (currentStatus.solved_at) {
    return { alreadySolved: true };
  }

  const submittedAtDate = submittedAt ? new Date(submittedAt) : new Date();
  const minutesElapsed = Math.floor((submittedAtDate - new Date(contest.starts_at)) / 60000);
  const penalty = minutesElapsed + (currentStatus.wrong_attempts * contest.penalty_minutes);

  await dbPool.query(
    `UPDATE team_problem_status
     SET solved_at = $1, penalty_minutes = $2
     WHERE team_id = $3 AND problem_id = $4`,
    [submittedAtDate, penalty, teamId, problemId]
  );

  await updateLeaderboard(contestId, teamId);

  return { solved: true, penalty };
}

export async function updateLeaderboard(contestId, teamId) {
  const scoreResult = await dbPool.query(
    `SELECT
       COUNT(*) FILTER (WHERE solved_at IS NOT NULL) AS problems_solved,
       COALESCE(SUM(penalty_minutes) FILTER (WHERE solved_at IS NOT NULL), 0) AS total_penalty
     FROM team_problem_status
     WHERE team_id = $1 AND contest_id = $2`,
    [teamId, contestId]
  );

  const problemsSolved = parseInt(scoreResult.rows[0]?.problems_solved || '0', 10);
  const totalPenalty = parseInt(scoreResult.rows[0]?.total_penalty || '0', 10);
  const score = (problemsSolved * 1000000) - totalPenalty;

  const redisClient = getRedisClient();
  if (redisClient) {
    await redisClient.zAdd(`leaderboard:${contestId}`, [
      { score, value: teamId.toString() },
    ]);
  }

  const io = getContestIo();
  if (io) {
    io.to(`contest:${contestId}`).emit('leaderboard_update', {
      teamId,
      problemsSolved,
      totalPenalty,
    });
  }

  return { problemsSolved, totalPenalty };
}

export async function getLeaderboard(contestId) {
  const redisClient = getRedisClient();
  if (!redisClient) {
    return [];
  }

  const scores = await redisClient.zRevRange(`leaderboard:${contestId}`, 0, 49, { withScores: true });
  const entries = [];

  for (let i = 0; i < scores.length; i += 2) {
    const teamId = parseInt(scores[i], 10);
    const score = Number(scores[i + 1]);
    const problemsSolved = Math.floor(score / 1000000);
    const totalPenalty = (problemsSolved * 1000000) - score;

    const teamResult = await dbPool.query(
      'SELECT name FROM teams WHERE id = $1',
      [teamId]
    );

    const membersResult = await dbPool.query(
      `SELECT u.username
       FROM team_members tm
       JOIN users u ON u.id = tm.user_id
       WHERE tm.team_id = $1
       ORDER BY tm.joined_at ASC`,
      [teamId]
    );

    entries.push({
      teamId,
      teamName: teamResult.rows[0]?.name || 'Unknown Team',
      members: membersResult.rows.map((row) => row.username),
      problemsSolved,
      totalPenalty,
    });
  }

  return entries.map((entry, index) => ({
    rank: index + 1,
    ...entry,
  }));
}
