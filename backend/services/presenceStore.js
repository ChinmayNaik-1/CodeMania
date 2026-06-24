// In-memory presence store (replaces Redis-based presence to avoid Upstash quota usage).
// Tracks online users with a TTL, refreshed via socket heartbeats.

const onlineUsers = new Map(); // userId -> expiresAtEpochMs

const DEFAULT_TTL_MS = 300 * 1000; // 5 minutes, mirrors previous `EX 300`

export function markOnline(userId, ttlMs = DEFAULT_TTL_MS) {
  if (userId == null) return;
  onlineUsers.set(String(userId), Date.now() + ttlMs);
}

export function markOffline(userId) {
  if (userId == null) return;
  onlineUsers.delete(String(userId));
}

export function isOnline(userId) {
  if (userId == null) return false;
  const expiresAt = onlineUsers.get(String(userId));
  if (!expiresAt) return false;
  if (expiresAt < Date.now()) {
    onlineUsers.delete(String(userId));
    return false;
  }
  return true;
}

// Periodically purge expired entries so the map doesn't grow unbounded.
const PURGE_INTERVAL_MS = 60 * 1000;
const purgeTimer = setInterval(() => {
  const now = Date.now();
  for (const [userId, expiresAt] of onlineUsers.entries()) {
    if (expiresAt < now) onlineUsers.delete(userId);
  }
}, PURGE_INTERVAL_MS);

// Don't keep the Node process alive solely for this timer.
if (purgeTimer.unref) purgeTimer.unref();
