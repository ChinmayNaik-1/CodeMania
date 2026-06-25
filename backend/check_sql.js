import { dbPool } from './index.js';
async function test() {
  try {
    const problemsResult = await dbPool.query(
      `SELECT
         p.id, p.title, p.difficulty,
         cp.points, cp.problem_order,
         EXISTS (
           SELECT 1 FROM contest_problem_solves cps
           WHERE cps.contest_id = 13 AND cps.problem_id = p.id
             AND cps.user_id = 1 AND cps.team_id IS NULL
         ) AS is_solved_by_me,
         CASE WHEN 1::int IS NOT NULL THEN
           EXISTS (
             SELECT 1 FROM contest_problem_solves cps
             WHERE cps.contest_id = 13 AND cps.problem_id = p.id
               AND cps.team_id = 1
           )
         ELSE false END AS is_solved_by_team
       FROM contest_problems cp
       JOIN problems p ON p.id = cp.problem_id
       WHERE cp.contest_id = 13`
    );
    console.log(problemsResult.rows);
  } catch (err) {
    console.error(err);
  } finally {
    process.exit(0);
  }
}
test();
