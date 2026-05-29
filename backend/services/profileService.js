import { dbPool } from '../index.js';

export async function recordActivity(userId, submissionVerdict, problemId) {
  try {
    // 1. Update user_daily_activity
    await dbPool.query(
      `INSERT INTO user_daily_activity (user_id, activity_date, submission_count)
       VALUES ($1, CURRENT_DATE, 1)
       ON CONFLICT (user_id, activity_date) DO UPDATE
       SET submission_count = user_daily_activity.submission_count + 1`,
      [userId]
    );

    // 2. Update user_streaks
    const streakRes = await dbPool.query(
      `SELECT current_streak, max_streak, last_active_date FROM user_streaks WHERE user_id = $1`,
      [userId]
    );

    let currentStreak = 1;
    let maxStreak = 1;

    if (streakRes.rows.length > 0) {
      const streak = streakRes.rows[0];
      const lastActive = streak.last_active_date;
      
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);

      let lastDate = null;
      if (lastActive) {
        lastDate = new Date(lastActive);
        lastDate.setHours(0, 0, 0, 0);
      }

      currentStreak = streak.current_streak;
      maxStreak = streak.max_streak;

      if (lastDate && lastDate.getTime() === yesterday.getTime()) {
        currentStreak++;
      } else if (lastDate && lastDate.getTime() === today.getTime()) {
        // no change
      } else {
        currentStreak = 1;
      }

      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }

      await dbPool.query(
        `UPDATE user_streaks
         SET current_streak = $1, max_streak = $2, last_active_date = CURRENT_DATE
         WHERE user_id = $3`,
        [currentStreak, maxStreak, userId]
      );
    } else {
      await dbPool.query(
        `INSERT INTO user_streaks (user_id, current_streak, max_streak, last_active_date)
         VALUES ($1, $2, $3, CURRENT_DATE)`,
        [userId, currentStreak, maxStreak]
      );
    }

    // 3. Update activity feed if accepted
    if (submissionVerdict === 'accepted' || submissionVerdict === 'Accepted') {
      await dbPool.query(
        `INSERT INTO user_activity_feed (user_id, activity_type, problem_id, meta)
         VALUES ($1, 'solved', $2, '{}')`,
        [userId, problemId]
      );
    }
  } catch (err) {
    console.error('Error recording activity:', err);
  }
}

export async function getProfileData(targetUserId, requestingUserId) {
  try {
    const [
      basicInfoRes,
      solvedStatsRes,
      langRes,
      heatmapRes,
      streakRes,
      contestRes,
      recentRes,
      friendStatusRes,
      friendsCountRes,
      totalProblemsRes
    ] = await Promise.all([
      dbPool.query(
        `SELECT id, username, avatar_url, bio, global_rank, created_at
         FROM users WHERE id = $1`,
        [targetUserId]
      ),
      dbPool.query(
        `SELECT p.difficulty, COUNT(DISTINCT s.problem_id) as count
         FROM submissions s
         JOIN problems p ON s.problem_id = p.id
         WHERE s.user_id = $1 AND (s.verdict = 'accepted' OR s.verdict = 'Accepted')
         GROUP BY p.difficulty`,
        [targetUserId]
      ),
      dbPool.query(
        `SELECT language, COUNT(DISTINCT problem_id) as problems_solved
         FROM submissions
         WHERE user_id = $1 AND (verdict = 'accepted' OR verdict = 'Accepted')
         GROUP BY language
         ORDER BY problems_solved DESC`,
        [targetUserId]
      ),
      dbPool.query(
        `SELECT activity_date as date, submission_count as count
         FROM user_daily_activity
         WHERE user_id = $1
           AND activity_date >= CURRENT_DATE - INTERVAL '365 days'
         ORDER BY activity_date`,
        [targetUserId]
      ),
      dbPool.query(
        `SELECT current_streak, max_streak, last_active_date
         FROM user_streaks WHERE user_id = $1`,
        [targetUserId]
      ),
      dbPool.query(
        `SELECT uch.rank, uch.score, uch.rating_after, uch.participated_at,
                c.title as contest_title
         FROM user_contest_history uch
         JOIN contests c ON uch.contest_id = c.id
         WHERE uch.user_id = $1
         ORDER BY uch.participated_at ASC`,
        [targetUserId]
      ),
      dbPool.query(
        `SELECT DISTINCT ON (s.problem_id)
           s.id, s.problem_id, p.title, s.language, s.created_at as solved_at
         FROM submissions s
         JOIN problems p ON s.problem_id = p.id
         WHERE s.user_id = $1 AND (s.verdict = 'accepted' OR s.verdict = 'Accepted')
         ORDER BY s.problem_id, s.created_at DESC
         LIMIT 10`,
        [targetUserId]
      ),
      requestingUserId && requestingUserId !== targetUserId
        ? dbPool.query(
            `SELECT status, requester_id
             FROM friendships
             WHERE (requester_id = $1 AND addressee_id = $2)
                OR (requester_id = $2 AND addressee_id = $1)`,
            [requestingUserId, targetUserId]
          )
        : Promise.resolve({ rows: [] }),
      dbPool.query(
        `SELECT COUNT(*) as count FROM friendships
         WHERE (requester_id = $1 OR addressee_id = $1)
           AND status = 'accepted'`,
        [targetUserId]
      ),
      dbPool.query(`SELECT COUNT(*) as count FROM problems`)
    ]);

    if (basicInfoRes.rows.length === 0) {
      return null;
    }

    const user = basicInfoRes.rows[0];

    const stats = {
      total_solved: 0,
      easy_solved: 0,
      medium_solved: 0,
      hard_solved: 0,
      total_problems: parseInt(totalProblemsRes.rows[0].count, 10),
    };

    solvedStatsRes.rows.forEach(r => {
      const count = parseInt(r.count, 10);
      stats.total_solved += count;
      if (r.difficulty === 'easy') stats.easy_solved = count;
      else if (r.difficulty === 'medium') stats.medium_solved = count;
      else if (r.difficulty === 'hard') stats.hard_solved = count;
    });

    let friendshipStatus = null;
    if (requestingUserId && requestingUserId !== targetUserId && friendStatusRes.rows.length > 0) {
      const f = friendStatusRes.rows[0];
      if (f.status === 'accepted') {
        friendshipStatus = 'accepted';
      } else if (f.status === 'pending') {
        if (f.requester_id == requestingUserId) {
          friendshipStatus = 'pending_sent';
        } else {
          friendshipStatus = 'pending_received';
        }
      }
    }

    return {
      user: user,
      stats: stats,
      languages: langRes.rows.map(r => ({ language: r.language, problems_solved: parseInt(r.problems_solved, 10) })),
      heatmap: heatmapRes.rows.map(r => ({ date: r.date, count: parseInt(r.count, 10) })),
      streak: streakRes.rows.length > 0 ? {
        current_streak: streakRes.rows[0].current_streak,
        max_streak: streakRes.rows[0].max_streak
      } : { current_streak: 0, max_streak: 0 },
      contest_history: contestRes.rows,
      recent_ac: recentRes.rows,
      friends_count: parseInt(friendsCountRes.rows[0].count, 10),
      friendship_status: friendshipStatus
    };
  } catch (error) {
    console.error('Error fetching profile data:', error);
    throw error;
  }
}
