import 'dotenv/config';
import { createRequire } from 'module';
import { Pool } from 'pg';
import { readFileSync } from 'fs';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function run() {
  const r = await pool.query(
    "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name"
  );
  console.log('Existing tables before migration:', r.rows.map(x => x.table_name));

  const sql = readFileSync('./migrations/contests.sql', 'utf8');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('Migration successful!');

    const r2 = await pool.query(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name"
    );
    console.log('Tables after migration:', r2.rows.map(x => x.table_name));
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('Migration error:', e.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

run();
