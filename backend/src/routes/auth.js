const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const verifyAppleToken = require('verify-apple-id-token').default || require('verify-apple-id-token');
const { query } = require('../db');
const { validatePassword } = require('../utils/passwordValidator');
const { validateUsername } = require('../utils/username');
const { sendPasswordResetCode, sendVerificationCode, RESET_LINK_EXPIRY_MINUTES, VERIFICATION_LINK_EXPIRY_MINUTES } = require('../services/emailService');

const router = express.Router();
const googleClient = process.env.GOOGLE_CLIENT_ID
  ? new OAuth2Client(process.env.GOOGLE_CLIENT_ID)
  : null;

/** JWT `aud` differs: iOS/macOS use App ID (bundle id); Android/web use Services ID. Try each. */
async function verifyAppleIdTokenFlexible(idToken) {
  const raw =
    process.env.APPLE_CLIENT_IDS ||
    process.env.APPLE_CLIENT_ID ||
    process.env.APPLE_SERVICE_ID ||
    '';
  const clientIds = raw.split(',').map((s) => s.trim()).filter(Boolean);
  if (clientIds.length === 0) {
    throw new Error('Apple not configured');
  }
  let lastErr;
  for (const clientId of clientIds) {
    try {
      return await verifyAppleToken({ idToken, clientId });
    } catch (e) {
      lastErr = e;
    }
  }
  throw lastErr;
}

/**
 * GET/POST — Apple OAuth return URL for Flutter Android (Chrome Custom Tab).
 * Redirects into the app via intent:// (see sign_in_with_apple README).
 */
function appleAndroidReturn(req, res) {
  try {
    const merged = { ...req.query };
    if (req.body && typeof req.body === 'object') {
      Object.assign(merged, req.body);
    }
    const u = new URLSearchParams();
    for (const [k, v] of Object.entries(merged)) {
      if (v != null && String(v) !== '') {
        u.append(k, String(v));
      }
    }
    const qs = u.toString();
    const pkg = (process.env.ANDROID_PACKAGE_NAME || 'com.example.tripoli_explorer').trim();
    const intent = `intent://callback?${qs}#Intent;package=${pkg};scheme=signinwithapple;end`;
    res.redirect(302, intent);
  } catch (err) {
    console.error('Apple android return redirect', err);
    res.status(500).send('Redirect failed');
  }
}

/** When true (non-production only), forgot-password includes devResetCode in JSON for local testing without SMTP. */
function isDevResetCodeEnabled() {
  if (process.env.NODE_ENV === 'production') return false;
  const v = (process.env.ENABLE_DEV_CODE || '').trim().toLowerCase();
  return v === 'true' || v === '1' || v === 'yes';
}

// Simple in-memory rate limit (5 attempts per IP per 15 min)
const loginAttempts = new Map();
const RATE_LIMIT_WINDOW = 15 * 60 * 1000; // 15 min
const MAX_ATTEMPTS = 5;

// Stricter rate limit for forgot-password (3 per 15 min) – prevents enumeration & abuse
const forgotAttempts = new Map();
const FORGOT_MAX_ATTEMPTS = 3;

function checkRateLimit(ip) {
  const now = Date.now();
  const entry = loginAttempts.get(ip);
  if (!entry) return { ok: true };
  if (now - entry.firstAttempt > RATE_LIMIT_WINDOW) {
    loginAttempts.delete(ip);
    return { ok: true };
  }
  if (entry.count >= MAX_ATTEMPTS) {
    return { ok: false, retryAfter: Math.ceil((entry.firstAttempt + RATE_LIMIT_WINDOW - now) / 1000) };
  }
  return { ok: true };
}

function recordFailedAttempt(ip) {
  const now = Date.now();
  const entry = loginAttempts.get(ip);
  if (!entry) {
    loginAttempts.set(ip, { count: 1, firstAttempt: now });
  } else if (now - entry.firstAttempt <= RATE_LIMIT_WINDOW) {
    entry.count++;
  } else {
    loginAttempts.set(ip, { count: 1, firstAttempt: now });
  }
}

