import { markOnline, markOffline } from '../services/presenceStore.js';

export function initPresenceSocket(io) {
  io.on('connection', (socket) => {
    const userId = socket.data?.userId;
    if (!userId) return;

    markOnline(userId);

    socket.on('disconnect', () => {
      markOffline(userId);
    });

    socket.on('heartbeat', () => {
      markOnline(userId);
    });
  });
}
