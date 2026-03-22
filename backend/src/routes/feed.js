const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const express = require('express');
const rateLimit = require('express-rate-limit');
const multer = require('multer');
const { responseCache, invalidateByPrefix } = require('../middleware/responseCache');
const { authMiddleware, optionalAuthMiddleware } = require('../middleware/auth');
const { query } = require('../db');
const { sanitizeFeedBody, isValidPlaceId } = require('../middleware/security');
const { imageFileFilter, videoFileFilter, MAX_IMAGE_SIZE, MAX_VIDEO_SIZE } = require('../middleware/secureUpload');
const { uploadFeedImage, uploadFeedVideo, isConfigured: supabaseStorageConfigured } = require('../lib/supabaseStorage');

const router = express.Router();
const isProd = process.env.NODE_ENV === 'production';

function absUrl(baseUrl, url) {
  return url && (url.startsWith('http') ? url : `${baseUrl}${url}`);
}
async function getLikeCount(postId) {
  const r = await query('SELECT COUNT(*)::int AS c FROM feed_likes WHERE post_id = $1', [postId]);
  return r.rows[0]?.c ?? 0;
}

const memoryStorage = multer.memoryStorage();
const upload = multer({
  storage: memoryStorage,
  limits: { fileSize: Math.max(MAX_IMAGE_SIZE, MAX_VIDEO_SIZE) },
  fileFilter: (req, file, cb) => {
    const mime = (file.mimetype || '').toLowerCase();
    const ext = path.extname((file.originalname || file.filename || '').toLowerCase());
    const hasImageExt = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);
    const hasVideoExt = ['.mp4', '.webm', '.mov', '.avi', '.mkv', '.3gp', '.ogv', '.mpeg', '.mpg'].includes(ext);

    // Image
    if (mime.startsWith('image/') || (mime === 'application/octet-stream' && hasImageExt)) {
      return imageFileFilter(req, file, cb);
    }
    // Video — any video/* mime, or octet-stream/no-mime with a video extension, or field named 'video'
    if (mime.startsWith('video/') || hasVideoExt || (mime === 'application/octet-stream' && hasVideoExt) || file.fieldname === 'video') {
      return videoFileFilter(req, file, cb);
    }
    cb(new Error('Invalid file type'));
  },
});

// Only run multer for multipart requests so JSON body (caption-only update) is left intact
function optionalUploadImage(req, res, next) {
  const contentType = (req.get('Content-Type') || '').toLowerCase();
  if (contentType.includes('multipart/form-data')) {
    return upload.single('image')(req, res, next);
  }
  next();
}

function getFirstPlaceImage(placeImages, baseUrl) {
  if (!placeImages) return null;
  let arr = placeImages;
  if (typeof arr === 'string') {
    try { arr = JSON.parse(arr); } catch { return null; }
  }
  if (!Array.isArray(arr) || arr.length === 0) return null;
  const first = arr[0];
  if (!first || typeof first !== 'string') return null;
  return first.startsWith('http') ? first : `${baseUrl}${first.startsWith('/') ? '' : '/'}${first}`;
}

function rowToPost(row, baseUrl, extras = {}) {
  return {
    id: row.id,
    authorId: row.user_id != null ? String(row.user_id) : null,
    authorName: row.author_name,
    authorPlaceId: row.place_id,
    authorPlaceName: row.place_name || null,
    authorPlaceImage: getFirstPlaceImage(row.place_images, baseUrl),
    authorRole: row.author_role || 'regular',
    caption: row.caption,
    imageUrl: absUrl(baseUrl, row.image_url),
    videoUrl: absUrl(baseUrl, row.video_url),
    type: row.type || 'image',
    createdAt: row.created_at,
    likeCount: extras.likeCount ?? 0,
    commentCount: extras.commentCount ?? 0,
    likedByMe: extras.likedByMe ?? false,
    savedByMe: extras.savedByMe ?? false,
    hideLikes: row.hide_likes === true,
    commentsDisabled: row.comments_disabled === true,
  };
}

function getBaseUrl(req) {
  const proto = req.get('x-forwarded-proto') || (req.secure ? 'https' : 'http');
  const host = req.get('x-forwarded-host') || req.get('host') || 'localhost:3000';
  return `${proto}://${host}`;
}

