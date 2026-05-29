import Bull from 'bull';
import { applyContestScoring, judgeSubmission } from './judgeService.js';
import { publishContestEvent } from './leaderboardService.js';
import {
  emitSubmissionResult,
  emitTeamFeedUpdate,
  emitUserSubmissionResult,
} from '../socket/contestSocket.js';
import { recordActivity } from './profileService.js';


const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
const queueName = 'submission-queue';

function getQueueRedisConfig() {
  const parsed = new URL(redisUrl);
  return {
    host: parsed.hostname,
    port: parseInt(parsed.port || '6379', 10),
    password: parsed.password || undefined,
    db: parsed.pathname && parsed.pathname !== '/' ? parseInt(parsed.pathname.slice(1), 10) : 0,
  };
}

export const submissionQueue = new Bull(queueName, {
  redis: getQueueRedisConfig(),
  defaultJobOptions: {
    removeOnComplete: true,
    removeOnFail: false,
    attempts: 1,
  },
});

let queueInitialized = false;

export function initSubmissionQueue(io, dbPool) {
  if (queueInitialized) {
    return;
  }

  submissionQueue.process(2, async (job) => {
    const {
      submissionId,
      userId,
      username,
      problemId,
      contestId,
      teamId,
      language,
      version,
      code,
    } = job.data;

    const submissionResult = await judgeSubmission(code, language, version, problemId, dbPool);

    await recordActivity(userId, submissionResult.verdict, problemId);


    await dbPool.query(
      `UPDATE submissions
       SET verdict = $1,
           status = $2,
           passed_cases = $3,
           total_cases = $4,
           time_ms = $5,
           runtime_ms = $6,
           memory_kb = $7,
           error_message = $8,
           stderr = $9,
           error_line = $10
       WHERE id = $11`,
      [
        submissionResult.verdict,
        submissionResult.status,
        submissionResult.passed,
        submissionResult.total,
        submissionResult.time_ms,
        submissionResult.time_ms,
        submissionResult.memory_kb,
        submissionResult.errorMessage || null,
        submissionResult.stderr || null,
        submissionResult.errorLine || null,
        submissionId,
      ]
    );

    const submissionRow = await dbPool.query(
      `SELECT id, user_id, problem_id, contest_id, team_id, created_at
       FROM submissions
       WHERE id = $1`,
      [submissionId]
    );

    if (submissionRow.rows.length > 0) {
      await applyContestScoring({
        submission: submissionRow.rows[0],
        finalVerdict: submissionResult.verdict,
      });
    }

    const userPayload = {
      submissionId,
      userId,
      problemId,
      verdict: submissionResult.verdict,
      passed: submissionResult.passed,
      total: submissionResult.total,
      errorMessage: submissionResult.errorMessage || null,
      failedCase: submissionResult.failedCase || null,
      timeMs: submissionResult.time_ms,
      memoryKb: submissionResult.memory_kb,
    };

    emitUserSubmissionResult(io, userId, userPayload);

    if (submissionResult.verdict === 'accepted' && contestId && teamId) {
      const problemTitleResult = await dbPool.query('SELECT title FROM problems WHERE id = $1', [problemId]);

      const submissionData = {
        submissionId,
        userId,
        username,
        problemId,
        problemTitle: problemTitleResult.rows[0]?.title || 'Unknown',
        verdict: submissionResult.verdict,
        passedCases: submissionResult.passed,
        totalCases: submissionResult.total,
        teamId,
      };

      emitSubmissionResult(io, contestId, submissionData);
      emitTeamFeedUpdate(io, contestId, submissionData);
      await publishContestEvent(contestId, { type: 'submission', data: submissionData });
    }

    return userPayload;
  });

  submissionQueue.on('failed', async (job, error) => {
    const { submissionId, userId } = job.data;

    try {
      await dbPool.query(
        `UPDATE submissions
         SET verdict = $1,
             status = $2,
             passed_cases = 0,
             total_cases = 0,
             time_ms = 0,
             runtime_ms = 0,
             memory_kb = 0,
             error_message = $3,
             stderr = $4,
             error_line = NULL
         WHERE id = $5`,
        [
          'runtime_error',
          'Runtime Error',
          error?.message || 'Queue processing failed',
          error?.stack || null,
          submissionId,
        ]
      );

      emitUserSubmissionResult(io, userId, {
        submissionId,
        userId,
        verdict: 'runtime_error',
        passed: 0,
        total: 0,
        errorMessage: error?.message || 'Queue processing failed',
        failedCase: null,
        timeMs: 0,
        memoryKb: 0,
      });
    } catch (updateError) {
      console.error('Failed to update submission after queue failure:', updateError);
    }

    console.error('Submission queue job failed:', error);
  });

  queueInitialized = true;
}
