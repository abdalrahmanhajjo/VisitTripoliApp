const path = require('path');
const fs = require('fs');

require('./config/loadEnv').loadEnv();
const isProd = process.env.NODE_ENV === 'production';
require('./config/validateEnv').validateEnv();

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
  process.exit(1);
});

if (!isProd && process.env.ALLOW_INSECURE_TLS === '1') {
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
}

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');

const { registerRoutes } = require('./registerRoutes');
const { query, pool } = require('./db');
const { AppError } = require('./utils/AppError');

const app = express();
const PORT = process.env.PORT || 3000;

app.disable('x-powered-by');
app.set('trust proxy', 1);

// Render / load balancers: health checks must succeed before heavy middleware (helmet, cors, DB-heavy routes).
// Do not require DB here — deploy timeouts happen if /health waits on pool or middleware.
function sendLiveness(res) {
  res.setHeader('Cache-Control', 'no-store');
  res.status(200).json({ status: 'ok' });
}
app.get('/health', (req, res) => sendLiveness(res));
app.get('/api/health', (req, res) => sendLiveness(res));
app.head('/health', (req, res) => res.sendStatus(200));
app.head('/api/health', (req, res) => res.sendStatus(200));

const smtpConfig = require('./config/smtpConfig');
if (!smtpConfig.isConfigured()) {
  console.warn('SMTP not configured: password reset & verification emails will be logged to console only.');
}

const { blockSuspiciousInput } = require('./middleware/security');
const helmetOptions = {
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false,
  crossOriginResourcePolicy: { policy: 'same-site' },
  hsts: isProd ? { maxAge: 31536000, includeSubDomains: true, preload: true } : false,
  xContentTypeOptions: true,
  xFrameOptions: { action: 'deny' },
  xXssProtection: true,
  referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
};
app.use(helmet(helmetOptions));
app.use(compression());

const allowedOriginsRaw = (process.env.CORS_ORIGIN || '').trim();
const allowedOrigins = allowedOriginsRaw
  ? allowedOriginsRaw.split(',').map((o) => o.trim()).filter(Boolean)
  : [];
const allowAllOrigins = allowedOrigins.length === 0 || (allowedOrigins.length === 1 && allowedOrigins[0] === '*');
app.use(cors({
  origin: allowAllOrigins
    ? true
    : (origin, cb) => {
        if (!origin || allowedOrigins.includes(origin)) return cb(null, true);
        return cb(null, false);
      },
  credentials: true,
  maxAge: 86400,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Admin-Key'],
  optionsSuccessStatus: 204,
}));

app.use(express.json({ limit: '256kb' }));
app.use(blockSuspiciousInput);

const healthDbHandler = (req, res) => {
  query('SELECT 1')
    .then(() => res.json({ status: 'ok', db: 'connected' }))
    .catch((err) => {
      console.error('Health DB check failed:', err.message);
      res.status(503).json({
        status: 'error',
        db: 'failed',
        error: 'Database unavailable',
        ...(isProd ? {} : { detail: err.message }),
      });
    });
};
// /health and /api/health (liveness) are registered above — before middleware.
app.get('/health/db', healthDbHandler);
app.get('/health/db/', healthDbHandler);
app.get('/api/health/db', healthDbHandler);
app.get('/api/health/db/', healthDbHandler);
app.get('/health/email', (req, res) => {
  if (isProd) return res.json({ status: 'ok' });
  return res.json({ smtpConfigured: !!require('./config/smtpConfig').isConfigured() });
});

