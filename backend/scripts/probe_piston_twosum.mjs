import 'dotenv/config';
import pg from 'pg';
import axios from 'axios';

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
});

const userCode = `class Solution {
public:
    vector<int> twoSum(vector<int>& nums, int target) {
        unordered_map<int,int> m;
        for (int i = 0; i < (int)nums.size(); ++i) {
            int need = target - nums[i];
            if (m.count(need)) return {m[need], i};
            m[nums[i]] = i;
        }
        return {};
    }
};
`;

const stdin = '[2,7,11,15]\n9';

const driverResult = await pool.query(
  `SELECT driver_prefix, driver_suffix
   FROM driver_code
   WHERE problem_id = $1 AND language = $2
   LIMIT 1`,
  [1, 'cpp']
);

const driverPrefix = driverResult.rows[0]?.driver_prefix || '';
const driverSuffix = driverResult.rows[0]?.driver_suffix || '';
const sourceCode = [driverPrefix, userCode, driverSuffix]
  .filter((part) => part && String(part).trim().length > 0)
  .join('\n');

const response = await axios.post(
  process.env.PISTON_URL || 'http://localhost:2000/api/v2/execute',
  {
    language: 'cpp',
    version: '10.2.0',
    files: [{ name: 'solution.cpp', content: sourceCode }],
    stdin,
    run_timeout: 3000,
    compile_timeout: 10000,
    run_memory_limit: 128 * 1024 * 1024,
    compile_memory_limit: 256 * 1024 * 1024,
  }
);

console.log(JSON.stringify(response.data, null, 2));
await pool.end();
