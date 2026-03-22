/**
 * Simple in-memory response cache for mostly-static endpoints.
 * Prevents repeated DB hits for categories, interests, etc.
 */
const cache = new Map();
const TTL_MS = 5 * 60 * 1000; // 5 minutes

function responseCache(ttlMs = TTL_MS, options = {}) {
  const includeHost = options.includeHost === true;
  const keyFn = typeof options.key === 'function' ? options.key : null;
  const getTtlMs = typeof options.getTtlMs === 'function' ? options.getTtlMs : null;
  return (req, res, next) => {
    let key = keyFn ? keyFn(req) : (req.originalUrl || req.url);
    if (!keyFn && includeHost) key += '|' + (req.get('host') || req.get('x-forwarded-host') || '');
    const ttl = getTtlMs ? getTtlMs(req) : ttlMs;
    const entry = cache.get(key);
    const now = Date.now();
    if (ttl > 0 && entry && entry.expiresAt > now) {
      res.setHeader('X-Cache', 'HIT');
      return res.json(entry.data);
    }
    const originalJson = res.json.bind(res);
    res.json = (data) => {
      if (ttl > 0) {
        cache.set(key, { data: JSON.parse(JSON.stringify(data)), expiresAt: now + ttl });
        res.setHeader('Cache-Control', `public, max-age=${Math.floor(ttl / 1000)}`);
        res.setHeader('X-Cache', 'MISS');
      } else {
        res.setHeader('X-Cache', 'BYPASS');
      }
      return originalJson(data);
    };
    next();
  };
}

/**
 * Invalidate cache entries whose key starts with prefix (e.g. 'feed:userId:' after like/save toggle).
 */
function invalidateByPrefix(prefix) {
  for (const key of cache.keys()) {
    if (key.startsWith(prefix)) cache.delete(key);
  }
}

module.exports = { responseCache, invalidateByPrefix };
