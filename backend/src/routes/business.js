/**
 * Business owner API - manage owned places and feed posts.
 * Auth: JWT (same as app). User must be in place_owners for the place.
 */
const express = require('express');
const rateLimit = require('express-rate-limit');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { authMiddleware, requireBusinessOwner } = require('../middleware/auth');
const { query } = require('../db');
const { sanitizeFeedBody, isValidPlaceId, validatePlaceIdParam, validateUuidParam } = require('../middleware/security');
const { getFeedStorage, getImageUrl, getVideoUrl, imageFileFilter, videoFileFilter, MAX_IMAGE_SIZE, MAX_VIDEO_SIZE } = require('../middleware/secureUpload');

const router = express.Router();
router.use(authMiddleware);
router.use(requireBusinessOwner);

const storage = multer.diskStorage(getFeedStorage());
const upload = multer({
  storage,
  limits: { fileSize: Math.max(MAX_IMAGE_SIZE, MAX_VIDEO_SIZE) },
  fileFilter: (req, file, cb) => {
    const isImage = /^image\//.test(file.mimetype);
    const isVideo = /^video\//.test(file.mimetype);
    if (isImage) return imageFileFilter(req, file, cb);
    if (isVideo) return videoFileFilter(req, file, cb);
    cb(new Error('Invalid file type'));
  },
});

const postLimiter = rateLimit({ windowMs: 60 * 1000, max: 10, message: { error: 'Post limit exceeded.' }, standardHeaders: true });

function getBaseUrl(req) {
  const proto = req.get('x-forwarded-proto') || (req.secure ? 'https' : 'http');
  const host = req.get('x-forwarded-host') || req.get('host') || 'localhost:3000';
  return `${proto}://${host}`;
}

async function assertOwnsPlace(userId, placeId) {
  const r = await query('SELECT 1 FROM place_owners WHERE user_id = $1 AND place_id = $2', [userId, placeId]);
  if (r.rows.length === 0) {
    const err = new Error('You do not own this place');
    err.statusCode = 403;
    throw err;
  }
}

