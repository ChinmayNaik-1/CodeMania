import pg from 'pg';
import dotenv from 'dotenv';
import fs from 'fs';
dotenv.config();

const { Pool } = pg;
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

async function run() {
  try {
    const sql = fs.readFileSync('./migrations/contest_submissions_table.sql', 'utf8');
    await pool.query(sql);
    console.log('Migration contest_submissions_table.sql applied successfully');
    process.exit(0);
  } catch(e) {
    console.error(e);
    process.exit(1);
  }
}
run();
