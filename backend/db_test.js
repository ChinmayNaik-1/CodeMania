import pkg from 'pg';
const { Pool } = pkg;
import dotenv from 'dotenv';
dotenv.config();

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function run() {
  try {
    const res = await pool.query(`SELECT p.id,
              p.title,
              p.difficulty,
              p.topics,
              p.is_contest_exclusive,
              EXISTS (
                SELECT 1
                FROM submissions s
                WHERE s.problem_id = p.id
                  AND s.user_id = $1
                  AND s.verdict = 'accepted'
              ) AS is_solved
       FROM problems p
       WHERE (p.is_contest_exclusive = false OR $2 = true)
       ORDER BY p.id ASC`, [1, false]);
    console.log(res.rows);
  } catch (err) {
    console.error('ERROR:', err.message);
  } finally {
    pool.end();
  }
}
run();