function checkForgotRateLimit(ip) {
  const now = Date.now();
  const entry = forgotAttempts.get(ip);
  if (!entry) return { ok: true };
  if (now - entry.firstAttempt > RATE_LIMIT_WINDOW) {
    forgotAttempts.delete(ip);
    return { ok: true };
  }
  if (entry.count >= FORGOT_MAX_ATTEMPTS) {
    return { ok: false, retryAfter: Math.ceil((entry.firstAttempt + RATE_LIMIT_WINDOW - now) / 1000) };
  }
  return { ok: true };
}

function recordForgotAttempt(ip) {
  const now = Date.now();
  const entry = forgotAttempts.get(ip);
  if (!entry) {
    forgotAttempts.set(ip, { count: 1, firstAttempt: now });
  } else if (now - entry.firstAttempt <= RATE_LIMIT_WINDOW) {
    entry.count++;
  } else {
    forgotAttempts.set(ip, { count: 1, firstAttempt: now });
  }
}

function sanitizeAuthInput(req, res, next) {
  const { email, password, name, username } = req.body || {};
  if (typeof email !== 'string' || email.length > 254) {
    return res.status(400).json({ error: 'Invalid email' });
  }
  if (typeof password !== 'string' || password.length > 128) {
    return res.status(400).json({ error: 'Invalid password' });
  }
  if (name != null && (typeof name !== 'string' || name.length > 150)) {
    return res.status(400).json({ error: 'Invalid name' });
  }
  if (username != null && (typeof username !== 'string' || username.length > 64)) {
    return res.status(400).json({ error: 'Invalid username' });
  }
  next();
}