function rowToPlace(row) {
  const images = Array.isArray(row.images) ? row.images : (row.images ? (typeof row.images === 'string' ? JSON.parse(row.images) : row.images) : []);
  return {
    id: row.id,
    name: row.name,
    description: row.description || '',
    location: row.location || '',
    latitude: row.latitude ?? null,
    longitude: row.longitude ?? null,
    images,
    category: row.category || '',
    categoryId: row.category_id,
    duration: row.duration,
    price: row.price,
    bestTime: row.best_time,
    rating: row.rating,
    reviewCount: row.review_count,
    hours: row.hours,
    tags: row.tags,
    searchName: row.search_name,
  };
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

// GET /api/business/places - list places owned by the user
router.get('/places', async (req, res) => {
  try {
    const userId = req.user.userId;
    const r = await query(
      `SELECT p.* FROM places p
       INNER JOIN place_owners po ON po.place_id = p.id
       WHERE po.user_id = $1
       ORDER BY p.name`,
      [userId]
    );
    res.json(r.rows.map(rowToPlace));
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// GET /api/business/places/:id - get one place (must own)
router.get('/places/:id', validatePlaceIdParam('id'), async (req, res) => {
  try {
    await assertOwnsPlace(req.user.userId, req.params.id);
    const r = await query('SELECT * FROM places WHERE id = $1', [req.params.id]);
    if (r.rows.length === 0) return res.status(404).json({ error: 'Place not found' });
    res.json(rowToPlace(r.rows[0]));
  } catch (err) {
    if (err.statusCode) return res.status(err.statusCode).json({ error: err.message });
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/business/places/:id - update place
router.put('/places/:id', validatePlaceIdParam('id'), async (req, res) => {
  try {
    await assertOwnsPlace(req.user.userId, req.params.id);
    const p = req.body;
    const id = req.params.id;
    const images = p.images != null ? (Array.isArray(p.images) ? p.images : [p.images]) : null;
    const lat = p.latitude ?? p.coordinates?.lat;
    const lng = p.longitude ?? p.coordinates?.lng;

    if (images !== null) {
      await query(
        `UPDATE places SET name=$1, description=$2, location=$3, latitude=$4, longitude=$5, images=$6, category=$7, category_id=$8, duration=$9, price=$10, best_time=$11, rating=$12, review_count=$13, tags=$14 WHERE id=$15`,
        [p.name || '', p.description || '', p.location || '', lat ?? null, lng ?? null, JSON.stringify(images),
         p.category || '', p.categoryId || p.category_id || '', p.duration || '', String(p.price ?? ''),
         p.bestTime || p.best_time || '', p.rating ?? null, p.reviewCount ?? p.review_count ?? null,
         JSON.stringify(p.tags || []), id]
      );
    } else {
      await query(
        `UPDATE places SET name=$1, description=$2, location=$3, latitude=$4, longitude=$5, category=$6, category_id=$7, duration=$8, price=$9, best_time=$10, rating=$11, review_count=$12, tags=$13 WHERE id=$14`,
        [p.name || '', p.description || '', p.location || '', lat ?? null, lng ?? null,
         p.category || '', p.categoryId || p.category_id || '', p.duration || '', String(p.price ?? ''),
         p.bestTime || p.best_time || '', p.rating ?? null, p.reviewCount ?? p.review_count ?? null,
         JSON.stringify(p.tags || []), id]
      );
    }
    res.json({ ok: true });
  } catch (err) {
    if (err.statusCode) return res.status(err.statusCode).json({ error: err.message });
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// GET /api/business/feed-posts - list feed posts for the user's places
router.get('/feed-posts', async (req, res) => {
  try {
    const userId = req.user.userId;
    const r = await query(
      `SELECT fp.* FROM feed_posts fp
       INNER JOIN place_owners po ON po.place_id = fp.place_id AND po.user_id = $1
       ORDER BY fp.created_at DESC
       LIMIT 100`,
      [userId]
    );
    const baseUrl = getBaseUrl(req);
    res.json(r.rows.map(row => rowToPost(row, baseUrl)));
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/business/feed-posts - create feed post (multipart)
router.post('/feed-posts', postLimiter, sanitizeFeedBody, upload.fields([{ name: 'image', maxCount: 1 }, { name: 'video', maxCount: 1 }]), async (req, res) => {
  try {
    const userId = req.user.userId;
    const placeId = (req.body?.placeId && isValidPlaceId(req.body.placeId)) || (req.body?.place_id && isValidPlaceId(req.body.place_id)) ? (req.body.placeId || req.body.place_id) : null;
    if (!placeId) return res.status(400).json({ error: 'Valid placeId required' });
    await assertOwnsPlace(userId, placeId);

    const userRow = await query('SELECT name FROM users WHERE id = $1', [userId]);
    const authorName = req.body?.authorName || userRow.rows[0]?.name || 'Business';
    const caption = req.body?.caption || null;
    const imageFile = req.files?.image?.[0];
    const videoFile = req.files?.video?.[0];

    let imageUrl = null;
    let videoUrl = null;
    let type = 'news';
    if (videoFile) {
      videoUrl = getVideoUrl(videoFile.filename);
      type = 'video';
    }
    if (imageFile) {
      imageUrl = getImageUrl(imageFile.filename);
      if (type === 'news') type = 'image';
    }

    const result = await query(
      `INSERT INTO feed_posts (user_id, author_name, place_id, caption, image_url, video_url, type, author_role) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'business_owner') 
       RETURNING id, user_id, author_name, place_id, caption, image_url, video_url, type, created_at`,
      [userId, authorName, placeId, caption || null, imageUrl, videoUrl, type]
    );
    const row = result.rows[0];
    const baseUrl = getBaseUrl(req);
    res.status(201).json(rowToPost(row, baseUrl));
  } catch (err) {
    if (err.statusCode) return res.status(err.statusCode).json({ error: err.message });
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