// GET /api/feed/can-post - Auth required. Returns whether user can post (admin or business owner).
router.get('/can-post', authMiddleware, async (req, res) => {
  try {
    const userId = req.user?.userId;
    const user = (await query('SELECT is_admin, is_business_owner FROM users WHERE id = $1', [userId])).rows[0];
    const payload = { canPost: false, isAdmin: false, isBusinessOwner: false, ownedPlaces: [] };
    if (!user) return res.json(payload);
    if (user.is_admin) return res.json({ ...payload, canPost: true, isAdmin: true });
    if (!user.is_business_owner) return res.json(payload);
    try {
      const placesRow = await query(
        'SELECT po.place_id, p.name FROM place_owners po JOIN places p ON p.id = po.place_id WHERE po.user_id = $1',
        [userId]
      );
      const ownedPlaces = placesRow.rows.map(r => ({ id: r.place_id, name: r.name }));
      return res.json({ ...payload, canPost: ownedPlaces.length > 0, isBusinessOwner: true, ownedPlaces });
    } catch {
      return res.json({ ...payload, isBusinessOwner: true });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to check post permission' });
  }
});

// GET /api/feed - Public; optional auth for likedByMe.
// sort=recent (default): cursor "before" = post id, chronological newest first.
// sort=trending: engagement score (likes + 2×comments), paginated with "offset" (max 800).
const FEED_LIMIT_DEFAULT = 20;
const FEED_LIMIT_MAX = 50;
const FEED_TRENDING_MAX_OFFSET = 800;

const FEED_POST_SELECT = `p.id, p.user_id, p.author_name, p.place_id, pl.name AS place_name, pl.images AS place_images, p.author_role, p.caption, p.image_url, p.video_url, p.type, p.created_at, p.hide_likes, p.comments_disabled`;

router.get('/', optionalAuthMiddleware, responseCache(30 * 1000, {
  key: (req) => `feed:${req.user?.userId || 'anon'}:${req.query.sort || 'recent'}:${req.query.limit || FEED_LIMIT_DEFAULT}:${req.query.before || ''}:${req.query.offset || '0'}`,
  getTtlMs: (req) => (req.user?.userId ? 0 : 30 * 1000),
}), async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || FEED_LIMIT_DEFAULT, FEED_LIMIT_MAX);
    const before = (req.query.before || '').toString().trim();
    const sort = ((req.query.sort || 'recent').toString().toLowerCase() === 'trending') ? 'trending' : 'recent';
    const offset = Math.min(Math.max(0, parseInt(req.query.offset, 10) || 0), FEED_TRENDING_MAX_OFFSET);
    const baseUrl = getBaseUrl(req);
    const userId = req.user?.userId || null;

    const baseWhere = `(p.author_role IN ('admin', 'business_owner') OR (p.author_role IS NULL AND p.place_id IS NOT NULL))`;

    let result;
    if (sort === 'trending') {
      result = await query(
        `SELECT ${FEED_POST_SELECT},
          (
            (SELECT COUNT(*)::float FROM feed_likes fl WHERE fl.post_id = p.id) +
            2 * (SELECT COUNT(*)::float FROM feed_comments fc WHERE fc.post_id = p.id)
          ) AS engagement_score
         FROM feed_posts p
         LEFT JOIN places pl ON pl.id = p.place_id
         WHERE ${baseWhere}
         ORDER BY engagement_score DESC, p.created_at DESC, p.id DESC
         LIMIT $1 OFFSET $2`,
        [limit, offset]
      );
    } else if (before) {
      result = await query(
        `SELECT ${FEED_POST_SELECT}
         FROM feed_posts p
         LEFT JOIN places pl ON pl.id = p.place_id
         CROSS JOIN (SELECT created_at AS ref_created_at, id AS ref_id FROM feed_posts WHERE id = $1 LIMIT 1) ref
         WHERE ${baseWhere}
           AND (p.created_at, p.id) < (ref.ref_created_at, ref.ref_id)
         ORDER BY p.created_at DESC, p.id DESC
         LIMIT $2`,
        [before, limit]
      );
    } else {
      result = await query(
        `SELECT ${FEED_POST_SELECT}
         FROM feed_posts p
         LEFT JOIN places pl ON pl.id = p.place_id
         WHERE ${baseWhere}
         ORDER BY p.created_at DESC
         LIMIT $1`,
        [limit]
      );
    }

    if (result.rows.length === 0) {
      return res.json({
        posts: [],
        nextCursor: null,
        nextOffset: sort === 'trending' ? offset : null,
        hasMore: false,
        sort,
      });
    }
    const postIds = result.rows.map(r => r.id);

    const [likeCounts, commentCounts, likedByUser, savedByUser] = await Promise.all([
      query('SELECT post_id, COUNT(*)::int AS c FROM feed_likes WHERE post_id = ANY($1) GROUP BY post_id', [postIds]),
      query('SELECT post_id, COUNT(*)::int AS c FROM feed_comments WHERE post_id = ANY($1) GROUP BY post_id', [postIds]),
      userId ? query('SELECT post_id FROM feed_likes WHERE user_id = $1 AND post_id = ANY($2)', [userId, postIds]) : Promise.resolve({ rows: [] }),
      userId ? query('SELECT post_id FROM feed_saves WHERE user_id = $1 AND post_id = ANY($2)', [userId, postIds]) : Promise.resolve({ rows: [] }),
    ]);
    const likeMap = Object.fromEntries(likeCounts.rows.map(r => [r.post_id, r.c]));
    const commentMap = Object.fromEntries(commentCounts.rows.map(r => [r.post_id, r.c]));
    const likedSet = new Set((likedByUser.rows || []).map(r => r.post_id));
    const savedSet = new Set((savedByUser.rows || []).map(r => r.post_id));

    const posts = result.rows.map(r => rowToPost(r, baseUrl, {
      likeCount: likeMap[r.id] ?? 0,
      commentCount: commentMap[r.id] ?? 0,
      likedByMe: likedSet.has(r.id),
      savedByMe: savedSet.has(r.id),
    }));

    let nextCursor = null;
    let nextOffset = null;
    let hasMore = false;
    if (sort === 'trending') {
      const newOffset = offset + result.rows.length;
      hasMore = result.rows.length === limit && newOffset < FEED_TRENDING_MAX_OFFSET;
      nextOffset = hasMore ? newOffset : null;
    } else {
      const last = result.rows[result.rows.length - 1];
      hasMore = result.rows.length === limit;
      nextCursor = hasMore ? last.id : null;
    }
    res.json({ posts, nextCursor, nextOffset, hasMore, sort });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch feed', ...(isProd ? {} : { detail: err.message }) });
  }
});