// POST /api/auth/register - Email signup (requires verification)
router.post('/register', sanitizeAuthInput, async (req, res) => {
  try {
    const { name, email, password, username: usernameRaw } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }
    const pv = validatePassword(password);
    if (!pv.valid) {
      return res.status(400).json({ error: pv.error });
    }
    const uv = validateUsername(usernameRaw);
    if (!uv.ok) {
      return res.status(400).json({ error: uv.error });
    }
    const username = uv.normalized;
    const taken = await query(
      `SELECT u.id FROM profiles p
       JOIN users u ON u.id = p.user_id
       WHERE LOWER(REGEXP_REPLACE(TRIM(p.username), '^@+', '')) = $1`,
      [username]
    );
    if (taken.rows.length > 0) {
      return res.status(400).json({ error: 'This username is already taken' });
    }
    const hash = await bcrypt.hash(password, 12);
    const result = await query(
      `INSERT INTO users (email, password_hash, name, auth_provider, email_verified)
       VALUES ($1, $2, $3, 'email', false)
       RETURNING id, email, name`,
      [email, hash, name || null]
    );
    const user = result.rows[0];
    await query(
      `INSERT INTO profiles (user_id, username, onboarding_completed)
       VALUES ($1, $2, false)
       ON CONFLICT (user_id) DO UPDATE SET username = COALESCE(EXCLUDED.username, profiles.username)`,
      [user.id, username]
    );

    const code = String(Math.floor(100000 + Math.random() * 900000));
    const tokenHash = crypto.createHash('sha256').update(code).digest('hex');
    const expiresAt = new Date(Date.now() + VERIFICATION_LINK_EXPIRY_MINUTES * 60 * 60 * 1000);
    await query(
      `INSERT INTO email_verification_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)`,
      [user.id, tokenHash, expiresAt]
    );
    await sendVerificationCode(email, code);

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    res.status(201).json({
      token,
      user: {
        id: user.id,
        name: user.name || email.split('@')[0],
        username,
        email: user.email,
        emailVerified: false,
        onboardingCompleted: false,
        isBusinessOwner: false
      }
    });
  } catch (err) {
    if (err.code === '23505') {
      const msg = (err.constraint || '').includes('username') || (err.detail || '').includes('username')
        ? 'This username is already taken'
        : 'Email already registered';
      return res.status(400).json({ error: msg });
    }
    console.error(err);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// POST /api/auth/login
router.post('/login', sanitizeAuthInput, async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }
    const ip = req.ip || req.connection?.remoteAddress || 'unknown';
    const rate = checkRateLimit(ip);
    if (!rate.ok) {
      return res.status(429).json({
        error: `Too many attempts. Try again in ${rate.retryAfter} seconds.`,
        retryAfter: rate.retryAfter
      });
    }
    const result = await query(
      `SELECT u.id, u.email, u.name, u.password_hash, u.email_verified, u.is_business_owner,
        COALESCE(p.onboarding_completed, false) AS onboarding_completed
       FROM users u
       LEFT JOIN profiles p ON p.user_id = u.id
       WHERE LOWER(u.email) = LOWER($1) AND u.auth_provider = 'email'`,
      [email]
    );
    const user = result.rows[0];
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      recordFailedAttempt(ip);
      return res.status(401).json({ error: 'Wrong email or password. Please try again.' });
    }
    if (!user.email_verified) {
      return res.status(403).json({
        error: 'Email not verified. Check your inbox for the verification link.',
        code: 'EMAIL_NOT_VERIFIED'
      });
    }
    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    res.json({
      token,
      user: {
        id: user.id,
        name: user.name || email.split('@')[0],
        email: user.email,
        emailVerified: true,
        onboardingCompleted: user.onboarding_completed === true,
        isBusinessOwner: user.is_business_owner === true
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Login failed' });
  }
});

// POST /api/auth/google - Sign in/up with Google ID token
router.post('/google', async (req, res) => {
  try {
    const { idToken } = req.body || {};
    if (!idToken || typeof idToken !== 'string' || idToken.length > 5000) {
      return res.status(400).json({ error: 'Invalid token' });
    }
    if (!googleClient) {
      return res.status(503).json({ error: 'Google Sign-In not configured. Set GOOGLE_CLIENT_ID.' });
    }
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const sub = payload.sub;
    const email = payload.email || `${sub}@oauth.google`;
    const name = payload.name || payload.given_name || email.split('@')[0];

    let result = await query(
      `SELECT u.id, u.email, u.name, u.is_business_owner,
        COALESCE(p.onboarding_completed, false) AS onboarding_completed
       FROM users u
       LEFT JOIN profiles p ON p.user_id = u.id
       WHERE u.auth_provider = 'google' AND u.auth_provider_id = $1`,
      [sub]
    );
    let user = result.rows[0];

    if (!user) {
      const existingEmail = await query(
        'SELECT id FROM users WHERE LOWER(email) = LOWER($1)',
        [email]
      );
      if (existingEmail.rows.length > 0) {
        return res.status(400).json({
          error: 'An account with this email already exists. Sign in with email/password.',
        });
      }
      result = await query(
        `INSERT INTO users (email, name, auth_provider, auth_provider_id, email_verified)
         VALUES ($1, $2, 'google', $3, true)
         RETURNING id, email, name`,
        [email, name, sub]
      );
      user = result.rows[0];
      await query(
        `INSERT INTO profiles (user_id, onboarding_completed) VALUES ($1, false)
         ON CONFLICT (user_id) DO NOTHING`,
        [user.id]
      );
      user.onboarding_completed = false;
    }

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    res.json({
      token,
      user: {
        id: user.id,
        name: user.name || email.split('@')[0],
        email: user.email,
        onboardingCompleted: user.onboarding_completed === true,
        isBusinessOwner: user.is_business_owner === true,
      },
    });
  } catch (err) {
    console.error('Google auth error:', err.message || err);
    if (err.message?.includes('Token used too late')) {
      return res.status(401).json({ error: 'Sign-in expired. Try again.' });
    }
    if (err.message?.includes('Wrong number of segments') || err.message?.includes('jwt')) {
      return res.status(401).json({ error: 'Invalid token format. Ensure serverClientId (Web client ID) is set in the app.' });
    }
    if (err.message?.includes('audience') || err.message?.includes('aud')) {
      return res.status(401).json({ error: 'Token audience mismatch. Backend GOOGLE_CLIENT_ID must match app Web client ID.' });
    }
    res.status(401).json({ error: `Google sign-in failed: ${err.message || 'Try again.'}` });
  }
});

// Return URL for Sign in with Apple on Android (register exact URL in Apple Developer → Services ID).
router.get('/apple/android-return', appleAndroidReturn);
router.post(
  '/apple/android-return',
  express.urlencoded({ extended: true, limit: '32kb' }),
  appleAndroidReturn,
);

// POST /api/auth/apple - Sign in/up with Apple ID token
router.post('/apple', async (req, res) => {
  try {
    const { idToken, email: appleEmail, name: appleName } = req.body || {};
    if (!idToken || typeof idToken !== 'string' || idToken.length > 5000) {
      return res.status(400).json({ error: 'Invalid token' });
    }
    const configured =
      (process.env.APPLE_CLIENT_IDS ||
        process.env.APPLE_CLIENT_ID ||
        process.env.APPLE_SERVICE_ID ||
        '').trim();
    if (!configured) {
      return res.status(503).json({
        error:
          'Apple Sign-In not configured. Set APPLE_CLIENT_IDS (recommended: iOS bundle id and Android Services id, comma-separated) or APPLE_CLIENT_ID.',
      });
    }

    const payload = await verifyAppleIdTokenFlexible(idToken);
    const sub = payload.sub;
    const email = payload.email || appleEmail || `${sub}@privaterelay.appleid.apple.com`;
    const name = appleName || payload.name || email.split('@')[0];

    let result = await query(
      `SELECT u.id, u.email, u.name, u.is_business_owner,
        COALESCE(p.onboarding_completed, false) AS onboarding_completed
       FROM users u
       LEFT JOIN profiles p ON p.user_id = u.id
       WHERE u.auth_provider = 'apple' AND u.auth_provider_id = $1`,
      [sub]
    );
    let user = result.rows[0];

    if (!user) {
      const existingEmail = await query(
        'SELECT id FROM users WHERE LOWER(email) = LOWER($1)',
        [email]
      );
      if (existingEmail.rows.length > 0) {
        return res.status(400).json({
          error: 'An account with this email already exists. Sign in with email/password.',
        });
      }
      result = await query(
        `INSERT INTO users (email, name, auth_provider, auth_provider_id, email_verified)
         VALUES ($1, $2, 'apple', $3, true)
         RETURNING id, email, name`,
        [email, name, sub]
      );
      user = result.rows[0];
      await query(
        `INSERT INTO profiles (user_id, onboarding_completed) VALUES ($1, false)
         ON CONFLICT (user_id) DO NOTHING`,
        [user.id]
      );
      user.onboarding_completed = false;
    }

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    res.json({
      token,
      user: {
        id: user.id,
        name: user.name || email.split('@')[0],
        email: user.email,
        onboardingCompleted: user.onboarding_completed === true,
        isBusinessOwner: user.is_business_owner === true,
      },
    });
  } catch (err) {
    console.error('Apple auth error:', err);
    res.status(401).json({ error: 'Invalid Apple sign-in. Try again.' });
  }
});

// POST /api/auth/verify-email
router.post('/verify-email', async (req, res) => {
  try {
    const code = typeof req.body?.code === 'string' ? req.body.code.trim() : '';
    if (!code || !/^\d{6}$/.test(code)) {
      return res.status(400).json({ error: 'Invalid or expired verification code.' });
    }
    const tokenHash = crypto.createHash('sha256').update(code).digest('hex');
    const result = await query(
      `SELECT evt.id, evt.user_id FROM email_verification_tokens evt
       WHERE evt.token_hash = $1 AND evt.expires_at > NOW() AND evt.used_at IS NULL`,
      [tokenHash]
    );
    const row = result.rows[0];
    if (!row) {
      return res.status(400).json({ error: 'Invalid or expired verification code. Request a new one.' });
    }
    await query('BEGIN');
    try {
      await query('UPDATE users SET email_verified = true WHERE id = $1', [row.user_id]);
      await query('UPDATE email_verification_tokens SET used_at = NOW() WHERE id = $1', [row.id]);
      await query('COMMIT');
    } catch (e) {
      await query('ROLLBACK');
      throw e;
    }
    const userResult = await query(
      `SELECT u.id, u.email, u.name, u.is_business_owner, COALESCE(p.onboarding_completed, false) AS onboarding_completed
       FROM users u LEFT JOIN profiles p ON p.user_id = u.id WHERE u.id = $1`,
      [row.user_id]
    );
    const user = userResult.rows[0];
    const jwtToken = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.json({
      token: jwtToken,
      user: {
        id: user.id,
        name: user.name || user.email?.split('@')[0],
        email: user.email,
        emailVerified: true,
        onboardingCompleted: user.onboarding_completed === true,
        isBusinessOwner: user.is_business_owner === true,
      },
    });
  } catch (err) {
    console.error('Verify email error:', err);
    res.status(500).json({ error: 'Verification failed. Try again.' });
  }
});

const resendAttempts = new Map();
const verifyResendCooldown = new Map(); // userId -> { lastSentAt, resendIndex }
const VERIFY_RESEND_COOLDOWNS = [30, 120, 1800]; // 30s, 2min, 30min - cycles

function getVerifyResendState(userId) {
  return verifyResendCooldown.get(userId) || { lastSentAt: null, resendIndex: 0 };
}

async function getLastVerificationSentAt(userId) {
  const r = await query(
    'SELECT created_at FROM email_verification_tokens WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1',
    [userId]
  );
  return r.rows[0]?.created_at ? new Date(r.rows[0].created_at).getTime() : null;
}

function checkVerifyResendCooldown(userId, lastSentAt, resendIndex) {
  const cooldownSec = VERIFY_RESEND_COOLDOWNS[resendIndex % 3];
  const now = Date.now();
  const effectiveLast = lastSentAt || 0;
  const elapsed = (now - effectiveLast) / 1000;
  if (elapsed < cooldownSec) {
    return { ok: false, retryAfter: Math.ceil(cooldownSec - elapsed) };
  }
  return { ok: true };
}

// POST /api/auth/request-verification-email (public, rate-limited - for users who can't login)
router.post('/request-verification-email', async (req, res) => {
  try {
    const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
    if (!email || email.length > 254) {
      return res.status(400).json({ error: 'Valid email required' });
    }
    const ip = req.ip || 'unknown';
    const entry = resendAttempts.get(ip) || { count: 0, first: 0 };
    if (Date.now() - entry.first > 60 * 1000) entry.count = 0;
    entry.first = entry.first || Date.now();
    if (entry.count >= 3) {
      return res.status(429).json({ error: 'Too many requests. Wait a minute.' });
    }
    entry.count++;
    resendAttempts.set(ip, entry);

    const userResult = await query(
      'SELECT id, email FROM users WHERE LOWER(email) = $1 AND auth_provider = \'email\' AND email_verified = false',
      [email]
    );
    const user = userResult.rows[0];
    if (!user) {
      return res.json({ message: 'If an account exists and is unverified, we\'ve sent a new code.' });
    }
    const state = getVerifyResendState(user.id);
    const lastSent = state.lastSentAt || (await getLastVerificationSentAt(user.id));
    const cooldown = checkVerifyResendCooldown(user.id, lastSent, state.resendIndex);
    if (!cooldown.ok) {
      return res.status(429).json({ error: `Please wait ${cooldown.retryAfter} seconds before resending.`, retryAfter: cooldown.retryAfter });
    }
    await query('DELETE FROM email_verification_tokens WHERE user_id = $1', [user.id]);
    const code = String(Math.floor(100000 + Math.random() * 900000));
    const tokenHash = crypto.createHash('sha256').update(code).digest('hex');
    const expiresAt = new Date(Date.now() + VERIFICATION_LINK_EXPIRY_MINUTES * 60 * 60 * 1000);
    await query(
      'INSERT INTO email_verification_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
      [user.id, tokenHash, expiresAt]
    );
    try {
      await sendVerificationCode(user.email, code);
    } catch (sendErr) {
      console.error('Request verification email send failed:', sendErr.message || sendErr);
      return res.status(503).json({ error: 'Failed to send verification email. Try again later.' });
    }
    state.lastSentAt = Date.now();
    state.resendIndex++;
    verifyResendCooldown.set(user.id, state);
    const nextCooldown = VERIFY_RESEND_COOLDOWNS[state.resendIndex % 3];
    res.json({ message: 'If an account exists and is unverified, we\'ve sent a new code.', resendCooldownSeconds: nextCooldown });
  } catch (err) {
    console.error('Request verification email error:', err);
    res.status(500).json({ error: 'Failed to send. Try again.' });
  }
});

// POST /api/auth/resend-verification (authenticated)
router.post('/resend-verification', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null;
    if (!token) return res.status(401).json({ error: 'Sign in required' });
    let userId;
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      userId = decoded.userId;
    } catch (_) {
      return res.status(401).json({ error: 'Invalid or expired session' });
    }

    const userResult = await query(
      'SELECT id, email FROM users WHERE id = $1 AND auth_provider = \'email\' AND email_verified = false',
      [userId]
    );
    const user = userResult.rows[0];
    if (!user) {
      return res.status(400).json({ error: 'Email already verified or invalid account.' });
    }

    const state = getVerifyResendState(userId);
    const lastSent = state.lastSentAt || (await getLastVerificationSentAt(userId));
    const cooldown = checkVerifyResendCooldown(userId, lastSent, state.resendIndex);
    if (!cooldown.ok) {
      return res.status(429).json({
        error: `Please wait ${cooldown.retryAfter} seconds before resending.`,
        retryAfter: cooldown.retryAfter
      });
    }

    await query('DELETE FROM email_verification_tokens WHERE user_id = $1', [userId]);
    const code = String(Math.floor(100000 + Math.random() * 900000));
    const tokenHash = crypto.createHash('sha256').update(code).digest('hex');
    const expiresAt = new Date(Date.now() + VERIFICATION_LINK_EXPIRY_MINUTES * 60 * 60 * 1000);
    await query(
      'INSERT INTO email_verification_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
      [userId, tokenHash, expiresAt]
    );
    try {
      await sendVerificationCode(user.email, code);
    } catch (sendErr) {
      console.error('Resend verification send failed:', sendErr.message || sendErr);
      return res.status(503).json({ error: 'Failed to send verification email. Try again later.' });
    }
    state.lastSentAt = Date.now();
    state.resendIndex++;
    verifyResendCooldown.set(userId, state);
    const nextCooldown = VERIFY_RESEND_COOLDOWNS[state.resendIndex % 3];
    res.json({ message: 'Verification code sent. Check your inbox.', resendCooldownSeconds: nextCooldown });
  } catch (err) {
    console.error('Resend verification error:', err);
    res.status(500).json({ error: 'Failed to send. Try again.' });
  }
});

