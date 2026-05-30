import { dbPool } from '../index.js';

/**
 * Checks contest timestamps and updates status if needed.
 * Returns the (possibly updated) status string.
 */
export async function checkAndUpdateContestStatus(contestId) {
  const result = await dbPool.query(
    `SELECT status, start_time, end_time FROM contests WHERE id = $1`,
    [contestId]
  );

  if (result.rows.length === 0) return null;

  const { status, start_time, end_time } = result.rows[0];
  const now = new Date();

  if (status === 'upcoming' && now >= new Date(start_time)) {
    await dbPool.query(
      `UPDATE contests SET status = 'live' WHERE id = $1 AND status = 'upcoming'`,
      [contestId]
    );
    return 'live';
  }

  if (status === 'live' && now >= new Date(end_time)) {
    await dbPool.query(
      `UPDATE contests SET status = 'ended' WHERE id = $1 AND status = 'live'`,
      [contestId]
    );
    return 'ended';
  }

  return status;
}

/**
 * Batch-updates all upcoming/live contests based on time.
 * Called on the contests list endpoint to keep statuses current.
 */
export async function refreshAllContestStatuses() {
  // upcoming → live
  await dbPool.query(
    `UPDATE contests SET status = 'live'
     WHERE status = 'upcoming' AND start_time <= NOW()`
  );
  // live → ended
  await dbPool.query(
    `UPDATE contests SET status = 'ended'
     WHERE status = 'live' AND end_time <= NOW()`
  );
}
