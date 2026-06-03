import axios from 'axios';
import https from 'https';

const PISTON_URL = 'https://glorious-space-enigma-wr57wx45p96rh9w9r-2001.app.github.dev/api/v2/runtimes';

async function test() {
  try {
    const response = await axios.get(PISTON_URL, {
      timeout: 10000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Accept': 'application/json'
      },
      httpsAgent: new https.Agent({ rejectUnauthorized: false })
    });
    console.log("SUCCESS:", response.data.length, "runtimes");
  } catch (err) {
    console.error("ERROR:", err.response?.status, err.message);
    if(err.response?.status === 404) {
      console.log("BODY:", err.response?.data);
    }
  }
}
test();
