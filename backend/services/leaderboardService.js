import redis from 'redis';

const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
});

redisClient.on('error', (err) => console.error('Redis error:', err));
redisClient.on('connect', () => console.log('Redis connected'));

export async function initRedis() {
  try {
    await redisClient.connect();
  } catch (error) {
    console.error('Failed to connect to Redis:', error);
    throw error;
  }
}

export async function updateTeamScore(contestId, teamId, points) {
  try {
    const leaderboardKey = `leaderboard:${contestId}`;
    await redisClient.zIncrBy(leaderboardKey, points, teamId.toString());
    await redisClient.expire(leaderboardKey, 30 * 24 * 60 * 60); // 30 days
  } catch (error) {
    console.error('Error updating team score:', error);
  }
}

export async function getLeaderboard(contestId, limit = 100) {
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
  try {
    const channel = `codemania:contest:${contestId}`;
    await redisClient.publish(channel, JSON.stringify(event));
  } catch (error) {
    console.error('Error publishing contest event:', error);
  }
}

export async function incrementSolvedCount(contestId, teamId) {
  try {
    const key = `team:${contestId}:${teamId}:solved`;
    await redisClient.incr(key);
    await redisClient.expire(key, 30 * 24 * 60 * 60);
  } catch (error) {
    console.error('Error incrementing solved count:', error);
  }
}

export async function getSolvedCount(contestId, teamId) {
  try {
    const key = `team:${contestId}:${teamId}:solved`;
    const count = await redisClient.get(key);
    return count ? parseInt(count) : 0;
  } catch (error) {
    console.error('Error getting solved count:', error);
    return 0;
  }
}

export function getRedisClient() {
  return redisClient;
}