const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: isProd ? 60 : 80,
  message: { error: 'Too many requests. Please slow down.' },
  standardHeaders: true,
  legacyHeaders: false,
});
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 15,
  message: { error: 'Too many attempts. Try again later.' },
  standardHeaders: true,
});
const forgotPasswordLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5,
  message: { error: 'Too many password reset requests. Try again later.' },
  standardHeaders: true,
});
app.use('/api', apiLimiter);
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);
app.use('/api/auth/forgot-password', forgotPasswordLimiter);
const adminLimiter = rateLimit({ windowMs: 60 * 1000, max: isProd ? 30 : 50, message: { error: 'Too many requests.' }, standardHeaders: true });
app.use('/api/admin', adminLimiter);
const uploadLimiter = rateLimit({ windowMs: 60 * 1000, max: 20, message: { error: 'Too many uploads.' }, standardHeaders: true });
app.use('/api/upload', uploadLimiter);
const aiLimiter = rateLimit({ windowMs: 60 * 1000, max: 30, message: { error: 'Too many AI requests. Try again in a minute.' }, standardHeaders: true });
app.use('/api/ai', aiLimiter);

const uploadsDir = process.env.UPLOADS_PATH
  ? path.resolve(path.join(__dirname, '../..'), process.env.UPLOADS_PATH)
  : path.join(__dirname, '../uploads');
try {
  fs.mkdirSync(uploadsDir, { recursive: true });
} catch (_) { /* ignore */ }
app.use('/uploads', express.static(uploadsDir, {
  index: false,
  redirect: false,
  maxAge: isProd ? 31536000000 : 300000,
  etag: true,
  setHeaders: (res) => {
    res.set('Cache-Control', isProd ? 'public, max-age=31536000, immutable' : 'public, max-age=300');
  },
}));

const publicDir = path.join(__dirname, '../public');
const adminPlacesPath = path.join(publicDir, 'admin-places.html');
app.get('/admin-places.html', (req, res) => {
  res.sendFile(adminPlacesPath, (err) => {
    if (err) {
      if (err.code === 'ENOENT') res.status(404).send('Not found');
      else res.status(500).send('Error');
    }
  });
});
app.get('/admin-places', (req, res) => res.redirect(301, '/admin-places.html'));

registerRoutes(app);

app.use((req, res, next) => {
  if (req.originalUrl.startsWith('/api')) {
    return res.status(404).json({ error: 'Not found' });
  }
  next();
});

app.use(express.static(publicDir, { index: false }));

app.use((err, req, res, next) => {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ error: err.message });
  }
  if (err.code === 'LIMIT_FILE_SIZE') return res.status(400).json({ error: 'File too large' });
  if (err.message?.includes('Invalid file type')) return res.status(400).json({ error: err.message });
  if (isProd) {
    console.error(err.message || err);
  } else {
    console.error(err);
  }
  res.status(500).json({ error: isProd ? 'An error occurred' : (err.message || 'An error occurred') });
});

const HOST = process.env.HOST || '0.0.0.0';
const server = app.listen(PORT, HOST, () => {
  console.log(`Visit Tripoli API running on http://${HOST}:${PORT}`);
  query('SELECT 1')
    .then(() => console.log('DB connected.'))
    .catch((err) => {
      const detail = err?.message || err?.code || String(err);
      console.error(
        'DB check failed:',
        detail,
        '- Set DATABASE_URL in backend/.env (local Postgres or Supabase). Then: npm run db:migrate && npm run db:seed-all. See backend/RENDER-500-PLACES.md'
      );
    });
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(
      `Port ${PORT} is already in use. Stop the other process, or set PORT in backend/.env to a free port.`
    );
    console.error(`Windows: netstat -ano | findstr :${PORT}  then  taskkill /PID <pid> /F`);
  } else {
    console.error(err);
  }
  process.exit(1);
});

function gracefulShutdown(signal) {
  console.log(`${signal}: closing HTTP server…`);
  server.close((closeErr) => {
    if (closeErr) console.error(closeErr);
    pool.end(() => {
      console.log('Database pool closed.');
      process.exit(closeErr ? 1 : 0);
    });
  });
  setTimeout(() => {
    console.error('Forced exit after shutdown timeout');
    process.exit(1);
  }, 10000).unref();
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
