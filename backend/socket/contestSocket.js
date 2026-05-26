import { getLeaderboard, publishContestEvent } from '../services/leaderboardService.js';

let contestIo = null;

export function getContestIo() {
  return contestIo;
}

export function initContestSocket(io) {
  contestIo = io;
  io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    if (socket.data.userId) {
      socket.join(`user:${socket.data.userId}`);
    }

    socket.on('join_contest', async (data) => {
      try {
        const { contestId, teamId, userId } = data;
        const room = `contest:${contestId}:team:${teamId}`;

        socket.join(room);
        socket.join(`contest:${contestId}`);

        socket.emit('contest_joined', {
          contestId,
          teamId,
          userId,
          timestamp: new Date(),
        });

        io.to(`contest:${contestId}`).emit('team_joined', {
          teamId,
          userId,
          timestamp: new Date(),
        });

        console.log(`User ${userId} joined contest ${contestId} team ${teamId}`);
      } catch (error) {
        console.error('Error joining contest:', error);
        socket.emit('error', { message: 'Failed to join contest' });
      }
    });

    socket.on('leave_contest', (data) => {
      try {
        const { contestId, teamId } = data;
        const room = `contest:${contestId}:team:${teamId}`;
        socket.leave(room);
        socket.leave(`contest:${contestId}`);
        console.log(`User left contest ${contestId} team ${teamId}`);
      } catch (error) {
        console.error('Error leaving contest:', error);
      }
    });

    socket.on('disconnect', () => {
      console.log('User disconnected:', socket.id);
    });
  });
}

export function emitSubmissionResult(io, contestId, submissionData) {
  const { userId, username, problemId, problemTitle, verdict, passedCases, totalCases, teamId, newTeamScore } = submissionData;

  io.to(`contest:${contestId}`).emit('submission_result', {
    userId,
    username,
    problemId,
    problemTitle,
    verdict,
    passedCases,
    totalCases,
    teamId,
    newTeamScore,
    timestamp: new Date(),
  });
}

export async function emitLeaderboardUpdate(io, contestId, dbPool) {
  try {
    const leaderboardKey = `leaderboard:${contestId}`;
    const leaderboard = await getLeaderboard(contestId);

    const teamsData = await Promise.all(
      leaderboard.map(async (item) => {
        const teamResult = await dbPool.query(
          'SELECT name FROM teams WHERE id = $1',
          [item.teamId]
        );

        const membersResult = await dbPool.query(
          'SELECT u.username FROM team_members tm JOIN users u ON tm.user_id = u.id WHERE tm.team_id = $1',
          [item.teamId]
        );

        return {
          teamId: item.teamId,
          teamName: teamResult.rows[0]?.name || 'Unknown Team',
          score: item.score,
          solvedCount: 0, // Can be calculated from submissions if needed
          members: membersResult.rows.map((r) => r.username),
        };
      })
    );

    io.to(`contest:${contestId}`).emit('leaderboard_update', {
      teams: teamsData,
      timestamp: new Date(),
    });
  } catch (error) {
    console.error('Error emitting leaderboard update:', error);
  }
}

export function emitTeamFeedUpdate(io, contestId, feedData) {
  const { userId, username, problemId, problemTitle, verdict, timestamp } = feedData;

  io.to(`contest:${contestId}`).emit('team_feed_update', {
    userId,
    username,
    problemId,
    problemTitle,
    verdict,
    timestamp,
  });
}

export function emitUserSubmissionResult(io, userId, payload) {
  io.to(`user:${userId}`).emit('submission_result', payload);
}
