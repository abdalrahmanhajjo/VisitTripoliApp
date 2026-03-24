const express = require('express');
const multer = require('multer');
const path = require('path');
const { authMiddleware } = require('../middleware/auth');
const { query } = require('../db');
const { imageFileFilter } = require('../middleware/secureUpload');
const { uploadProfileAvatar, isConfigured: supabaseConfigured } = require('../lib/supabaseStorage');
const { validateUsername } = require('../utils/username');

const router = express.Router();

router.use(authMiddleware);

const MAX_AVATAR_SIZE = 2 * 1024 * 1024; // 2MB
const avatarUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_AVATAR_SIZE },
  fileFilter: imageFileFilter,
});

// POST /api/user/profile/avatar - Upload profile image to Supabase bucket, update DB
router.post('/profile/avatar', avatarUpload.single('image'), async (req, res) => {
  try {
    if (!req.file || !req.file.buffer) {
      return res.status(400).json({ error: 'No image file provided' });
    }
    if (!supabaseConfigured()) {
      return res.status(503).json({ error: 'Avatar upload not configured' });
    }
    const userId = req.user.userId;
    const avatarUrl = await uploadProfileAvatar(req.file.buffer, req.file, userId);
    await query('UPDATE users SET avatar_url = $1 WHERE id = $2', [avatarUrl, userId]);
    res.status(200).json({ avatarUrl });
  } catch (err) {
    console.error('Avatar upload error:', err);
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ error: 'Image too large. Max 2MB.' });
    }
    res.status(500).json({ error: 'Failed to upload avatar' });
  }
});

