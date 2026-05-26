export const requireAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ error: 'Authentication required', code: 'MISSING_AUTH' });
  }

  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required', code: 'ADMIN_REQUIRED' });
  }

  next();
};