// GET /api/auth/email-config - Get SMTP config (for app UI, password masked)
router.get('/email-config', (req, res) => {
  const { getSmtpConfig } = require('../config/smtpConfig');
  const c = getSmtpConfig();
  res.json({
    host: c.host,
    port: c.port,
    user: c.user,
    passMasked: c.pass ? '••••••••' : '',
    configured: !!(c.host && c.user && c.pass),
  });
});

// PUT /api/auth/email-config - Save SMTP config (from app UI)
router.put('/email-config', (req, res) => {
  try {
    const { host, port, user, pass } = req.body || {};
    const { saveToFile } = require('../config/smtpConfig');
    const config = {
      host: typeof host === 'string' ? host.trim() : '',
      port: String(port || '587').trim(),
      user: typeof user === 'string' ? user.trim() : '',
      pass: typeof pass === 'string' ? pass.trim() : '',
    };
    const current = require('../config/smtpConfig').getSmtpConfig();
    if (!config.pass && current.pass) config.pass = current.pass;
    saveToFile(config);
    res.json({ ok: true, configured: !!(config.host && config.user && config.pass) });
  } catch (err) {
    console.error('Save email config:', err);
    res.status(500).json({ error: 'Failed to save' });
  }
});

// POST /api/auth/test-email (dev only - verify SMTP)
if (process.env.NODE_ENV !== 'production') {
  router.post('/test-email', async (req, res) => {
    const to = req.body?.to || req.body?.email;
    if (!to || typeof to !== 'string') {
      return res.status(400).json({ error: 'Provide { "to": "your@email.com" }' });
    }
    const testCode = '123456';
    try {
      await sendPasswordResetCode(to, testCode);
      res.json({ ok: true, message: `Test email sent to ${to}. Check inbox and spam.` });
    } catch (err) {
      console.error('Test email failed:', err);
      res.status(500).json({ error: err.message || 'Failed to send' });
    }
  });
}

