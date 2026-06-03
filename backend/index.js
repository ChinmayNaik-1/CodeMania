import 'express-async-errors';
import 'dotenv/config';
import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import path from 'path';
import { fileURLToPath } from 'url';
import jwt from 'jsonwebtoken';
import axios from 'axios';
import https from 'https';
import pg from 'pg';
import cors from 'cors';
import { initRedis } from './services/leaderboardService.js';
import { initContestSocket } from './socket/contestSocket.js';
import { setSocketIo } from './routes/submissionRoutes.js';
import { initSubmissionQueue } from './services/submissionQueue.js';

import authRoutes from './routes/authRoutes.js';
import problemRoutes from './routes/problems.js';
import contestRoutes from './routes/contests.js';
import submissionRoutes from './routes/submissionRoutes.js';
import submissionsApiRoutes from './routes/submissions.js';
import adminRoutes from './routes/admin.js';
import userCodeRoutes from './routes/usercode.js';
import profileRoutes from './routes/profile.js';
import friendsRoutes from './routes/friends.js';
import usersRoutes from './routes/users.js';
import { initPresenceSocket } from './socket/presence.js';

const app = express();
const httpServer = createServer(app);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const flutterBuildDir = path.join(__dirname, 'public');
const flutterIndexFile = path.join(flutterBuildDir, 'index.html');

function isApiPath(requestPath = '') {
  return (
    requestPath === '/health' ||
    requestPath.startsWith('/auth') ||
    requestPath.startsWith('/problems') ||
    requestPath.startsWith('/contests') ||
    requestPath.startsWith('/api/contests') ||
    requestPath.startsWith('/submit') ||
    requestPath.startsWith('/api/submissions') ||
    requestPath.startsWith('/api/friends') ||
    requestPath.startsWith('/api/users') ||
    requestPath.startsWith('/api/admin') ||
    requestPath.startsWith('/api/usercode') ||
    requestPath.startsWith('/socket.io')
  );
}

const corsOptions = {
  origin: function(origin, callback) {
    const allowedOrigins = [
      'http://localhost:5000',
      'http://localhost:5001',
      'http://localhost:3000',
      'http://localhost:8080',
      'http://localhost:4200',
      'http://127.0.0.1:5000',
      'http://127.0.0.1:5001',
      'http://127.0.0.1:3000',
      'http://127.0.0.1:8080',
      process.env.FRONTEND_URL,
    ].filter(Boolean);
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      console.log('⚠️ CORS: Attempted access from', origin);
      callback(null, true); // TEMP: Allow all for debugging
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: [
    'Content-Type', 
    'Authorization',
    'X-Requested-With',
    'Accept',
    'Origin'
  ],
  optionsSuccessStatus: 200
};

const io = new Server(httpServer, {
  cors: {
    origin: [
      'http://localhost:5000',
      'http://localhost:3000',
      'http://localhost:8080',
      'http://127.0.0.1:5000',
      process.env.FRONTEND_URL,
    ].filter(Boolean),
    methods: ['GET', 'POST'],
    credentials: true,
    allowedHeaders: ['Authorization', 'Content-Type']
  },
  transports: ['websocket', 'polling'],
  allowEIO3: true,
  pingTimeout: 60000,
  pingInterval: 25000,
});

const JWT_SECRET = process.env.JWT_SECRET || 'codemania_dev_secret';
app.set('io', io);

io.use((socket, next) => {
  const authHeader =
    socket.handshake.headers.authorization ||
    (typeof socket.handshake.auth?.token === 'string'
      ? `Bearer ${socket.handshake.auth.token}`
      : null);

  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.slice(7);
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      socket.data.userId = decoded.userId;
    } catch (error) {
      console.warn('Socket auth token verification failed:', error.message);
    }
  }

  next();
});

const PORT = process.env.PORT || 3000;

export const dbPool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : undefined,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

dbPool.on('error', (err) => console.error('Unexpected error on idle client', err));

app.use(cors(corsOptions));
app.options('*', cors(corsOptions));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

