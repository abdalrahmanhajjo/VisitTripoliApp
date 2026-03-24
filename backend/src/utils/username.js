/** Normalize and validate public usernames (stored lowercase, no @). */

const RESERVED = new Set([
  'admin',
  'administrator',
  'support',
  'help',
  'null',
  'undefined',
  'system',
  'tripoli',
  'official',
  'visit',
  'visittripoli',
  'moderator',
  'mod',
  'staff',
]);

/**
 * @param {string|null|undefined} raw
 * @returns {string|null}
 */
function normalizeUsername(raw) {
  if (raw == null || typeof raw !== 'string') return null;
  let s = raw.trim().replace(/^@+/u, '');
  if (!s) return null;
  return s.toLowerCase();
}

/**
 * @param {string|null|undefined} raw
 * @returns {{ ok: true, normalized: string } | { ok: false, error: string }}
 */
function validateUsername(raw) {
  const n = normalizeUsername(raw);
  if (!n) {
    return { ok: false, error: 'Username is required' };
  }
  if (n.length < 3 || n.length > 20) {
    return { ok: false, error: 'Username must be 3–20 characters' };
  }
  if (!/^[a-z0-9_]+$/.test(n)) {
    return { ok: false, error: 'Username can only use lowercase letters, numbers, and underscores' };
  }
  if (n.startsWith('_') || n.endsWith('_')) {
    return { ok: false, error: 'Username cannot start or end with an underscore' };
  }
  if (RESERVED.has(n)) {
    return { ok: false, error: 'This username is reserved' };
  }
  return { ok: true, normalized: n };
}

module.exports = { normalizeUsername, validateUsername, RESERVED };