// GET /api/feed/reels - Paginated feed strictly for videos
router.get('/reels', optionalAuthMiddleware, async (req, res) => {
  try {
    const { before, limit = '20' } = req.query;
    const limitNum = Math.min(parseInt(limit, 10) || 20, 50);
    const userId = req.user?.userId || null;

    let queryStr = `SELECT p.id, p.user_id, p.author_name, p.place_id, pl.name AS place_name, pl.images AS place_images, p.author_role, p.caption, p.image_url, p.video_url, p.type, p.created_at, p.hide_likes, p.comments_disabled
                    FROM feed_posts p
                    LEFT JOIN places pl ON pl.id = p.place_id
                    WHERE p.type = 'video'`;
    let params = [];
    if (before) {
      queryStr += ` AND p.created_at < $1`;
      params.push(before);
    }
    queryStr += ` ORDER BY p.created_at DESC LIMIT $${params.length + 1}`;
    params.push(limitNum);

    const result = await query(queryStr, params);
    if (result.rows.length === 0) {
      return res.json({ posts: [], hasMore: false, nextCursor: null });
    }

    const postIds = result.rows.map(r => r.id);
    const [likeCounts, commentCounts, likedByUser, savedByUser] = await Promise.all([
      query('SELECT post_id, COUNT(*)::int AS c FROM feed_likes WHERE post_id = ANY($1) GROUP BY post_id', [postIds]),
      query('SELECT post_id, COUNT(*)::int AS c FROM feed_comments WHERE post_id = ANY($1) GROUP BY post_id', [postIds]),
      userId ? query('SELECT post_id FROM feed_likes WHERE user_id = $1 AND post_id = ANY($2)', [userId, postIds]) : Promise.resolve({ rows: [] }),
      userId ? query('SELECT post_id FROM feed_saves WHERE user_id = $1 AND post_id = ANY($2)', [userId, postIds]) : Promise.resolve({ rows: [] }),
    ]);

    const likeMap = Object.fromEntries(likeCounts.rows.map(r => [r.post_id, r.c]));
    const commentMap = Object.fromEntries(commentCounts.rows.map(r => [r.post_id, r.c]));
    const likedSet = new Set((likedByUser.rows || []).map(r => r.post_id));
    const savedSet = new Set((savedByUser.rows || []).map(r => r.post_id));

    const baseUrl = getBaseUrl(req);
    const posts = result.rows.map(r => rowToPost(r, baseUrl, {
      likeCount: likeMap[r.id] ?? 0,
      commentCount: commentMap[r.id] ?? 0,
      likedByMe: likedSet.has(r.id),
      savedByMe: savedSet.has(r.id),
    }));

    const last = result.rows[result.rows.length - 1];
    const nextCursor = result.rows.length === limitNum ? last.created_at : null;

    res.json({ posts, nextCursor, hasMore: !!nextCursor });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch reels', ...(isProd ? {} : { detail: err.message }) });
  }
});

// GET /api/feed/saved - Auth required. Returns posts the user has saved, paginated (newest first).
router.get('/saved', authMiddleware, async (req, res) => {
  try {
    const userId = req.user?.userId;
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const limit = Math.min(parseInt(req.query.limit, 10) || FEED_LIMIT_DEFAULT, FEED_LIMIT_MAX);
    const before = (req.query.before || '').toString().trim();
    const baseUrl = getBaseUrl(req);

    let result;
    if (before) {
      result = await query(
        `SELECT p.id, p.user_id, p.author_name, p.place_id, pl.name AS place_name, pl.images AS place_images, p.author_role, p.caption, p.image_url, p.video_url, p.type, p.created_at, p.hide_likes, p.comments_disabled
         FROM feed_posts p
         LEFT JOIN places pl ON pl.id = p.place_id
         INNER JOIN feed_saves s ON s.post_id = p.id AND s.user_id = $1
         CROSS JOIN (SELECT created_at AS ref_created_at, id AS ref_id FROM feed_posts WHERE id = $2 LIMIT 1) ref
         WHERE (p.created_at, p.id) < (ref.ref_created_at, ref.ref_id)
         ORDER BY p.created_at DESC, p.id DESC
         LIMIT $3`,
        [userId, before, limit]
      );
    } else {
      result = await query(
        `SELECT p.id, p.user_id, p.author_name, p.place_id, pl.name AS place_name, pl.images AS place_images, p.author_role, p.caption, p.image_url, p.video_url, p.type, p.created_at, p.hide_likes, p.comments_disabled
         FROM feed_posts p
         LEFT JOIN places pl ON pl.id = p.place_id
         INNER JOIN feed_saves s ON s.post_id = p.id AND s.user_id = $1
         ORDER BY p.created_at DESC, p.id DESC
         LIMIT $2`,
        [userId, limit]
      );
    }

    if (result.rows.length === 0) {
      return res.json({ posts: [], nextCursor: null, hasMore: false });
    }
    const postIds = result.rows.map(r => r.id);

    const [likeCounts, commentCounts, likedByUser] = await Promise.all([
      query('SELECT post_id, COUNT(*)::int AS c FROM feed_likes WHERE post_id = ANY($1) GROUP BY post_id', [postIds]),
      query('SELECT post_id, COUNT(*)::int AS c FROM feed_comments WHERE post_id = ANY($1) GROUP BY post_id', [postIds]),
      query('SELECT post_id FROM feed_likes WHERE user_id = $1 AND post_id = ANY($2)', [userId, postIds]),
    ]);
    const likeMap = Object.fromEntries(likeCounts.rows.map(r => [r.post_id, r.c]));
    const commentMap = Object.fromEntries(commentCounts.rows.map(r => [r.post_id, r.c]));
    const likedSet = new Set((likedByUser.rows || []).map(r => r.post_id));

    const posts = result.rows.map(r => rowToPost(r, baseUrl, {
      likeCount: likeMap[r.id] ?? 0,
      commentCount: commentMap[r.id] ?? 0,
      likedByMe: likedSet.has(r.id),
      savedByMe: true,
    }));
    const last = result.rows[result.rows.length - 1];
    const nextCursor = result.rows.length === limit ? last.id : null;
    res.json({ posts, nextCursor, hasMore: !!nextCursor });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch saved feed', ...(isProd ? {} : { detail: err.message }) });
  }
});

