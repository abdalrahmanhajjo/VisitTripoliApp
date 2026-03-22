/**
 * Protects admin routes. Expects X-Admin-Key header matching ADMIN_SECRET.
 * In production: ADMIN_SECRET is required, requests without valid key are rejected.
 * In development: if ADMIN_SECRET is not set, allows all (dev mode).
 */
function adminAuth(req, res, next) {
  const secret = process.env.ADMIN_SECRET;
  const isProd = process.env.NODE_ENV === 'production';

  if (isProd && !secret) {
    return res.status(503).json({
      error: 'Admin access disabled: ADMIN_SECRET not configured.',
      hint: 'Set ADMIN_SECRET in your host environment (e.g. Render Dashboard → Environment). For local dev, use NODE_ENV=development and add ADMIN_SECRET to backend/.env, then restart the server.',
    });
  }
  if (!secret) {
    return next(); // Dev: no secret = allow
  }
  const key = req.headers['x-admin-key'];
  if (!key || key.length > 512 || key !== secret) {
    return res.status(401).json({ error: 'Unauthorized. Invalid or missing admin key.' });
  }
  next();
}

module.exports = adminAuth;