// GET /api/user/profile
router.get('/profile', async (req, res) => {
  try {
    const userId = req.user.userId;
    const userResult = await query('SELECT id, email, name, avatar_url, created_at FROM users WHERE id = $1', [userId]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    const user = userResult.rows[0];
    const profileResult = await query('SELECT * FROM profiles WHERE user_id = $1', [userId]);
    const profile = profileResult.rows[0] || {};
    const baseUrl = (req.get('x-forwarded-proto') || (req.secure ? 'https' : 'http')) + '://' + (req.get('x-forwarded-host') || req.get('host') || 'localhost:3000');
    const avatarUrl = user.avatar_url && !user.avatar_url.startsWith('http') ? `${baseUrl}${user.avatar_url}` : (user.avatar_url || null);
    res.json({
      id: user.id,
      name: user.name || profile.username?.replace(/^@/, '') || '',
      username: profile.username || (user.name ? `@${user.name.toLowerCase().replace(/\s/g, '')}` : ''),
      email: user.email,
      avatarUrl: avatarUrl || null,
      city: profile.city || '',
      bio: profile.bio || '',
      mood: profile.mood || 'mixed',
      pace: profile.pace || 'normal',
      analytics: profile.analytics ?? true,
      showTips: profile.show_tips ?? true,
      appRating: profile.app_rating ?? 0,
      onboardingCompleted: profile.onboarding_completed === true,
      createdAt: user.created_at
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// PUT /api/user/profile
router.put('/profile', async (req, res) => {
  try {
    const userId = req.user.userId;
    const { name, username, email, city, bio, mood, pace, analytics, showTips, appRating, onboardingCompleted, avatarUrl } = req.body;
    let usernameForSql = username;
    if (Object.prototype.hasOwnProperty.call(req.body, 'username')) {
      if (username == null || (typeof username === 'string' && !username.trim())) {
        return res.status(400).json({ error: 'Username cannot be empty' });
      }
      const uv = validateUsername(username);
      if (!uv.ok) {
        return res.status(400).json({ error: uv.error });
      }
      const conflict = await query(
        `SELECT user_id FROM profiles
         WHERE LOWER(REGEXP_REPLACE(TRIM(username), '^@+', '')) = $1 AND user_id <> $2`,
        [uv.normalized, userId]
      );
      if (conflict.rows.length > 0) {
        return res.status(400).json({ error: 'This username is already taken' });
      }
      usernameForSql = uv.normalized;
    }
    const onboardingNow = onboardingCompleted === true ? new Date().toISOString() : null;
    if (typeof avatarUrl === 'string') {
      await query('UPDATE users SET avatar_url = $1 WHERE id = $2', [avatarUrl || null, userId]);
    }
    await query(
      `INSERT INTO profiles (user_id, username, city, bio, mood, pace, analytics, show_tips, app_rating, onboarding_completed, onboarding_completed_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())
       ON CONFLICT (user_id) DO UPDATE SET
         username = COALESCE($2, profiles.username),
         city = COALESCE($3, profiles.city),
         bio = COALESCE($4, profiles.bio),
         mood = COALESCE($5, profiles.mood),
         pace = COALESCE($6, profiles.pace),
         analytics = COALESCE($7, profiles.analytics),
         show_tips = COALESCE($8, profiles.show_tips),
         app_rating = COALESCE($9, profiles.app_rating),
         onboarding_completed = COALESCE($10, profiles.onboarding_completed),
         onboarding_completed_at = COALESCE($11, profiles.onboarding_completed_at),
         updated_at = NOW()`,
      [userId, usernameForSql, city, bio, mood, pace, analytics ?? true, showTips ?? true, appRating ?? 0, onboardingCompleted ?? false, onboardingNow]
    );
    if (name) await query('UPDATE users SET name = $1 WHERE id = $2', [name, userId]);
    if (email) await query('UPDATE users SET email = $1 WHERE id = $2', [email, userId]);
    const userResult = await query('SELECT id, email, name, avatar_url, created_at FROM users WHERE id = $1', [userId]);
    const profileResult = await query('SELECT * FROM profiles WHERE user_id = $1', [userId]);
    const user = userResult.rows[0];
    const profile = profileResult.rows[0] || {};
    const baseUrl = (req.get('x-forwarded-proto') || (req.secure ? 'https' : 'http')) + '://' + (req.get('x-forwarded-host') || req.get('host') || 'localhost:3000');
    const resolvedAvatar = (typeof avatarUrl === 'string' ? avatarUrl : user.avatar_url) || null;
    const avatarUrlRes = resolvedAvatar && !resolvedAvatar.startsWith('http') ? `${baseUrl}${resolvedAvatar}` : resolvedAvatar;
    res.json({
      id: user.id,
      name: name ?? (profile.username ? profile.username.replace(/^@/, '') : user.name) ?? '',
      username: username ?? profile.username ?? '',
      email: email ?? user.email,
      avatarUrl: avatarUrlRes,
      city: city ?? profile.city ?? '',
      bio: bio ?? profile.bio ?? '',
      mood: mood ?? profile.mood ?? 'mixed',
      pace: pace ?? profile.pace ?? 'normal',
      analytics: analytics ?? profile.analytics ?? true,
      showTips: showTips ?? profile.show_tips ?? true,
      appRating: appRating ?? profile.app_rating ?? 0,
      onboardingCompleted: onboardingCompleted ?? profile.onboarding_completed ?? false,
      createdAt: user.created_at
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// POST /api/user/push-token — FCM / device token for remote notifications (one active token per user)
router.post('/push-token', async (req, res) => {
  try {
    const userId = req.user.userId;
    const { token, platform } = req.body || {};
    if (!token || typeof token !== 'string') {
      return res.status(400).json({ error: 'token required' });
    }
    const plat = (platform && String(platform)) || 'android';
    await query(
      `INSERT INTO user_push_tokens (user_id, token, platform)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id) DO UPDATE SET token = EXCLUDED.token, platform = EXCLUDED.platform, updated_at = NOW()`,
      [userId, token.trim(), plat.slice(0, 32)]
    );
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to save push token' });
  }
});

module.exports = router;