// POST /api/auth/forgot-password
// Secure: rate-limited, same response for any email, token stored as hash only
router.post('/forgot-password', async (req, res) => {
  try {
    const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
    if (!email || email.length > 254) {
      return res.status(400).json({ error: 'Valid email required' });
    }

    const ip = req.ip || req.connection?.remoteAddress || 'unknown';
    const rate = checkForgotRateLimit(ip);
    if (!rate.ok) {
      return res.status(429).json({
        error: `Too many requests. Try again in ${rate.retryAfter} seconds.`,
        retryAfter: rate.retryAfter,
      });
    }
    recordForgotAttempt(ip);

    const expiryMs = RESET_LINK_EXPIRY_MINUTES * 60 * 1000;

    const result = await query(
      `SELECT id FROM users WHERE LOWER(email) = $1 AND auth_provider = 'email' AND password_hash IS NOT NULL`,
      [email]
    );
    const user = result.rows[0];

    let devResetCode = null;
    if (user) {
      console.log(`[Forgot password] Sending reset code to ${email}`);
      await query(
        "DELETE FROM password_reset_tokens WHERE user_id = $1 AND (used_at IS NULL OR expires_at < NOW())",
        [user.id]
      );

      const code = String(Math.floor(100000 + Math.random() * 900000)); // 6-digit code
      const tokenHash = crypto.createHash('sha256').update(code).digest('hex');
      const expiresAt = new Date(Date.now() + expiryMs);

      await query(
        `INSERT INTO password_reset_tokens (user_id, token_hash, expires_at)
         VALUES ($1, $2, $3)`,
        [user.id, tokenHash, expiresAt]
      );

      try {
        await sendPasswordResetCode(email, code);
        console.log(`[Forgot password] Reset code sent successfully to ${email}`);
      } catch (sendErr) {
        console.error('[Forgot password] Email send failed:', sendErr.message || sendErr);
        if (isDevResetCodeEnabled()) {
          devResetCode = code;
          console.warn('[Forgot password] ENABLE_DEV_CODE: returning code in API response (dev only).');
        } else {
          return res.status(503).json({
            error: 'Failed to send reset email. Please try again later or check your spam folder.',
          });
        }
      }
      if (isDevResetCodeEnabled() && !devResetCode) {
        devResetCode = code;
      }
    }

    const genericMsg =
      "If an account with that email exists, we've sent a 6-digit code. Check your inbox.";
    const body = { message: genericMsg };
    if (devResetCode) {
      body.devResetCode = devResetCode;
      body.message =
        'Development mode: use the 6-digit code below (also logged if email was sent).';
    }
    res.json(body);
  } catch (err) {
    console.error('Forgot password error:', err);
    res.status(500).json({
      error: 'Something went wrong. Please try again.',
    });
  }
});

