/**
 * Extreme security middleware.
 * - Input sanitization
 * - UUID validation for IDs
 * - Request size limits
 * - No sensitive data in prod errors
 */

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const PLACE_ID_REGEX = /^[a-zA-Z0-9_-]{1,50}$/;
const MAX_STRING = 5000;
const MAX_CAPTION = 2000;
const MAX_NAME = 255;
const MAX_EMAIL = 254;

function sanitizeString(s, maxLen = MAX_STRING) {
  if (s == null || typeof s !== 'string') return null;
  return s
    .replace(/\0/g, '')
    .replace(/<[^>]*>/g, '')
    .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '')
    .slice(0, maxLen)
    .trim() || null;
}

function isValidUUID(id) {
  return id && typeof id === 'string' && UUID_REGEX.test(id);
}

function isValidPlaceId(id) {
  return id && typeof id === 'string' && PLACE_ID_REGEX.test(id);
}

function sanitizeObject(obj, schema) {
  if (!obj || typeof obj !== 'object') return {};
  const out = {};
  for (const [key, rules] of Object.entries(schema)) {
    if (!(key in obj)) continue;
    let val = obj[key];
    if (rules.type === 'string') {
      val = sanitizeString(val, rules.max || MAX_STRING);
    } else if (rules.type === 'number') {
      val = typeof val === 'number' && !isNaN(val) ? val : parseFloat(val);
      if (isNaN(val)) val = rules.default;
      if (rules.min != null && val < rules.min) val = rules.min;
      if (rules.max != null && val > rules.max) val = rules.max;
    } else if (rules.type === 'boolean') {
      val = val === true || val === 'true' || val === 1;
    } else if (rules.type === 'uuid') {
      val = isValidUUID(val) ? val : null;
    } else if (rules.type === 'placeId') {
      val = isValidPlaceId(val) ? val : null;
    } else if (rules.type === 'array') {
      val = Array.isArray(val) ? val : null;
    }
    if (val !== undefined && val !== null) out[key] = val;
  }
  return out;
}

/** Middleware: validate UUID param */
function validateUuidParam(paramName) {
  return (req, res, next) => {
    const id = req.params[paramName];
    if (!isValidUUID(id)) {
      return res.status(400).json({ error: 'Invalid ID format' });
    }
    next();
  };
}

/** Middleware: validate place ID param */
function validatePlaceIdParam(paramName) {
  return (req, res, next) => {
    const id = req.params[paramName];
    if (!isValidPlaceId(id)) {
      return res.status(400).json({ error: 'Invalid place ID format' });
    }
    next();
  };
}

/** Middleware: sanitize common body fields for feed/business posts */
function sanitizeFeedBody(req, res, next) {
  if (req.body && typeof req.body === 'object') {
    req.body.caption = sanitizeString(req.body.caption, MAX_CAPTION);
    req.body.authorName = sanitizeString(req.body.authorName, MAX_NAME);
    req.body.placeId = isValidPlaceId(req.body.placeId) ? req.body.placeId : (isValidPlaceId(req.body.place_id) ? req.body.place_id : null);
  }
  next();
}

/** Middleware: ensure no sensitive data in error response (production) */
function safeError(err, req) {
  const isProd = process.env.NODE_ENV === 'production';
  if (isProd) {
    return { error: 'An error occurred' };
  }
  return { error: err.message, detail: err.message };
}

/** Dangerous patterns: XSS, path traversal, and other injection attempts */
const SUSPICIOUS_PATTERNS = [
  '<script', 'javascript:', 'vbscript:', 'data:', 'expression(',
  'onerror=', 'onload=', 'onclick=', 'onmouseover=', 'onfocus=',
  '<iframe', '<object', '<embed', 'eval(', 'document.cookie',
  '../', '..\\', '\\\\', '\0',
];

function hasSuspiciousInput(s) {
  if (!s || typeof s !== 'string') return false;
  const lower = s.toLowerCase();
  if (SUSPICIOUS_PATTERNS.some(p => lower.includes(p))) return true;
  if (lower.includes('..') && (lower.includes('/') || lower.includes('\\'))) return true;
  if (s.includes('\0')) return true;
  return false;
}

/** Reject requests with suspicious patterns (XSS, path traversal, null bytes) */
function blockSuspiciousInput(req, res, next) {
  // AI route accepts large prompts with place data; skip body check to avoid false positives
  const isAiRoute = (req.originalUrl || req.url || '').includes('/api/ai');
  const qs = req.originalUrl || '';
  const authHeader = req.headers.authorization || '';
  if (hasSuspiciousInput(qs) || hasSuspiciousInput(authHeader)) {
    return res.status(400).json({ error: 'Invalid request' });
  }
  if (!isAiRoute) {
    const body = JSON.stringify(req.body || {});
    if (hasSuspiciousInput(body)) {
      return res.status(400).json({ error: 'Invalid request' });
    }
  }
  next();
}

module.exports = {
  sanitizeString,
  isValidUUID,
  isValidPlaceId,
  sanitizeObject,
  validateUuidParam,
  validatePlaceIdParam,
  sanitizeFeedBody,
  safeError,
  blockSuspiciousInput,
  MAX_CAPTION,
  MAX_NAME,
};