// GET /api/feed/liked - Paginated liked feed. Auth required.
router.get('/liked', authMiddleware, async (req, res) => {
  try {
    const userId = req.user?.userId;
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const limit = Math.min(parseInt(req.query.limit, 10) || FEED_LIMIT_DEFAULT, FEED_LIMIT_MAX);
    const before = (req.query.before || '').toString().trim();
    const baseUrl = getBaseUrl(req);

    let result;
    if (before) {
      result = await query(
        `SELECT p.id, p.user_id, p.author_name, p.place_id, pl.name AS place_name, pl.images AS place_images, p.author_role, p.caption, p.image_url, p.video_url, p.type, p.created_at, p.hide_likes, p.comments_disabled
         FROM feed_posts p
         LEFT JOIN places pl ON pl.id = p.place_id
         INNER JOIN feed_likes l ON l.post_id = p.id AND l.user_id = $1
         CROSS JOIN (SELECT created_at AS ref_created_at, id AS ref_id FROM feed_posts WHERE id = $2 LIMIT 1) ref
         WHERE (p.created_at, p.id) < (ref.ref_created_at, ref.ref_id)
         ORDER BY p.created_at DESC, p.id DESC
         LIMIT $3`,
        [userId, before, limit]
      );
    } else {
      result = await query(
        `SELECT p.id, p.user_id, p.author_name, p.place_id, pl.name AS place_name, pl.images AS place_images, p.author_role, p.caption, p.image_url, p.video_url, p.type, p.created_at, p.hide_likes, p.comments_disabled
         FROM feed_posts p
         LEFT JOIN places pl ON pl.id = p.place_id
         INNER JOIN feed_likes l ON l.post_id = p.id AND l.user_id = $1
         ORDER BY p.created_at DESC, p.id DESC
         LIMIT $2`,
        [userId, limit]
      );
    }

    if (result.rows.length === 0) {
      return res.json({ posts: [], nextCursor: null, hasMore: false });
    }
    const postIds = result.rows.map(r => r.id);

    const [likeCounts, commentCounts, savedByUser] = await Promise.all([
      query('SELECT post_id, COUNT(*)::int AS c FROM feed_likes WHERE post_id = ANY($1) GROUP BY post_id', [postIds]),
      query('SELECT post_id, COUNT(*)::int AS c FROM feed_comments WHERE post_id = ANY($1) GROUP BY post_id', [postIds]),
      query('SELECT post_id FROM feed_saves WHERE user_id = $1 AND post_id = ANY($2)', [userId, postIds]),
    ]);
    const likeMap = Object.fromEntries(likeCounts.rows.map(r => [r.post_id, r.c]));
    const commentMap = Object.fromEntries(commentCounts.rows.map(r => [r.post_id, r.c]));
    const savedSet = new Set((savedByUser.rows || []).map(r => r.post_id));

    const posts = result.rows.map(r => rowToPost(r, baseUrl, {
      likeCount: likeMap[r.id] ?? 0,
      commentCount: commentMap[r.id] ?? 0,
      likedByMe: true,
      savedByMe: savedSet.has(r.id),
    }));
    const last = result.rows[result.rows.length - 1];
    const nextCursor = result.rows.length === limit ? last.id : null;
    res.json({ posts, nextCursor, hasMore: !!nextCursor });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch liked feed', ...(isProd ? {} : { detail: err.message }) });
  }
});

