const express = require('express');
const multer = require('multer');
const { authMiddleware } = require('../middleware/auth');
const { collection } = require('../db');
const { imageFileFilter } = require('../middleware/secureUpload');
const { uploadProfileAvatar, isConfigured: mediaStorageConfigured } = require('../lib/supabaseStorage');
const { validateUsername } = require('../utils/username');

const router = express.Router();
router.use(authMiddleware);

const avatarUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 2 * 1024 * 1024 },
  fileFilter: imageFileFilter,
});

router.post('/profile/avatar', avatarUpload.single('image'), async (req, res) => {
  try {
    if (!req.file?.buffer) return res.status(400).json({ error: 'No image file provided' });
    if (!mediaStorageConfigured()) return res.status(503).json({ error: 'Avatar upload not configured' });
    const userId = req.user.userId;
    const avatarUrl = await uploadProfileAvatar(req.file.buffer, req.file, userId);
    await collection('users').updateOne({ id: userId }, { $set: { avatar_url: avatarUrl, updated_at: new Date() } });
    res.status(200).json({ avatarUrl });
  } catch {
    res.status(500).json({ error: 'Failed to upload avatar' });
  }
});

router.get('/profile', async (req, res) => {
  const userId = req.user.userId;
  const user = await collection('users').findOne({ id: userId }, { projection: { _id: 0, id: 1, email: 1, name: 1, avatar_url: 1, created_at: 1 } });
  if (!user) return res.status(404).json({ error: 'User not found' });
  const profile = (await collection('profiles').findOne({ user_id: userId }, { projection: { _id: 0 } })) || {};
  const baseUrl = `${req.get('x-forwarded-proto') || (req.secure ? 'https' : 'http')}://${req.get('x-forwarded-host') || req.get('host') || 'localhost:3000'}`;
  const avatarUrl = user.avatar_url && !user.avatar_url.startsWith('http') ? `${baseUrl}${user.avatar_url}` : (user.avatar_url || null);
  res.json({
    id: user.id,
    name: user.name || profile.username?.replace(/^@/, '') || '',
    username: profile.username || (user.name ? `@${user.name.toLowerCase().replace(/\s/g, '')}` : ''),
    email: user.email,
    avatarUrl,
    city: profile.city || '',
    bio: profile.bio || '',
    mood: profile.mood || 'mixed',
    pace: profile.pace || 'normal',
    analytics: profile.analytics ?? true,
    showTips: profile.show_tips ?? true,
    appRating: profile.app_rating ?? 0,
    onboardingCompleted: profile.onboarding_completed === true,
    createdAt: user.created_at,
  });
});

async function updateProfileHandler(req, res) {
  try {
    const userId = req.user.userId;
    const { name, username, email, city, bio, mood, pace, analytics, showTips, appRating, onboardingCompleted, avatarUrl } = req.body || {};
    let normalized = null;
    if (Object.prototype.hasOwnProperty.call(req.body || {}, 'username')) {
      if (username == null || (typeof username === 'string' && !username.trim())) return res.status(400).json({ error: 'Username cannot be empty' });
      const uv = validateUsername(username);
      if (!uv.ok) return res.status(400).json({ error: uv.error });
      const conflict = await collection('profiles').findOne({ username_normalized: uv.normalized, user_id: { $ne: userId } }, { projection: { _id: 1 } });
      if (conflict) return res.status(400).json({ error: 'This username is already taken' });
      normalized = uv.normalized;
    }
    const userSet = { updated_at: new Date() };
    if (name !== undefined) userSet.name = name;
    if (email !== undefined) {
      userSet.email = email;
      userSet.email_lower = String(email).toLowerCase();
    }
    if (typeof avatarUrl === 'string') userSet.avatar_url = avatarUrl || null;
    await collection('users').updateOne({ id: userId }, { $set: userSet });
    const profileSet = { updated_at: new Date() };
    if (normalized != null) {
      profileSet.username = `@${normalized}`;
      profileSet.username_normalized = normalized;
    }
    if (city !== undefined) profileSet.city = city;
    if (bio !== undefined) profileSet.bio = bio;
    if (mood !== undefined) profileSet.mood = mood;
    if (pace !== undefined) profileSet.pace = pace;
    if (analytics !== undefined) profileSet.analytics = analytics;
    if (showTips !== undefined) profileSet.show_tips = showTips;
    if (appRating !== undefined) profileSet.app_rating = appRating;
    if (onboardingCompleted !== undefined) {
      profileSet.onboarding_completed = onboardingCompleted;
      if (onboardingCompleted === true) profileSet.onboarding_completed_at = new Date().toISOString();
    }
    await collection('profiles').updateOne(
      { user_id: userId },
      { $set: profileSet, $setOnInsert: { user_id: userId, created_at: new Date() } },
      { upsert: true }
    );
    const user = await collection('users').findOne({ id: userId }, { projection: { _id: 0 } });
    const profile = await collection('profiles').findOne({ user_id: userId }, { projection: { _id: 0 } });
    res.json({
      id: user.id,
      name: user.name || '',
      username: profile?.username || '',
      email: user.email,
      avatarUrl: user.avatar_url || null,
      city: profile?.city || '',
      bio: profile?.bio || '',
      mood: profile?.mood || 'mixed',
      pace: profile?.pace || 'normal',
      analytics: profile?.analytics ?? true,
      showTips: profile?.show_tips ?? true,
      appRating: profile?.app_rating ?? 0,
      onboardingCompleted: profile?.onboarding_completed ?? false,
      createdAt: user.created_at,
    });
  } catch {
    res.status(500).json({ error: 'Failed to update profile' });
  }
}

router.put('/profile', updateProfileHandler);
// Web parity alias: web uses PATCH for profile updates.
router.patch('/profile', updateProfileHandler);

router.post('/push-token', async (req, res) => {
  const userId = req.user.userId;
  const { token, platform } = req.body || {};
  if (!token || typeof token !== 'string') return res.status(400).json({ error: 'token required' });
  await collection('user_push_tokens').updateOne(
    { user_id: userId },
    { $set: { user_id: userId, token: token.trim(), platform: String(platform || 'android').slice(0, 32), updated_at: new Date() }, $setOnInsert: { created_at: new Date() } },
    { upsert: true }
  );
  res.json({ ok: true });
});

module.exports = router;
