import { Router } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { dbPool } from '../index.js';
import { authMiddleware } from '../middleware/auth.js';

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'codemania_dev_secret';
const SALT_ROUNDS = 10;
const GOOGLE_SIGNUP_TOKEN_EXPIRES = '15m';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const USERNAME_REGEX = /^[a-zA-Z0-9_]{3,30}$/;

const createSessionToken = (user) => {
  return jwt.sign({ userId: user.id, role: user.role }, JWT_SECRET, {
    expiresIn: '7d',
  });
};

const createGoogleSignupToken = ({ email, googleUid, avatarUrl }) => {
  return jwt.sign(
    {
      type: 'google_signup',
      email,
      googleUid,
      avatarUrl: avatarUrl || null,
    },
    JWT_SECRET,
    { expiresIn: GOOGLE_SIGNUP_TOKEN_EXPIRES }
  );
};

const validateRegistrationFields = ({ username, email, password }) => {
  if (!username || !email || !password) {
    return 'username, email and password are required';
  }

  if (!EMAIL_REGEX.test(email)) {
    return 'Please provide a valid email address';
  }

  if (!USERNAME_REGEX.test(username)) {
    return 'Username must be 3-30 characters and use only letters, numbers, or underscores';
  }

  if (password.length < 8) {
    return 'Password must be at least 8 characters long';
  }

  return null;
};

async function verifyGoogleIdToken(idToken) {
  const googleWebClientId = process.env.GOOGLE_WEB_CLIENT_ID;

  if (!googleWebClientId) {
    throw new Error('Google auth is not configured on server');
  }

  const response = await fetch(
    `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`
  );

  if (!response.ok) {
    throw new Error('Invalid Google token');
  }

  const payload = await response.json();

  if (payload.aud !== googleWebClientId) {
    throw new Error('Invalid Google token');
  }

  if (payload.email_verified !== true && payload.email_verified !== 'true') {
    throw new Error('Email not verified by Google');
  }

  return {
    email: payload.email,
    googleUid: payload.sub,
    avatarUrl: payload.picture || null,
  };
}

// POST /auth/register
router.post('/register', async (req, res) => {
  const { username, email, password } = req.body;
  const validationError = validateRegistrationFields({ username, email, password });
  if (validationError) {
    return res.status(400).json({ error: validationError });
  }

  const normalizedEmail = email.trim().toLowerCase();
  const normalizedUsername = username.trim();

  try {
    const existing = await dbPool.query(
      'SELECT id FROM users WHERE email = $1 OR username = $2',
      [normalizedEmail, normalizedUsername]
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'Email or username already taken' });
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    const result = await dbPool.query(
      `INSERT INTO users (username, email, password_hash, role, rating)
       VALUES ($1, $2, $3, 'user', 1200)
       RETURNING id, username, email, role, rating, avatar_url, google_uid`,
      [normalizedUsername, normalizedEmail, passwordHash]
    );

    const user = result.rows[0];
    const token = createSessionToken(user);

    res.status(201).json({ token, user });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ error: err.message });
  }
});

// POST /auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password are required' });
  }

  const normalizedEmail = email.trim().toLowerCase();

  try {
    const result = await dbPool.query(
      'SELECT * FROM users WHERE email = $1',
      [normalizedEmail]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = result.rows[0];
    
    const valid = await bcrypt.compare(password, user.password_hash);

    if (!valid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = createSessionToken(user);

    res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role,
        rating: user.rating,
        avatar_url: user.avatar_url,
        google_uid: user.google_uid,
      },
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: err.message });
  }
});

// GET /auth/me (protected route)
router.get('/me', authMiddleware, (req, res) => {
  res.json({ user: req.user });
});

// POST /auth/google/start
const googleStartHandler = async (req, res) => {
  const { idToken } = req.body;

  if (!idToken) {
    return res.status(400).json({ error: 'idToken is required' });
  }

  try {
    const { email, googleUid, avatarUrl } = await verifyGoogleIdToken(idToken);

    const existing = await dbPool.query(
      'SELECT id, username, email, role, rating, avatar_url, google_uid FROM users WHERE google_uid = $1 OR email = $2 LIMIT 1',
      [googleUid, email]
    );

    if (existing.rows.length > 0) {
      const user = existing.rows[0];

      if (!user.google_uid) {
        const updateResult = await dbPool.query(
          `UPDATE users
           SET google_uid = $1, avatar_url = COALESCE($2, avatar_url)
           WHERE id = $3
           RETURNING id, username, email, role, rating, avatar_url, google_uid`,
          [googleUid, avatarUrl, user.id]
        );
        const updatedUser = updateResult.rows[0];
        return res.json({ token: createSessionToken(updatedUser), user: updatedUser });
      }

      return res.json({ token: createSessionToken(user), user });
    }
    const signupToken = createGoogleSignupToken({
      email,
      googleUid,
      avatarUrl,
    });

    return res.status(202).json({
      signup_required: true,
      signup_token: signupToken,
      email,
    });
  } catch (err) {
    if (err.message === 'Invalid Google token' || err.message === 'Email not verified by Google') {
      return res.status(401).json({ error: err.message });
    }
    if (err.message === 'Google auth is not configured on server') {
      return res.status(500).json({ error: err.message });
    }
    console.error('Google start auth error:', err);
    return res.status(500).json({ error: 'Google authentication failed' });
  }
};

router.post('/google/start', googleStartHandler);

// POST /auth/google/complete-signup
router.post('/google/complete-signup', async (req, res) => {
  const { signupToken, username, password } = req.body;

  if (!signupToken) {
    return res.status(400).json({ error: 'signupToken is required' });
  }

  if (!username || !password) {
    return res.status(400).json({ error: 'username and password are required' });
  }

  if (!USERNAME_REGEX.test(username)) {
    return res.status(400).json({ error: 'Username must be 3-30 characters and use only letters, numbers, or underscores' });
  }

  if (password.length < 8) {
    return res.status(400).json({ error: 'Password must be at least 8 characters long' });
  }

  try {
    const decoded = jwt.verify(signupToken, JWT_SECRET);
    if (decoded.type !== 'google_signup') {
      return res.status(401).json({ error: 'Invalid signup token' });
    }

    const email = decoded.email;
    const googleUid = decoded.googleUid;
    const avatarUrl = decoded.avatarUrl || null;

    const existing = await dbPool.query(
      'SELECT id FROM users WHERE email = $1 OR username = $2 OR google_uid = $3',
      [email, username.trim(), googleUid]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        error: 'Email, username, or Google account is already registered',
      });
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    const created = await dbPool.query(
      `INSERT INTO users (email, username, password_hash, google_uid, avatar_url, role, rating)
       VALUES ($1, $2, $3, $4, $5, 'user', 1200)
       RETURNING id, username, email, role, rating, avatar_url, google_uid`,
      [email, username.trim(), passwordHash, googleUid, avatarUrl]
    );

    const user = created.rows[0];
    const token = createSessionToken(user);

    return res.status(201).json({ token, user });
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Signup token expired. Please start Google sign-in again.' });
    }
    if (err.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Invalid signup token' });
    }
    console.error('Google complete signup error:', err);
    return res.status(500).json({ error: 'Failed to complete Google signup' });
  }
});

export default router;