// GET /api/feed/place/:placeId — Posts for one place (grid / “stories”). Public; optional auth for likedByMe.
router.get('/place/:placeId', optionalAuthMiddleware, responseCache(30 * 1000, {
  key: (req) => `feed:${req.user?.userId || 'anon'}:place:${req.params.placeId}:${req.query.limit || FEED_LIMIT_DEFAULT}:${req.query.before || ''}`,
  getTtlMs: (req) => (req.user?.userId ? 0 : 30 * 1000),
}), async (req, res) => {
  try {
    const placeId = req.params.placeId;
    if (!isValidPlaceId(placeId)) {
      return res.status(400).json({ error: 'Invalid place id' });
    }
    const limit = Math.min(parseInt(req.query.limit, 10) || FEED_LIMIT_DEFAULT, FEED_LIMIT_MAX);
    const before = (req.query.before || '').toString().trim();
    const baseUrl = getBaseUrl(req);
    const userId = req.user?.userId || null;

    const placeRow = (await query('SELECT name, images FROM places WHERE id = $1', [placeId])).rows[0];
    const placePayload = placeRow
      ? { name: placeRow.name || 'Place', image: getFirstPlaceImage(placeRow.images, baseUrl) }
      : { name: 'Place', image: null };

    let result;
    if (before) {
      result = await query(
        `SELECT p.id, p.user_id, p.author_name, p.place_id, pl.name AS place_name, pl.images AS place_images, p.author_role, p.caption, p.image_url, p.video_url, p.type, p.created_at, p.hide_likes, p.comments_disabled
         FROM feed_posts p
         LEFT JOIN places pl ON pl.id = p.place_id
         CROSS JOIN (SELECT created_at AS ref_created_at, id AS ref_id FROM feed_posts WHERE id = $1 LIMIT 1) ref
         WHERE p.place_id = $2
           AND (p.author_role IN ('admin', 'business_owner') OR (p.author_role IS NULL AND p.place_id IS NOT NULL))
           AND (p.created_at, p.id) < (ref.ref_created_at, ref.ref_id)
         ORDER BY p.created_at DESC, p.id DESC
         LIMIT $3`,
        [before, placeId, limit]
      );
    } else {
      result = await query(
        `SELECT p.id, p.user_id, p.author_name, p.place_id, pl.name AS place_name, pl.images AS place_images, p.author_role, p.caption, p.image_url, p.video_url, p.type, p.created_at, p.hide_likes, p.comments_disabled
         FROM feed_posts p
         LEFT JOIN places pl ON pl.id = p.place_id
         WHERE p.place_id = $1
           AND (p.author_role IN ('admin', 'business_owner') OR (p.author_role IS NULL AND p.place_id IS NOT NULL))
         ORDER BY p.created_at DESC, p.id DESC
         LIMIT $2`,
        [placeId, limit]
      );
    }

    if (result.rows.length === 0) {
      return res.json({ posts: [], nextCursor: null, hasMore: false, place: placePayload });
    }
    const postIds = result.rows.map(r => r.id);

    const [likeCounts, commentCounts, likedByUser, savedByUser] = await Promise.all([
      query('SELECT post_id, COUNT(*)::int AS c FROM feed_likes WHERE post_id = ANY($1) GROUP BY post_id', [postIds]),
      query('SELECT post_id, COUNT(*)::int AS c FROM feed_comments WHERE post_id = ANY($1) GROUP BY post_id', [postIds]),
      userId ? query('SELECT post_id FROM feed_likes WHERE user_id = $1 AND post_id = ANY($2)', [userId, postIds]) : Promise.resolve({ rows: [] }),
      userId ? query('SELECT post_id FROM feed_saves WHERE user_id = $1 AND post_id = ANY($2)', [userId, postIds]) : Promise.resolve({ rows: [] }),
    ]);
    const likeMap = Object.fromEntries(likeCounts.rows.map(r => [r.post_id, r.c]));
    const commentMap = Object.fromEntries(commentCounts.rows.map(r => [r.post_id, r.c]));
    const likedSet = new Set((likedByUser.rows || []).map(r => r.post_id));
    const savedSet = new Set((savedByUser.rows || []).map(r => r.post_id));

    const posts = result.rows.map(r => rowToPost(r, baseUrl, {
      likeCount: likeMap[r.id] ?? 0,
      commentCount: commentMap[r.id] ?? 0,
      likedByMe: likedSet.has(r.id),
      savedByMe: savedSet.has(r.id),
    }));
    const last = result.rows[result.rows.length - 1];
    const nextCursor = result.rows.length === limit ? last.id : null;
    res.json({ posts, nextCursor, hasMore: !!nextCursor, place: placePayload });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch place feed', ...(isProd ? {} : { detail: err.message }) });
  }
});

const postLimiter = rateLimit({ windowMs: 60 * 1000, max: 10, message: { error: 'Post limit exceeded. Try again later.' }, standardHeaders: true });
// POST /api/feed - Auth required. Only admins and business owners can post.
router.post('/', postLimiter, authMiddleware, sanitizeFeedBody, upload.fields([{ name: 'image', maxCount: 1 }, { name: 'video', maxCount: 1 }]), async (req, res) => {
  try {
    const userId = req.user?.userId;
    const placeId = req.body?.placeId && isValidPlaceId(req.body.placeId) ? req.body.placeId : null;

    const userRow = await query('SELECT id, name, is_admin, is_business_owner FROM users WHERE id = $1', [userId]);
    const user = userRow.rows[0];
    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }

    let authorRole = null;
    if (user.is_admin) {
      authorRole = 'admin';
    } else if (!user.is_business_owner) {
      return res.status(403).json({ error: 'Only business owners can post to the feed. Regular users cannot post.' });
    } else if (placeId) {
      const own = await query('SELECT 1 FROM place_owners WHERE user_id = $1 AND place_id = $2', [userId, placeId]);
      if (own.rows.length === 0) {
        return res.status(403).json({ error: 'Only admins and business owners can post. You must own this place to post.' });
      }
      authorRole = 'business_owner';
    } else {
      return res.status(403).json({ error: 'Business owners must select a place to post to.' });
    }

    const authorName = req.body?.authorName || user.name || 'User';
    const caption = req.body?.caption || null;
    const imageFile = req.files?.image?.[0];
    const videoFile = req.files?.video?.[0];

    let imageUrl = null;
    let videoUrl = null;
    let type = 'news';
    if (videoFile) {
      if (!supabaseStorageConfigured()) {
        return res.status(503).json({ error: 'Video upload requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY' });
      }
      videoUrl = await uploadFeedVideo(videoFile.buffer, videoFile);
      type = 'video';
    }
    if (imageFile) {
      if (!supabaseStorageConfigured()) {
        return res.status(503).json({ error: 'Feed image upload requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY' });
      }
      imageUrl = await uploadFeedImage(imageFile.buffer, imageFile);
      if (type === 'news') type = 'image';
    }

    const result = await query(
      `INSERT INTO feed_posts (user_id, author_name, place_id, caption, image_url, video_url, type, author_role) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
       RETURNING id, user_id, author_name, place_id, author_role, caption, image_url, video_url, type, created_at`,
      [userId, authorName, placeId || null, caption || null, imageUrl, videoUrl, type, authorRole]
    );
    let row = result.rows[0];
    if (placeId) {
      const placeRow = (await query('SELECT name, images FROM places WHERE id = $1', [placeId])).rows[0];
      if (placeRow) {
        row = { ...row, place_name: placeRow.name, place_images: placeRow.images };
      }
    }
    const baseUrl = getBaseUrl(req);
    res.status(201).json(rowToPost(row, baseUrl, { likeCount: 0, commentCount: 0, likedByMe: false, savedByMe: false }));
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create post', ...(isProd ? {} : { detail: err.message }) });
  }
});

