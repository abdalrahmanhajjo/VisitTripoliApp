/**
 * Structured logging for the API. Set LOG_LEVEL=error|warn|info|debug (default: info prod, debug dev).
 * Never pass secrets or full request bodies.
 */

const isProd = process.env.NODE_ENV === 'production';
const configured = (process.env.LOG_LEVEL || (isProd ? 'info' : 'debug')).toLowerCase();

const rank = { error: 0, warn: 1, info: 2, debug: 3 };

function shouldLog(level) {
  const r = rank[level] ?? 2;
  const min = rank[configured] ?? 2;
  return r <= min;
}

function safeMeta(meta) {
  if (!meta || typeof meta !== 'object') return '';
  try {
    return ` ${JSON.stringify(meta)}`;
  } catch {
    return '';
  }
}

function line(level, msg, meta) {
  if (!shouldLog(level)) return;
  const ts = new Date().toISOString();
  const out = `[${ts}] [${level.toUpperCase()}] ${msg}${safeMeta(meta)}`;
  if (level === 'error') console.error(out);
  else if (level === 'warn') console.warn(out);
  else console.log(out);
}

module.exports = {
  error: (msg, meta) => line('error', msg, meta),
  warn: (msg, meta) => line('warn', msg, meta),
  info: (msg, meta) => line('info', msg, meta),
  debug: (msg, meta) => line('debug', msg, meta),
};