// POST /api/auth/reset-password
// Secure: 6-digit code verified by hash, single-use, short expiry, strong password validation
router.post('/reset-password', async (req, res) => {
  try {
    const { code, password } = req.body || {};
    if (!code || typeof code !== 'string' || !/^\d{6}$/.test(code.trim())) {
      return res.status(400).json({ error: 'Invalid or expired code. Request a new one.' });
    }
    if (!password || typeof password !== 'string') {
      return res.status(400).json({ error: 'New password required' });
    }

    const pv = validatePassword(password);
    if (!pv.valid) {
      return res.status(400).json({ error: pv.error });
    }

    const tokenHash = crypto.createHash('sha256').update(code.trim()).digest('hex');

    const result = await query(
      `SELECT prt.id, prt.user_id
       FROM password_reset_tokens prt
       WHERE prt.token_hash = $1 AND prt.expires_at > NOW() AND prt.used_at IS NULL`,
      [tokenHash]
    );
    const row = result.rows[0];

    if (!row) {
      return res.status(400).json({ error: 'Invalid or expired code. Request a new one.' });
    }

    const hash = await bcrypt.hash(password, 12);
    await query('BEGIN');
    try {
      await query('UPDATE users SET password_hash = $1 WHERE id = $2', [hash, row.user_id]);
      await query('UPDATE password_reset_tokens SET used_at = NOW() WHERE id = $1', [row.id]);
      await query('COMMIT');
    } catch (e) {
      await query('ROLLBACK');
      throw e;
    }

    res.json({ message: 'Password reset successfully. You can now sign in.' });
  } catch (err) {
    console.error('Reset password error:', err);
    res.status(500).json({ error: 'Password reset failed. Try again.' });
  }
});

module.exports = router;