// POST /api/feed/:id/like - Auth required. Toggle like.
router.post('/:id/like', authMiddleware, async (req, res) => {
  try {
    const { id: postId } = req.params;
    const userId = req.user?.userId;
    if (!userId) return res.status(401).json({ error: 'Authentication required' });
    const exists = (await query('SELECT 1 FROM feed_likes WHERE post_id = $1 AND user_id = $2', [postId, userId])).rows.length > 0;
    if (exists) {
      await query('DELETE FROM feed_likes WHERE post_id = $1 AND user_id = $2', [postId, userId]);
    } else {
      await query('INSERT INTO feed_likes (post_id, user_id) VALUES ($1, $2)', [postId, userId]);
    }
    invalidateByPrefix(`feed:${userId}:`);
    res.json({ liked: !exists, likeCount: await getLikeCount(postId) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to update like' });
  }
});

// GET /api/feed/:id/comments - List comments for a post (public). Paginated: limit + offset (max 200).
router.get('/:id/comments', async (req, res) => {
  try {
    let userId = null;
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const jwt = require('jsonwebtoken');
        const decoded = jwt.verify(authHeader.split(' ')[1], process.env.JWT_SECRET || 'safedefaultsecret123');
        userId = decoded.userId;
      } catch (e) {}
    }

    const limit = Math.min(parseInt(req.query.limit, 10) || 40, 200);
    const offset = Math.max(0, parseInt(req.query.offset, 10) || 0);
    const order = (req.query.order || 'desc').toString().toLowerCase() === 'asc' ? 'ASC' : 'DESC';

    const result = await query(
      `SELECT c.id, c.post_id, c.user_id, c.author_name, c.body, c.created_at, c.parent_comment_id, c.updated_at,
        (SELECT author_name FROM feed_comments pc WHERE pc.id = c.parent_comment_id) AS parent_author_name,
        (SELECT COUNT(*)::int FROM feed_comment_likes l WHERE l.comment_id = c.id) as like_count,
        EXISTS(SELECT 1 FROM feed_comment_likes l WHERE l.comment_id = c.id AND l.user_id = $2) as liked_by_me
       FROM feed_comments c 
       WHERE c.post_id = $1 
       ORDER BY c.created_at ${order}, c.id ${order}
       LIMIT $3 OFFSET $4`,
      [req.params.id, userId, limit, offset]
    );
    const countRow = await query(
      'SELECT COUNT(*)::int AS c FROM feed_comments WHERE post_id = $1',
      [req.params.id]
    );
    const total = countRow.rows[0]?.c ?? 0;
    const nextOffset = offset + result.rows.length;
    const hasMore = nextOffset < total;

    const comments = result.rows.map(r => ({
      id: r.id, postId: r.post_id, userId: r.user_id, authorName: r.author_name, body: r.body, createdAt: r.created_at,
      parentCommentId: r.parent_comment_id, parentAuthorName: r.parent_author_name, updatedAt: r.updated_at,
      likeCount: r.like_count || 0, likedByMe: r.liked_by_me || false
    }));
    res.json({ comments, total, nextOffset: hasMore ? nextOffset : null, hasMore });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch comments' });
  }
});

