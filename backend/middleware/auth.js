import jwt from 'jsonwebtoken';
import { dbPool } from '../index.js';

const JWT_SECRET = process.env.JWT_SECRET || 'codemania_dev_secret';

export const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing token', code: 'NO_TOKEN' });
    }

    const token = authHeader.split('Bearer ')[1];

    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      const result = await dbPool.query(
        'SELECT id, username, email, role, rating, avatar_url, google_uid FROM users WHERE id = $1',
        [decoded.userId]
      );

      if (result.rows.length === 0) {
        return res.status(401).json({ error: 'User not found', code: 'USER_NOT_FOUND' });
      }

      req.user = result.rows[0];
      next();
    } catch (err) {
      return res.status(401).json({ error: 'Invalid token', code: 'INVALID_TOKEN' });
    }
  } catch (error) {
    return res.status(401).json({ error: error.message, code: 'AUTH_ERROR' });
  }
};

export const requireAdmin = (req, res, next) => {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required', code: 'FORBIDDEN' });
  }
  next();
};

export const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }

    const token = authHeader.split('Bearer ')[1];
    const decoded = jwt.verify(token, JWT_SECRET);
    const result = await dbPool.query(
      'SELECT id, username, email, role, rating, avatar_url, google_uid FROM users WHERE id = $1',
      [decoded.userId]
    );

    if (result.rows.length > 0) {
      req.user = result.rows[0];
    }
  } catch (error) {
    // Ignore invalid tokens for optional auth
  }
  next();
};
