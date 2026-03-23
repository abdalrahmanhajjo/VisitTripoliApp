/**
 * Fail fast in production when critical configuration is missing or weak.
 */
const isProd = process.env.NODE_ENV === 'production';

function validateEnv() {
  if (!isProd) {
    if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 16) {
      console.warn(
        'JWT_SECRET is missing or short; set a strong secret before production (32+ chars).'
      );
    }
    return;
  }

  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
    console.error('FATAL: In production JWT_SECRET must be set and at least 32 characters.');
    process.exit(1);
  }

  const dbUrl = (process.env.DATABASE_URL || '').trim();
  if (!dbUrl) {
    console.error('FATAL: DATABASE_URL is required in production.');
    process.exit(1);
  }

  const corsOrigin = (process.env.CORS_ORIGIN || '').trim();
  if (!corsOrigin) {
    console.warn('CORS_ORIGIN not set; defaulting to * for this run. Set explicit origins for production.');
    process.env.CORS_ORIGIN = '*';
  } else if (corsOrigin === '*') {
    console.warn('CORS_ORIGIN is *; restrict to your app origins when possible.');
  }

  if (process.env.ALLOW_INSECURE_TLS === '1') {
    console.warn('Warning: ALLOW_INSECURE_TLS is ignored in production.');
  }
}

module.exports = { validateEnv };