// POST /api/feed/:id/comments - Auth required. Add comment.
router.post('/:id/comments', authMiddleware, async (req, res) => {
  try {
    const postId = req.params.id;
    const postRow = (await query('SELECT comments_disabled, user_id FROM feed_posts WHERE id = $1', [postId])).rows[0];
    if (!postRow) return res.status(404).json({ error: 'Post not found' });
    if (postRow.comments_disabled) return res.status(403).json({ error: 'Comments are turned off for this post' });
    const body = (req.body?.body ?? req.body?.text ?? '').toString().trim();
    if (!body || body.length > 2000) return res.status(400).json({ error: 'Comment must be 1–2000 characters' });
    const userId = req.user?.userId;
    const authorName = (await query('SELECT name FROM users WHERE id = $1', [userId])).rows[0]?.name || 'User';
    let parentCommentId = (req.body?.parentCommentId ?? req.body?.parent_comment_id ?? '').toString().trim() || null;
    if (parentCommentId) {
      const parentRow = (await query('SELECT id, post_id FROM feed_comments WHERE id = $1', [parentCommentId])).rows[0];
      if (!parentRow || parentRow.post_id !== postId) {
        parentCommentId = null;
      }
    }
    const r = (await query(
      `INSERT INTO feed_comments (post_id, user_id, author_name, body, parent_comment_id)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, post_id, user_id, author_name, body, created_at, parent_comment_id`,
      [postId, userId, authorName, body, parentCommentId]
    )).rows[0];
    let parentAuthorName = null;
    if (r.parent_comment_id) {
      parentAuthorName = (await query('SELECT author_name FROM feed_comments WHERE id = $1', [r.parent_comment_id])).rows[0]?.author_name || null;
    }
    res.status(201).json({
      id: r.id, postId: r.post_id, userId: r.user_id, authorName: r.author_name, body: r.body, createdAt: r.created_at,
      parentCommentId: r.parent_comment_id, parentAuthorName,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to add comment' });
  }
});

// DELETE /api/feed/comments/:commentId - Auth required. Delete own comment OR post owner can delete any comment on their post.
router.delete('/comments/:commentId', authMiddleware, async (req, res) => {
  try {
    const { commentId } = req.params;
    const userId = req.user?.userId;
    const commentRow = (await query('SELECT c.id, c.post_id, c.user_id, p.user_id AS post_owner FROM feed_comments c JOIN feed_posts p ON p.id = c.post_id WHERE c.id = $1', [commentId])).rows[0];
    if (!commentRow) return res.status(404).json({ error: 'Comment not found' });
    const isCommentAuthor = commentRow.user_id === userId;
    const isPostOwner = commentRow.post_owner === userId;
    const isAdmin = (await query('SELECT is_admin FROM users WHERE id = $1', [userId])).rows[0]?.is_admin;
    if (!isCommentAuthor && !isPostOwner && !isAdmin) return res.status(403).json({ error: 'You can only delete your own comments or comments on your posts' });
    await query('DELETE FROM feed_comments WHERE id = $1', [commentId]);
    res.json({ deleted: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to delete comment' });
  }
});

// POST /api/feed/comments/:commentId/like - Auth required. Toggle comment like.
router.post('/comments/:commentId/like', authMiddleware, async (req, res) => {
  try {
    const { commentId } = req.params;
    const userId = req.user?.userId;
    const exists = (await query('SELECT 1 FROM feed_comment_likes WHERE comment_id = $1 AND user_id = $2', [commentId, userId])).rows.length > 0;
    if (exists) {
      await query('DELETE FROM feed_comment_likes WHERE comment_id = $1 AND user_id = $2', [commentId, userId]);
    } else {
      await query('INSERT INTO feed_comment_likes (comment_id, user_id) VALUES ($1, $2)', [commentId, userId]);
    }
    const count = (await query('SELECT COUNT(*)::int FROM feed_comment_likes WHERE comment_id = $1', [commentId])).rows[0].count;
    res.json({ liked: !exists, likeCount: count });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to update comment like' });
  }
});

// PATCH /api/feed/comments/:commentId - Auth required. Edit comment.
router.patch('/comments/:commentId', authMiddleware, async (req, res) => {
  try {
    const { commentId } = req.params;
    const userId = req.user?.userId;
    const body = (req.body?.body ?? req.body?.text ?? '').toString().trim();
    if (!body || body.length > 2000) return res.status(400).json({ error: 'Comment must be 1–2000 characters' });
    
    // Ensure the user actually owns this comment
    const commentOwner = (await query('SELECT user_id FROM feed_comments WHERE id = $1', [commentId])).rows[0];
    if (!commentOwner) return res.status(404).json({ error: 'Comment not found' });
    if (commentOwner.user_id !== userId) return res.status(403).json({ error: 'You can only edit your own comments' });

    const edited = (await query('UPDATE feed_comments SET body = $1, updated_at = now() WHERE id = $2 RETURNING *', [body, commentId])).rows[0];
    res.json({ id: edited.id, postId: edited.post_id, userId: edited.user_id, authorName: edited.author_name, body: edited.body, createdAt: edited.created_at, updatedAt: edited.updated_at });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to edit comment' });
  }
});

// POST /api/feed/:id/report - Auth required. Report a post (Instagram-like).
router.post('/:id/report', authMiddleware, async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.user?.userId;
    const reason = (req.body?.reason ?? 'inappropriate').toString().trim().slice(0, 50);
    const postRow = (await query('SELECT user_id FROM feed_posts WHERE id = $1', [postId])).rows[0];
    if (!postRow) return res.status(404).json({ error: 'Post not found' });
    if (postRow.user_id === userId) return res.status(400).json({ error: 'You cannot report your own post' });
    await query(
      'INSERT INTO feed_reports (post_id, user_id, reason) VALUES ($1, $2, $3) ON CONFLICT (post_id, user_id) DO NOTHING',
      [postId, userId, reason || null]
    );
    res.json({ reported: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to report post' });
  }
});

// POST /api/feed/:id/save - Auth required. Toggle save (bookmark).
router.post('/:id/save', authMiddleware, async (req, res) => {
  try {
    const { id: postId } = req.params;
    const userId = req.user?.userId;
    if (!userId) return res.status(401).json({ error: 'Authentication required' });
    const exists = (await query('SELECT 1 FROM feed_saves WHERE post_id = $1 AND user_id = $2', [postId, userId])).rows.length > 0;
    if (exists) {
      await query('DELETE FROM feed_saves WHERE post_id = $1 AND user_id = $2', [postId, userId]);
    } else {
      await query('INSERT INTO feed_saves (post_id, user_id) VALUES ($1, $2)', [postId, userId]);
    }
    invalidateByPrefix(`feed:${userId}:`);
    res.json({ saved: !exists });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to update save' });
  }
});

// PUT /api/feed/:id - Auth required. Edit post (caption, image: add/replace/remove). Author or admin.
router.put('/:id', authMiddleware, optionalUploadImage, async (req, res) => {
  try {
    const { id: postId } = req.params;
    const userId = req.user?.userId;
    const body = req.body || {};
    const caption = (body.caption != null ? body.caption : '').toString().trim();
    const removeImage = body.removeImage === 'true' || body.removeImage === true;

    const row = (await query('SELECT user_id, image_url, video_url, type FROM feed_posts WHERE id = $1', [postId])).rows[0];
    if (!row) return res.status(404).json({ error: 'Post not found' });
    const isAdmin = (await query('SELECT is_admin FROM users WHERE id = $1', [userId])).rows[0]?.is_admin;
    if (row.user_id !== userId && !isAdmin) return res.status(403).json({ error: 'You can only edit your own posts' });

    let imageUrl = removeImage ? null : row.image_url;
    let type = row.type || 'image';
    if (removeImage) type = row.video_url ? 'video' : 'news';
    if (req.file) {
      if (!supabaseStorageConfigured()) {
        return res.status(503).json({ error: 'Feed image upload requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY' });
      }
      imageUrl = await uploadFeedImage(req.file.buffer, req.file);
      type = 'image';
    }

    await query('UPDATE feed_posts SET caption = $1, image_url = $2, type = $3 WHERE id = $4', [caption || null, imageUrl, type, postId]);
    const [updated, likeCounts, commentCounts, likedByUser, savedByUser] = await Promise.all([
      query('SELECT p.id, p.user_id, p.author_name, p.place_id, pl.name AS place_name, pl.images AS place_images, p.author_role, p.caption, p.image_url, p.video_url, p.type, p.created_at, p.hide_likes, p.comments_disabled FROM feed_posts p LEFT JOIN places pl ON pl.id = p.place_id WHERE p.id = $1', [postId]),
      query('SELECT post_id, COUNT(*)::int AS c FROM feed_likes WHERE post_id = $1 GROUP BY post_id', [postId]),
      query('SELECT post_id, COUNT(*)::int AS c FROM feed_comments WHERE post_id = $1 GROUP BY post_id', [postId]),
      userId ? query('SELECT post_id FROM feed_likes WHERE user_id = $1 AND post_id = $2', [userId, postId]) : Promise.resolve({ rows: [] }),
      userId ? query('SELECT post_id FROM feed_saves WHERE user_id = $1 AND post_id = $2', [userId, postId]) : Promise.resolve({ rows: [] }),
    ]);
    const baseUrl = getBaseUrl(req);
    res.json(rowToPost(updated.rows[0], baseUrl, {
      likeCount: likeCounts.rows[0]?.c ?? 0,
      commentCount: commentCounts.rows[0]?.c ?? 0,
      likedByMe: (likedByUser.rows || []).length > 0,
      savedByMe: (savedByUser.rows || []).length > 0,
    }));
  } catch (err) {
    console.error('PUT /api/feed/:id error:', err);
    res.status(err.statusCode || 500).json({ error: isProd ? 'Failed to update post' : (err.message || 'Failed to update post') });
  }
});

// PATCH /api/feed/:id/options - Auth required. Toggle hideLikes, commentsDisabled. Author or admin.
router.patch('/:id/options', authMiddleware, async (req, res) => {
  try {
    const { id: postId } = req.params;
    const userId = req.user?.userId;
    const body = req.body || {};
    const row = (await query('SELECT user_id FROM feed_posts WHERE id = $1', [postId])).rows[0];
    if (!row) return res.status(404).json({ error: 'Post not found' });
    const isAdmin = (await query('SELECT is_admin FROM users WHERE id = $1', [userId])).rows[0]?.is_admin;
    if (row.user_id !== userId && !isAdmin) return res.status(403).json({ error: 'You can only edit your own posts' });
    const setClauses = [];
    const queryParams = [];
    let idx = 1;
    if (body.hideLikes !== undefined) {
      setClauses.push(`hide_likes = $${idx}`);
      queryParams.push(body.hideLikes === true || body.hideLikes === 'true');
      idx++;
    }
    if (body.commentsDisabled !== undefined) {
      setClauses.push(`comments_disabled = $${idx}`);
      queryParams.push(body.commentsDisabled === true || body.commentsDisabled === 'true');
      idx++;
    }
    if (setClauses.length === 0) return res.status(400).json({ error: 'Provide hideLikes and/or commentsDisabled' });
    queryParams.push(postId);
    await query(`UPDATE feed_posts SET ${setClauses.join(', ')} WHERE id = $${idx}`, queryParams);
    invalidateByPrefix('feed:');
    const [updated, likeCounts, commentCounts, likedByUser, savedByUser] = await Promise.all([
      query('SELECT p.id, p.user_id, p.author_name, p.place_id, pl.name AS place_name, pl.images AS place_images, p.author_role, p.caption, p.image_url, p.video_url, p.type, p.created_at, p.hide_likes, p.comments_disabled FROM feed_posts p LEFT JOIN places pl ON pl.id = p.place_id WHERE p.id = $1', [postId]),
      query('SELECT post_id, COUNT(*)::int AS c FROM feed_likes WHERE post_id = $1 GROUP BY post_id', [postId]),
      query('SELECT post_id, COUNT(*)::int AS c FROM feed_comments WHERE post_id = $1 GROUP BY post_id', [postId]),
      query('SELECT post_id FROM feed_likes WHERE user_id = $1 AND post_id = $2', [userId, postId]),
      query('SELECT post_id FROM feed_saves WHERE user_id = $1 AND post_id = $2', [userId, postId]),
    ]);
    const baseUrl = getBaseUrl(req);
    res.json(rowToPost(updated.rows[0], baseUrl, {
      likeCount: likeCounts.rows[0]?.c ?? 0,
      commentCount: commentCounts.rows[0]?.c ?? 0,
      likedByMe: (likedByUser.rows || []).length > 0,
      savedByMe: (savedByUser.rows || []).length > 0,
    }));
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to update post options' });
  }
});

// DELETE /api/feed/:id - Auth required. Image/news: author or admin. Video (reels): admin or business owner of place_id.
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const { id: postId } = req.params;
    const userId = req.user?.userId;
    const row = (await query('SELECT user_id, place_id, type FROM feed_posts WHERE id = $1', [postId])).rows[0];
    if (!row) return res.status(404).json({ error: 'Post not found' });
    const isAdmin = (await query('SELECT is_admin FROM users WHERE id = $1', [userId])).rows[0]?.is_admin;
    if (row.type === 'video') {
      if (isAdmin) {
        // ok
      } else if (row.place_id) {
        const owns = (await query('SELECT 1 FROM place_owners WHERE user_id = $1 AND place_id = $2', [userId, row.place_id])).rows.length;
        if (!owns) {
          return res.status(403).json({ error: 'Only admins or the place owner can delete reels' });
        }
      } else {
        return res.status(403).json({ error: 'Only admins can delete this reel' });
      }
    } else if (row.user_id !== userId && !isAdmin) {
      return res.status(403).json({ error: 'You can only delete your own posts' });
    }
    await query('DELETE FROM feed_posts WHERE id = $1', [postId]);
    res.json({ deleted: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to delete post' });
  }
});

module.exports = router;
