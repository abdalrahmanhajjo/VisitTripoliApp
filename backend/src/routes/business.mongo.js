const crypto = require('crypto');
const express = require('express');
const rateLimit = require('express-rate-limit');
const multer = require('multer');
const { authMiddleware, requireBusinessOwner } = require('../middleware/auth');
const { collection } = require('../db');
const { sanitizeFeedBody, isValidPlaceId, validatePlaceIdParam } = require('../middleware/security');
const { imageFileFilter, videoFileFilter, MAX_IMAGE_SIZE, MAX_VIDEO_SIZE } = require('../middleware/secureUpload');
const { uploadFeedImage, uploadFeedVideo, isConfigured: mediaStorageConfigured } = require('../lib/supabaseStorage');

const router = express.Router();
router.use(authMiddleware);
router.use(requireBusinessOwner);

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: Math.max(MAX_IMAGE_SIZE, MAX_VIDEO_SIZE) },
  fileFilter: (req, file, cb) => {
    if (/^image\//.test(file.mimetype)) return imageFileFilter(req, file, cb);
    if (/^video\//.test(file.mimetype)) return videoFileFilter(req, file, cb);
    return cb(new Error('Invalid file type'));
  },
});

const postLimiter = rateLimit({ windowMs: 60 * 1000, max: 10, message: { error: 'Post limit exceeded.' }, standardHeaders: true });

function getBaseUrl(req) {
  const proto = req.get('x-forwarded-proto') || (req.secure ? 'https' : 'http');
  const host = req.get('x-forwarded-host') || req.get('host') || 'localhost:3000';
  return `${proto}://${host}`;
}
function rowToPost(row, baseUrl) {
  return {
    id: row.id,
    authorName: row.author_name,
    authorPlaceId: row.place_id,
    caption: row.caption,
    imageUrl: row.image_url ? (row.image_url.startsWith('http') ? row.image_url : `${baseUrl}${row.image_url}`) : null,
    videoUrl: row.video_url ? (row.video_url.startsWith('http') ? row.video_url : `${baseUrl}${row.video_url}`) : null,
    type: row.type || 'image',
    createdAt: row.created_at,
  };
}
async function assertOwnsPlace(userId, placeId) {
  const own = await collection('place_owners').findOne({ user_id: userId, place_id: placeId }, { projection: { _id: 1 } });
  if (!own) {
    const err = new Error('You do not own this place');
    err.statusCode = 403;
    throw err;
  }
}

router.get('/places', async (req, res) => {
  const ids = (await collection('place_owners').find({ user_id: req.user.userId }, { projection: { _id: 0, place_id: 1 } }).toArray()).map((x) => x.place_id);
  const rows = await collection('places').find({ id: { $in: ids } }, { projection: { _id: 0 } }).sort({ name: 1 }).toArray();
  res.json(rows);
});

// Web parity endpoint: business profile summary.
router.get('/me', async (req, res) => {
  const user = await collection('users').findOne(
    { id: req.user.userId },
    { projection: { _id: 0, id: 1, name: 1, email: 1, is_business_owner: 1 } },
  );
  if (!user) return res.status(404).json({ error: 'User not found' });
  return res.json(user);
});
router.get('/places/:id', validatePlaceIdParam('id'), async (req, res) => {
  try {
    await assertOwnsPlace(req.user.userId, req.params.id);
    const row = await collection('places').findOne({ id: req.params.id }, { projection: { _id: 0 } });
    if (!row) return res.status(404).json({ error: 'Place not found' });
    return res.json(row);
  } catch (err) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});
router.put('/places/:id', validatePlaceIdParam('id'), async (req, res) => {
  try {
    await assertOwnsPlace(req.user.userId, req.params.id);
    const p = req.body || {};
    const set = { ...p, updated_at: new Date() };
    if (p.images != null) set.images = Array.isArray(p.images) ? p.images : [p.images];
    await collection('places').updateOne({ id: req.params.id }, { $set: set });
    return res.json({ ok: true });
  } catch (err) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

router.get('/feed-posts', async (req, res) => {
  const ids = (await collection('place_owners').find({ user_id: req.user.userId }, { projection: { _id: 0, place_id: 1 } }).toArray()).map((x) => x.place_id);
  const rows = await collection('feed_posts').find({ place_id: { $in: ids } }, { projection: { _id: 0 } }).sort({ created_at: -1 }).limit(100).toArray();
  const baseUrl = getBaseUrl(req);
  res.json(rows.map((r) => rowToPost(r, baseUrl)));
});

// Web parity aliases
router.get('/feed', async (req, res) => {
  req.url = '/feed-posts';
  return router.handle(req, res);
});

router.post('/feed-posts', postLimiter, sanitizeFeedBody, upload.fields([{ name: 'image', maxCount: 1 }, { name: 'video', maxCount: 1 }]), async (req, res) => {
  try {
    const userId = req.user.userId;
    const placeId = ((req.body?.placeId && isValidPlaceId(req.body.placeId)) || (req.body?.place_id && isValidPlaceId(req.body.place_id))) ? (req.body.placeId || req.body.place_id) : null;
    if (!placeId) return res.status(400).json({ error: 'Valid placeId required' });
    await assertOwnsPlace(userId, placeId);
    const user = await collection('users').findOne({ id: userId }, { projection: { _id: 0, name: 1 } });
    const imageFile = req.files?.image?.[0];
    const videoFile = req.files?.video?.[0];
    let imageUrl = null;
    let videoUrl = null;
    let type = 'news';
    if (videoFile) {
      if (!mediaStorageConfigured()) return res.status(503).json({ error: 'Video upload not configured' });
      videoUrl = await uploadFeedVideo(videoFile.buffer, videoFile);
      type = 'video';
    }
    if (imageFile) {
      if (!mediaStorageConfigured()) return res.status(503).json({ error: 'Image upload not configured' });
      imageUrl = await uploadFeedImage(imageFile.buffer, imageFile);
      if (type === 'news') type = 'image';
    }
    const row = {
      id: crypto.randomUUID(),
      user_id: userId,
      author_name: req.body?.authorName || user?.name || 'Business',
      place_id: placeId,
      caption: req.body?.caption || null,
      image_url: imageUrl,
      video_url: videoUrl,
      type,
      author_role: 'business_owner',
      moderation_status: 'approved',
      created_at: new Date(),
      updated_at: new Date(),
    };
    await collection('feed_posts').insertOne(row);
    return res.status(201).json(rowToPost(row, getBaseUrl(req)));
  } catch (err) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

router.post('/feed', postLimiter, sanitizeFeedBody, upload.fields([{ name: 'image', maxCount: 1 }, { name: 'video', maxCount: 1 }]), async (req, res) => {
  req.url = '/feed-posts';
  return router.handle(req, res);
});

// Lightweight compatibility: surface customer proposals in business namespace.
router.get('/proposals', async (req, res) => {
  const ownedIds = (await collection('place_owners').find({ user_id: req.user.userId }, { projection: { _id: 0, place_id: 1 } }).toArray()).map((x) => x.place_id);
  const proposals = await collection('offer_proposals')
    .find({ place_id: { $in: ownedIds } }, { projection: { _id: 0 } })
    .sort({ created_at: -1 })
    .limit(100)
    .toArray();
  return res.json({ proposals });
});

module.exports = router;
