import { getRedisClient } from '../services/leaderboardService.js';

export function initPresenceSocket(io) {
  io.on('connection', async (socket) => {
    const userId = socket.data?.userId;
    if (!userId) return;

    const redis = getRedisClient();
    await redis.set(`online:${userId}`, '1', 'EX', 300);

    socket.on('disconnect', async () => {
      await redis.del(`online:${userId}`);
    });

    socket.on('heartbeat', async () => {
      await redis.set(`online:${userId}`, '1', 'EX', 300);
    });
  });
}
