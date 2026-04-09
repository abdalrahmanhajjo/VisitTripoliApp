const jwt = require('jsonwebtoken');

const isProd = process.env.NODE_ENV === 'production';
const JWT_SECRET = process.env.JWT_SECRET || (isProd ? '' : 'fallback-dev-only');
const MAX_TOKEN_LENGTH = 1024;
const JWT_OPTIONS = {
  algorithms: ['HS256'],
  maxAge: isProd ? '3d' : '7d',
  clockTolerance: 0,
};

function authMiddleware(req, res, next) {
  if (isProd && !process.env.JWT_SECRET) {
    return res.status(503).json({ error: 'Service unavailable' });
  }
  const authHeader = req.headers.authorization;
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7).trim() : null;

  if (!token) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  if (token.length > MAX_TOKEN_LENGTH) {
    return res.status(401).json({ error: 'Invalid token' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET, JWT_OPTIONS);
    if (!decoded.userId) {
      return res.status(401).json({ error: 'Invalid token payload' });
    }
    req.user = decoded;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

async function requireBusinessOwner(req, res, next) {
  const userId = req.user?.userId;
  if (!userId) return res.status(401).json({ error: 'Authentication required' });
  try {
    const { collection } = require('../db');
    const user = await collection('users').findOne(
      { id: userId },
      { projection: { _id: 0, is_business_owner: 1 } }
    );
    if (!user || !user.is_business_owner) {
      return res.status(403).json({ error: 'Business owner access only. Regular users cannot use this feature.' });
    }
    next();
  } catch (err) {
    next(err);
  }
}

function optionalAuthMiddleware(req, res, next) {
  if (isProd && !process.env.JWT_SECRET) return next();
  const authHeader = req.headers.authorization;
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7).trim() : null;
  if (!token || token.length > MAX_TOKEN_LENGTH) {
    return next();
  }
  try {
    const decoded = jwt.verify(token, JWT_SECRET, JWT_OPTIONS);
    if (decoded.userId) req.user = decoded;
  } catch {
    // ignore invalid token
  }
  next();
}

/**
 * Verify a Bearer token the same way as [optionalAuthMiddleware] (no weak defaults).
 * Use for routes that cannot use the middleware (e.g. mixed public handlers).
 * @returns {string|null} userId or null if missing/invalid
 */
function verifyAccessTokenOptional(token) {
  if (!token || typeof token !== 'string' || token.length > MAX_TOKEN_LENGTH) return null;
  if (isProd && !process.env.JWT_SECRET) return null;
  try {
    const decoded = jwt.verify(token, JWT_SECRET, JWT_OPTIONS);
    return decoded.userId || null;
  } catch {
    return null;
  }
}

module.exports = {
  authMiddleware,
  optionalAuthMiddleware,
  requireBusinessOwner,
  verifyAccessTokenOptional,
};
