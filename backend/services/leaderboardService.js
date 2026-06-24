import redis from 'redis';

// Redis is OPT-IN. Leave REDIS_ENABLED unset (or "false") to run entirely without
// Upstash/Redis. This prevents accidental quota usage: all leaderboard reads fall
// back to PostgreSQL (see contestService.getLeaderboard) and presence uses an
// in-memory store. Only set REDIS_ENABLED=true when you have quota to spare.
const REDIS_ENABLED = String(process.env.REDIS_ENABLED || '').toLowerCase() === 'true';

let redisClient = null;
let redisReady = false;

if (REDIS_ENABLED) {
  redisClient = redis.createClient({
    url: process.env.REDIS_URL || 'redis://localhost:6379',
  });
  redisClient.on('error', (err) => console.error('Redis error:', err));
  redisClient.on('connect', () => console.log('Redis connected'));
}

export async function initRedis() {
  if (!REDIS_ENABLED) {
    console.log('ℹ️  Redis disabled (REDIS_ENABLED not set). Using PostgreSQL + in-memory fallbacks.');
    return;
  }
  try {
    await redisClient.connect();
    redisReady = true;
  } catch (error) {
    console.error('Failed to connect to Redis:', error);
    throw error;
  }
}

export async function updateTeamScore(contestId, teamId, points) {
  if (!redisReady) return;
  try {
    const leaderboardKey = `leaderboard:${contestId}`;
    await redisClient.zIncrBy(leaderboardKey, points, teamId.toString());
    await redisClient.expire(leaderboardKey, 30 * 24 * 60 * 60); // 30 days
  } catch (error) {
    console.error('Error updating team score:', error);
  }
}

export async function getLeaderboard(contestId, limit = 100) {
  if (!redisReady) return [];
  try {
    const leaderboardKey = `leaderboard:${contestId}`;
    const scores = await redisClient.zRevRange(leaderboardKey, 0, limit - 1, { withScores: true });

    const result = [];
    for (let i = 0; i < scores.length; i += 2) {
      result.push({
        teamId: parseInt(scores[i]),
        score: scores[i + 1],
      });
    }
    return result;
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    return [];
  }
}

export async function publishContestEvent(contestId, event) {
  if (!redisReady) return;
  try {
    const channel = `codemania:contest:${contestId}`;
    await redisClient.publish(channel, JSON.stringify(event));
  } catch (error) {
    console.error('Error publishing contest event:', error);
  }
}

export async function incrementSolvedCount(contestId, teamId) {
  if (!redisReady) return;
  try {
    const key = `team:${contestId}:${teamId}:solved`;
    await redisClient.incr(key);
    await redisClient.expire(key, 30 * 24 * 60 * 60);
  } catch (error) {
    console.error('Error incrementing solved count:', error);
  }
}

export async function getSolvedCount(contestId, teamId) {
  if (!redisReady) return 0;
  try {
    const key = `team:${contestId}:${teamId}:solved`;
    const count = await redisClient.get(key);
    return count ? parseInt(count) : 0;
  } catch (error) {
    console.error('Error getting solved count:', error);
    return 0;
  }
}

// Returns the live Redis client only when connected, otherwise null.
// Callers MUST guard with `if (redis)` so they fall back to the database.
export function getRedisClient() {
  return redisReady ? redisClient : null;
}
