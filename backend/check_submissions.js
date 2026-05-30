import 'dotenv/config';
import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const r = await pool.query(
  "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'submissions' ORDER BY ordinal_position"
);
console.log('submissions columns:', r.rows.map(x => `${x.column_name}:${x.data_type}`));

// Check if contest_id and team_id exist
const hasContestId = r.rows.some(x => x.column_name === 'contest_id');
const hasTeamId = r.rows.some(x => x.column_name === 'team_id');

if (!hasContestId) {
  console.log('Adding contest_id to submissions...');
  await pool.query('ALTER TABLE submissions ADD COLUMN IF NOT EXISTS contest_id INT REFERENCES contests(id)');
}
if (!hasTeamId) {
  console.log('Adding team_id to submissions...');
  await pool.query('ALTER TABLE submissions ADD COLUMN IF NOT EXISTS team_id INT REFERENCES contest_teams(id)');
}

console.log('Done.');
await pool.end();