app.use('/auth', authRoutes);
app.use('/problems', problemRoutes);
app.use('/api/contests', contestRoutes);
app.use('/submit', submissionRoutes);
app.use('/api/submissions', submissionsApiRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/usercode', userCodeRoutes);
app.use('/api', profileRoutes);
app.use('/api/friends', friendsRoutes);
app.use('/api/users', usersRoutes);
// Friends leaderboard alias
app.use('/api/leaderboard/friends', (req, res) => res.redirect('/api/friends/leaderboard'));

app.use(express.static(flutterBuildDir, {
  maxAge: '1y',
  etag: true,
  lastModified: true,
  setHeaders: (res, filePath) => {
    if (filePath.endsWith('index.html')) {
      res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
      return;
    }

    if (/\.(js|css|map|png|jpg|jpeg|gif|svg|webp|ico|woff|woff2|ttf|otf|json|wasm)$/i.test(filePath)) {
      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    }
  },
}));

app.get('*', (req, res, next) => {
  const acceptsHtml = (req.headers.accept || '').includes('text/html');

  if (req.method !== 'GET' || isApiPath(req.path) || !acceptsHtml) {
    return next();
  }

  res.sendFile(flutterIndexFile, (err) => {
    if (err) {
      next();
    }
  });
});

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: err.message || 'Internal server error',
    code: 'INTERNAL_ERROR',
  });
});

app.use((req, res) => {
  if (isApiPath(req.path) || !(req.headers.accept || '').includes('text/html')) {
    res.status(404).json({ error: 'Not found', code: 'NOT_FOUND' });
    return;
  }

  res.sendFile(flutterIndexFile);
});

setSocketIo(io);
initContestSocket(io);
initPresenceSocket(io);
initSubmissionQueue(io, dbPool);

async function checkPistonHealth() {
  const basePistonUrl = (process.env.PISTON_URL || 'http://localhost:2000')
    .replace(/\/$/, '')
    .replace(/\/api\/v2(\/execute|\/runtimes)?$/, '');
  const pistonRuntimesUrl = `${basePistonUrl}/api/v2/runtimes`;

  try {
    const response = await axios.get(pistonRuntimesUrl, { 
      timeout: 5000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json'
      },
      httpsAgent: new https.Agent({ rejectUnauthorized: false })
    });
    const runtimes = Array.isArray(response.data) ? response.data : [];
    console.log(`✓ Piston runtimes available: ${runtimes.length}`);
  } catch (error) {
    console.warn(`⚠️  Piston health check failed at ${pistonRuntimesUrl}: ${error.message}`);
  }
}

async function startServer() {
  try {
    const poolConnection = await dbPool.connect();
    poolConnection.release();
    console.log('✓ Database connected');

    await initRedis();
    console.log('✓ Redis connected');

    await checkPistonHealth();

    httpServer.listen(PORT, () => {
      console.log(`✓ Server running on http://localhost:${PORT}`);
      console.log(`✓ Socket.IO server ready for real-time events`);
      console.log('PISTON_URL from env:', process.env.PISTON_URL);
      console.log('Final Piston endpoint:', process.env.PISTON_URL?.includes('/api/v2') ? process.env.PISTON_URL : `${process.env.PISTON_URL}/api/v2/execute`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// --- RENDER FREE TIER SELF-PING KEEPALIVE ---
// Prevent the server container from entering idle/sleep mode
const KEEPALIVE_INTERVAL = 10 * 60 * 1000; // Every 10 minutes

setInterval(async () => {
  try {
    const backendUrl = process.env.RENDER_EXTERNAL_URL ? `${process.env.RENDER_EXTERNAL_URL}/health` : `http://localhost:${PORT}/health`;
    
    // Using native fetch or axios. Axios is available here.
    await axios.get(backendUrl, { timeout: 10000 });
    console.log(`📡 Keepalive ping successfully transmitted to ${backendUrl}`);
  } catch (error) {
    // Fail silently so it doesn't interrupt main server threads if offline
    console.log('📡 Keepalive ping skipped or network trace failed.');
  }
}, KEEPALIVE_INTERVAL);

process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  httpServer.close(async () => {
    await dbPool.end();
    process.exit(0);
  });
});

startServer();
