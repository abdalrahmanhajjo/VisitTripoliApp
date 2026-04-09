const path = require('path');
const crypto = require('crypto');
const express = require('express');
const rateLimit = require('express-rate-limit');
const multer = require('multer');
const { collection } = require('../db');
const { responseCache, invalidateByPrefix } = require('../middleware/responseCache');
const { authMiddleware, optionalAuthMiddleware, verifyAccessTokenOptional } = require('../middleware/auth');
const { getRequestLang } = require('../utils/requestLang');
const { sanitizeFeedBody, isValidPlaceId, isValidUUID } = require('../middleware/security');
const { imageFileFilter, videoFileFilter, MAX_IMAGE_SIZE, MAX_VIDEO_SIZE } = require('../middleware/secureUpload');
const { uploadFeedImage, uploadFeedVideo, isConfigured: mediaStorageConfigured } = require('../lib/supabaseStorage');
const { withTranslation } = require('../utils/mongoTranslations');

const router = express.Router();
const isProd = process.env.NODE_ENV === 'production';
const FEED_LIMIT_DEFAULT = 20;
const FEED_LIMIT_MAX = 50;

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: Math.max(MAX_IMAGE_SIZE, MAX_VIDEO_SIZE) },
  fileFilter: (req, file, cb) => {
    const mime = (file.mimetype || '').toLowerCase();
    const ext = path.extname((file.originalname || '').toLowerCase());
    const imgExt = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);
    const vidExt = ['.mp4', '.webm', '.mov', '.avi', '.mkv', '.3gp', '.ogv', '.mpeg', '.mpg'].includes(ext);
    if (mime.startsWith('image/') || (mime === 'application/octet-stream' && imgExt)) return imageFileFilter(req, file, cb);
    if (mime.startsWith('video/') || vidExt || (mime === 'application/octet-stream' && vidExt) || file.fieldname === 'video') return videoFileFilter(req, file, cb);
    return cb(new Error('Invalid file type'));
  },
});

function getBaseUrl(req) {
  const proto = req.get('x-forwarded-proto') || (req.secure ? 'https' : 'http');
  const host = req.get('x-forwarded-host') || req.get('host') || 'localhost:3000';
  return `${proto}://${host}`;
}
function absUrl(baseUrl, url) {
  return url && (url.startsWith('http') ? url : `${baseUrl}${url}`);
}
function firstPlaceImage(images, baseUrl) {
  if (!Array.isArray(images) || !images.length) return null;
  const v = images[0];
  return typeof v === 'string' ? (v.startsWith('http') ? v : `${baseUrl}${v.startsWith('/') ? '' : '/'}${v}`) : null;
}

function parseFeedBeforeParam(raw) {
  const s = (raw || '').toString().trim();
  if (!s) return { ok: true, value: null };
  if (!isValidUUID(s)) return { ok: false };
  return { ok: true, value: s };
}
function parseReelsBeforeParam(raw) {
  const s = (raw || '').toString().trim();
  if (!s) return { ok: true, value: null };
  const ms = Date.parse(s);
  if (Number.isNaN(ms)) return { ok: false };
  return { ok: true, value: new Date(ms).toISOString() };
}
function requireUuidParam(name) {
  return (req, res, next) => {
    const v = req.params[name];
    if (!isValidUUID(v)) return res.status(400).json({ error: 'Invalid id' });
    return next();
  };
}

async function enrichPosts(posts, userId, lang, req) {
  const baseUrl = getBaseUrl(req);
  const postIds = posts.map((p) => p.id);
  const placeIds = posts.map((p) => p.place_id).filter(Boolean);
  const [likes, comments, placeRows, placeTrRows, myLikes, mySaves] = await Promise.all([
    collection('feed_likes').aggregate([{ $match: { post_id: { $in: postIds } } }, { $group: { _id: '$post_id', c: { $sum: 1 } } }]).toArray(),
    collection('feed_comments').aggregate([{ $match: { post_id: { $in: postIds } } }, { $group: { _id: '$post_id', c: { $sum: 1 } } }]).toArray(),
    collection('places').find({ id: { $in: placeIds } }, { projection: { _id: 0, id: 1, name: 1, images: 1 } }).toArray(),
    lang && lang !== 'en'
      ? collection('place_translations').find({ place_id: { $in: placeIds }, lang }, { projection: { _id: 0 } }).toArray()
      : Promise.resolve([]),
    userId ? collection('feed_likes').find({ user_id: userId, post_id: { $in: postIds } }, { projection: { _id: 0, post_id: 1 } }).toArray() : Promise.resolve([]),
    userId ? collection('feed_saves').find({ user_id: userId, post_id: { $in: postIds } }, { projection: { _id: 0, post_id: 1 } }).toArray() : Promise.resolve([]),
  ]);
  const likeMap = new Map(likes.map((x) => [x._id, x.c]));
  const commentMap = new Map(comments.map((x) => [x._id, x.c]));
  const placeMap = new Map(placeRows.map((p) => [p.id, p]));
  const trMap = new Map(placeTrRows.map((x) => [x.place_id, x]));
  const likedSet = new Set(myLikes.map((x) => x.post_id));
  const savedSet = new Set(mySaves.map((x) => x.post_id));
  return posts.map((p) => {
    const pl = placeMap.get(p.place_id);
    const plt = withTranslation(pl || {}, trMap.get(p.place_id), ['name']);
    return {
      id: p.id,
      authorId: p.user_id != null ? String(p.user_id) : null,
      authorName: p.author_name,
      authorPlaceId: p.place_id,
      authorPlaceName: plt?.name || null,
      authorPlaceImage: firstPlaceImage(pl?.images, baseUrl),
      authorRole: p.author_role || 'regular',
      caption: p.caption,
      imageUrl: absUrl(baseUrl, p.image_url),
      videoUrl: absUrl(baseUrl, p.video_url),
      type: p.type || 'image',
      createdAt: p.created_at,
      likeCount: likeMap.get(p.id) || 0,
      commentCount: commentMap.get(p.id) || 0,
      likedByMe: likedSet.has(p.id),
      savedByMe: savedSet.has(p.id),
      hideLikes: p.hide_likes === true,
      commentsDisabled: p.comments_disabled === true,
      moderationStatus: p.moderation_status || 'approved',
    };
  });
}

async function assertFeedPostApprovedForInteraction(postId) {
  const r = await collection('feed_posts').findOne({ id: postId }, { projection: { _id: 0, moderation_status: 1 } });
  if (!r) return { ok: false, code: 404, message: 'Post not found' };
  const st = r.moderation_status || 'approved';
  if (st === 'pending') return { ok: false, code: 403, message: 'Post is not public yet' };
  if (st === 'rejected') return { ok: false, code: 403, message: 'Post is not available' };
  return { ok: true };
}

router.get('/can-post', authMiddleware, async (req, res) => {
  try {
    const userId = req.user?.userId;
    const user = await collection('users').findOne({ id: userId }, { projection: { _id: 0, is_admin: 1, is_business_owner: 1, feed_discoverable: 1 } });
    const payload = { canPost: false, isAdmin: false, isBusinessOwner: false, isDiscoverableContributor: false, requiresModeration: false, ownedPlaces: [] };
    if (!user) return res.json(payload);
    if (user.is_admin) return res.json({ ...payload, canPost: true, isAdmin: true });
    if (!user.is_business_owner && !user.feed_discoverable) return res.json(payload);
    if (!user.is_business_owner && user.feed_discoverable) return res.json({ ...payload, canPost: true, isDiscoverableContributor: true, requiresModeration: true });
    const lang = getRequestLang(req);
    const owns = await collection('place_owners').find({ user_id: userId }, { projection: { _id: 0, place_id: 1 } }).toArray();
    const ids = owns.map((o) => o.place_id);
    const places = await collection('places').find({ id: { $in: ids } }, { projection: { _id: 0, id: 1, name: 1 } }).toArray();
    const tr = lang && lang !== 'en'
      ? await collection('place_translations').find({ place_id: { $in: ids }, lang }, { projection: { _id: 0 } }).toArray()
      : [];
    const trMap = new Map(tr.map((x) => [x.place_id, x]));
    return res.json({
      ...payload,
      canPost: places.length > 0,
      isBusinessOwner: true,
      ownedPlaces: places.map((p) => ({ id: p.id, name: withTranslation(p, trMap.get(p.id), ['name']).name })),
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to check post permission' });
  }
});

router.get('/', optionalAuthMiddleware, responseCache(30 * 1000), async (req, res) => {
  try {
    const lang = getRequestLang(req);
    const limit = Math.min(parseInt(req.query.limit, 10) || FEED_LIMIT_DEFAULT, FEED_LIMIT_MAX);
    const beforeParsed = parseFeedBeforeParam(req.query.before);
    if (!beforeParsed.ok) return res.status(400).json({ error: 'Invalid cursor' });
    const userId = req.user?.userId || null;
    const filter = {
      moderation_status: 'approved',
      $or: [{ author_role: { $in: ['admin', 'business_owner'] } }, { author_role: 'discoverer', place_id: { $ne: null } }, { author_role: null, place_id: { $ne: null } }],
    };
    if (beforeParsed.value) {
      const ref = await collection('feed_posts').findOne({ id: beforeParsed.value }, { projection: { _id: 0, created_at: 1 } });
      if (ref?.created_at) filter.created_at = { $lt: ref.created_at };
    }
    const posts = await collection('feed_posts').find(filter, { projection: { _id: 0 } }).sort({ created_at: -1 }).limit(limit).toArray();
    const mapped = await enrichPosts(posts, userId, lang, req);
    const nextCursor = mapped.length === limit ? mapped[mapped.length - 1].id : null;
    res.json({ posts: mapped, nextCursor, hasMore: !!nextCursor, sort: 'recent', nextOffset: null });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch feed', ...(isProd ? {} : { detail: err.message }) });
  }
});

router.get('/reels', optionalAuthMiddleware, async (req, res) => {
  try {
    const lang = getRequestLang(req);
    const parsed = parseReelsBeforeParam(req.query.before);
    if (!parsed.ok) return res.status(400).json({ error: 'Invalid cursor' });
    const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
    const filter = { type: 'video', moderation_status: 'approved' };
    if (parsed.value) filter.created_at = { $lt: new Date(parsed.value) };
    const posts = await collection('feed_posts').find(filter, { projection: { _id: 0 } }).sort({ created_at: -1 }).limit(limit).toArray();
    const mapped = await enrichPosts(posts, req.user?.userId || null, lang, req);
    const nextCursor = mapped.length === limit ? posts[posts.length - 1].created_at : null;
    res.json({ posts: mapped, nextCursor, hasMore: !!nextCursor });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch reels', ...(isProd ? {} : { detail: err.message }) });
  }
});

router.get('/saved', authMiddleware, async (req, res) => {
  const ids = (await collection('feed_saves').find({ user_id: req.user.userId }, { projection: { _id: 0, post_id: 1 } }).toArray()).map((x) => x.post_id);
  const posts = await collection('feed_posts').find({ id: { $in: ids }, moderation_status: 'approved' }, { projection: { _id: 0 } }).sort({ created_at: -1 }).toArray();
  const mapped = await enrichPosts(posts, req.user.userId, getRequestLang(req), req);
  res.json({ posts: mapped, nextCursor: null, hasMore: false });
});

router.get('/liked', authMiddleware, async (req, res) => {
  const ids = (await collection('feed_likes').find({ user_id: req.user.userId }, { projection: { _id: 0, post_id: 1 } }).toArray()).map((x) => x.post_id);
  const posts = await collection('feed_posts').find({ id: { $in: ids }, moderation_status: 'approved' }, { projection: { _id: 0 } }).sort({ created_at: -1 }).toArray();
  const mapped = await enrichPosts(posts, req.user.userId, getRequestLang(req), req);
  res.json({ posts: mapped, nextCursor: null, hasMore: false });
});

router.get('/pending-moderation', authMiddleware, async (req, res) => {
  const u = await collection('users').findOne({ id: req.user.userId }, { projection: { _id: 0, is_admin: 1 } });
  if (!u?.is_admin) return res.status(403).json({ error: 'Admin only' });
  const posts = await collection('feed_posts').find({ moderation_status: 'pending', author_role: 'discoverer' }, { projection: { _id: 0 } }).sort({ created_at: 1 }).limit(50).toArray();
  const mapped = await enrichPosts(posts, req.user.userId, getRequestLang(req), req);
  res.json({ posts: mapped, total: mapped.length });
});

router.get('/place/:placeId', optionalAuthMiddleware, async (req, res) => {
  const placeId = req.params.placeId;
  if (!isValidPlaceId(placeId)) return res.status(400).json({ error: 'Invalid place id' });
  const posts = await collection('feed_posts').find({ place_id: placeId, moderation_status: 'approved' }, { projection: { _id: 0 } }).sort({ created_at: -1 }).limit(50).toArray();
  const mapped = await enrichPosts(posts, req.user?.userId || null, getRequestLang(req), req);
  const pl = await collection('places').findOne({ id: placeId }, { projection: { _id: 0, name: 1, images: 1 } });
  res.json({ posts: mapped, nextCursor: null, hasMore: false, place: { name: pl?.name || 'Place', image: firstPlaceImage(pl?.images, getBaseUrl(req)) } });
});

const postLimiter = rateLimit({ windowMs: 60 * 1000, max: 10, message: { error: 'Post limit exceeded. Try again later.' }, standardHeaders: true });
router.post('/', postLimiter, authMiddleware, sanitizeFeedBody, upload.fields([{ name: 'image', maxCount: 1 }, { name: 'video', maxCount: 1 }]), async (req, res) => {
  try {
    const userId = req.user?.userId;
    const placeId = req.body?.placeId && isValidPlaceId(req.body.placeId) ? req.body.placeId : null;
    const user = await collection('users').findOne({ id: userId }, { projection: { _id: 0, id: 1, name: 1, is_admin: 1, is_business_owner: 1, feed_discoverable: 1 } });
    if (!user) return res.status(401).json({ error: 'User not found' });
    let authorRole = null;
    let moderationStatus = 'approved';
    if (user.is_admin) authorRole = 'admin';
    else if (user.is_business_owner) {
      if (!placeId) return res.status(403).json({ error: 'Business owners must select a place to post to.' });
      const own = await collection('place_owners').findOne({ user_id: userId, place_id: placeId }, { projection: { _id: 1 } });
      if (!own) return res.status(403).json({ error: 'Only admins and business owners can post. You must own this place to post.' });
      authorRole = 'business_owner';
    } else if (user.feed_discoverable) {
      if (!placeId) return res.status(403).json({ error: 'Select a place for your post.' });
      const placeOk = await collection('places').findOne({ id: placeId }, { projection: { _id: 1 } });
      if (!placeOk) return res.status(404).json({ error: 'Place not found' });
      authorRole = 'discoverer';
      moderationStatus = 'pending';
    } else return res.status(403).json({ error: 'Only business owners can post to the feed. Regular users cannot post.' });

    const imageFile = req.files?.image?.[0];
    const videoFile = req.files?.video?.[0];
    let imageUrl = null;
    let videoUrl = null;
    let type = 'news';
    if (videoFile) {
      if (!mediaStorageConfigured()) return res.status(503).json({ error: 'Video upload requires ImageKit configuration' });
      videoUrl = await uploadFeedVideo(videoFile.buffer, videoFile);
      type = 'video';
    }
    if (imageFile) {
      if (!mediaStorageConfigured()) return res.status(503).json({ error: 'Feed image upload requires ImageKit configuration' });
      imageUrl = await uploadFeedImage(imageFile.buffer, imageFile);
      if (type === 'news') type = 'image';
    }
    const doc = {
      id: crypto.randomUUID(),
      user_id: userId,
      author_name: req.body?.authorName || user.name || 'User',
      place_id: placeId || null,
      caption: req.body?.caption || null,
      image_url: imageUrl,
      video_url: videoUrl,
      type,
      author_role: authorRole,
      moderation_status: moderationStatus,
      hide_likes: false,
      comments_disabled: false,
      created_at: new Date(),
      updated_at: new Date(),
    };
    await collection('feed_posts').insertOne(doc);
    const mapped = await enrichPosts([doc], userId, getRequestLang(req), req);
    res.status(201).json(mapped[0]);
  } catch (err) {
    res.status(500).json({ error: 'Failed to create post', ...(isProd ? {} : { detail: err.message }) });
  }
});

router.patch('/:id/moderation', authMiddleware, requireUuidParam('id'), async (req, res) => {
  const admin = await collection('users').findOne({ id: req.user.userId }, { projection: { _id: 0, is_admin: 1 } });
  if (!admin?.is_admin) return res.status(403).json({ error: 'Admin only' });
  const status = String(req.body?.status || '').toLowerCase();
  if (!['approved', 'rejected'].includes(status)) return res.status(400).json({ error: 'status must be approved or rejected' });
  const r = await collection('feed_posts').updateOne({ id: req.params.id, author_role: 'discoverer', moderation_status: 'pending' }, { $set: { moderation_status: status, updated_at: new Date() } });
  if (!r.matchedCount) return res.status(404).json({ error: 'Post not found' });
  invalidateByPrefix('feed:');
  const post = await collection('feed_posts').findOne({ id: req.params.id }, { projection: { _id: 0 } });
  const mapped = await enrichPosts([post], req.user.userId, getRequestLang(req), req);
  res.json(mapped[0]);
});

router.post('/:id/like', authMiddleware, requireUuidParam('id'), async (req, res) => {
  const postId = req.params.id;
  const userId = req.user.userId;
  const vis = await assertFeedPostApprovedForInteraction(postId);
  if (!vis.ok) return res.status(vis.code).json({ error: vis.message });
  const exists = await collection('feed_likes').findOne({ post_id: postId, user_id: userId }, { projection: { _id: 1 } });
  if (exists) await collection('feed_likes').deleteOne({ post_id: postId, user_id: userId });
  else await collection('feed_likes').insertOne({ post_id: postId, user_id: userId, created_at: new Date() });
  const likeCount = await collection('feed_likes').countDocuments({ post_id: postId });
  res.json({ liked: !exists, likeCount });
});

router.get('/:id/comments', requireUuidParam('id'), async (req, res) => {
  const postId = req.params.id;
  const vis = await assertFeedPostApprovedForInteraction(postId);
  if (!vis.ok) return res.status(vis.code).json({ error: vis.message });
  const userId = req.headers.authorization?.startsWith('Bearer ') ? verifyAccessTokenOptional(req.headers.authorization.slice(7).trim()) : null;
  const limit = Math.min(parseInt(req.query.limit, 10) || 40, 200);
  const offset = Math.max(0, parseInt(req.query.offset, 10) || 0);
  const comments = await collection('feed_comments').find({ post_id: postId }, { projection: { _id: 0 } }).sort({ created_at: -1 }).skip(offset).limit(limit).toArray();
  const cids = comments.map((c) => c.id);
  const [users, profiles, likeAgg, myLikes] = await Promise.all([
    collection('users').find({ id: { $in: comments.map((c) => c.user_id).filter(Boolean) } }, { projection: { _id: 0, id: 1, name: 1, avatar_url: 1 } }).toArray(),
    collection('profiles').find({ user_id: { $in: comments.map((c) => c.user_id).filter(Boolean) } }, { projection: { _id: 0, user_id: 1, username: 1 } }).toArray(),
    collection('feed_comment_likes').aggregate([{ $match: { comment_id: { $in: cids } } }, { $group: { _id: '$comment_id', c: { $sum: 1 } } }]).toArray(),
    userId ? collection('feed_comment_likes').find({ user_id: userId, comment_id: { $in: cids } }, { projection: { _id: 0, comment_id: 1 } }).toArray() : Promise.resolve([]),
  ]);
  const uMap = new Map(users.map((u) => [u.id, u]));
  const pMap = new Map(profiles.map((p) => [p.user_id, p]));
  const lMap = new Map(likeAgg.map((x) => [x._id, x.c]));
  const mySet = new Set(myLikes.map((x) => x.comment_id));
  const total = await collection('feed_comments').countDocuments({ post_id: postId });
  const out = comments.map((c) => {
    const u = uMap.get(c.user_id);
    const p = pMap.get(c.user_id);
    return {
      id: c.id,
      postId: c.post_id,
      userId: c.user_id ? String(c.user_id) : null,
      authorName: c.author_name,
      authorUsername: p?.username ? String(p.username).replace(/^@+/, '') : null,
      authorAvatarUrl: absUrl(getBaseUrl(req), u?.avatar_url) || null,
      authorFullName: u?.name || null,
      body: c.body,
      createdAt: c.created_at,
      parentCommentId: c.parent_comment_id || null,
      parentAuthorName: c.parent_author_name || null,
      parentAuthorUsername: c.parent_username || null,
      updatedAt: c.updated_at || null,
      likeCount: lMap.get(c.id) || 0,
      likedByMe: mySet.has(c.id),
    };
  });
  const nextOffset = offset + out.length;
  res.json({ comments: out, total, nextOffset: nextOffset < total ? nextOffset : null, hasMore: nextOffset < total });
});

router.post('/:id/comments', authMiddleware, requireUuidParam('id'), async (req, res) => {
  const postId = req.params.id;
  const post = await collection('feed_posts').findOne({ id: postId }, { projection: { _id: 0, comments_disabled: 1, moderation_status: 1 } });
  if (!post) return res.status(404).json({ error: 'Post not found' });
  if (post.moderation_status === 'pending') return res.status(403).json({ error: 'Post is not public yet' });
  if (post.moderation_status === 'rejected') return res.status(403).json({ error: 'Post is not available' });
  if (post.comments_disabled) return res.status(403).json({ error: 'Comments are turned off for this post' });
  const body = String(req.body?.body ?? req.body?.text ?? '').trim();
  if (!body || body.length > 2000) return res.status(400).json({ error: 'Comment must be 1–2000 characters' });
  const userId = req.user.userId;
  const u = await collection('users').findOne({ id: userId }, { projection: { _id: 0, name: 1, avatar_url: 1 } });
  const p = await collection('profiles').findOne({ user_id: userId }, { projection: { _id: 0, username: 1 } });
  let parentCommentId = String(req.body?.parentCommentId ?? req.body?.parent_comment_id ?? '').trim() || null;
  if (parentCommentId && !isValidUUID(parentCommentId)) parentCommentId = null;
  if (parentCommentId) {
    const parent = await collection('feed_comments').findOne({ id: parentCommentId, post_id: postId }, { projection: { _id: 0, id: 1 } });
    if (!parent) parentCommentId = null;
  }
  const doc = {
    id: crypto.randomUUID(),
    post_id: postId,
    user_id: userId,
    author_name: p?.username ? `@${String(p.username).replace(/^@+/, '')}` : ((u?.name || 'User')),
    body,
    parent_comment_id: parentCommentId,
    created_at: new Date(),
    updated_at: null,
  };
  await collection('feed_comments').insertOne(doc);
  res.status(201).json({
    id: doc.id,
    postId: doc.post_id,
    userId: doc.user_id,
    authorName: doc.author_name,
    authorUsername: p?.username ? String(p.username).replace(/^@+/, '') : null,
    authorAvatarUrl: absUrl(getBaseUrl(req), u?.avatar_url) || null,
    authorFullName: u?.name || null,
    body: doc.body,
    createdAt: doc.created_at,
    parentCommentId: doc.parent_comment_id,
    parentAuthorName: null,
    parentAuthorUsername: null,
    updatedAt: null,
    likeCount: 0,
    likedByMe: false,
  });
});

router.delete('/comments/:commentId', authMiddleware, requireUuidParam('commentId'), async (req, res) => {
  const { commentId } = req.params;
  const userId = req.user.userId;
  const c = await collection('feed_comments').findOne({ id: commentId }, { projection: { _id: 0 } });
  if (!c) return res.status(404).json({ error: 'Comment not found' });
  const post = await collection('feed_posts').findOne({ id: c.post_id }, { projection: { _id: 0, user_id: 1 } });
  const isAdmin = (await collection('users').findOne({ id: userId }, { projection: { _id: 0, is_admin: 1 } }))?.is_admin;
  if (c.user_id !== userId && post?.user_id !== userId && !isAdmin) return res.status(403).json({ error: 'You can only delete your own comments or comments on your posts' });
  await collection('feed_comments').deleteOne({ id: commentId });
  res.json({ deleted: true });
});

router.post('/comments/:commentId/like', authMiddleware, requireUuidParam('commentId'), async (req, res) => {
  const { commentId } = req.params;
  const userId = req.user.userId;
  const exists = await collection('feed_comment_likes').findOne({ comment_id: commentId, user_id: userId }, { projection: { _id: 1 } });
  if (exists) await collection('feed_comment_likes').deleteOne({ comment_id: commentId, user_id: userId });
  else await collection('feed_comment_likes').insertOne({ comment_id: commentId, user_id: userId, created_at: new Date() });
  const likeCount = await collection('feed_comment_likes').countDocuments({ comment_id: commentId });
  res.json({ liked: !exists, likeCount });
});

router.patch('/comments/:commentId', authMiddleware, requireUuidParam('commentId'), async (req, res) => {
  const { commentId } = req.params;
  const userId = req.user.userId;
  const body = String(req.body?.body ?? req.body?.text ?? '').trim();
  if (!body || body.length > 2000) return res.status(400).json({ error: 'Comment must be 1–2000 characters' });
  const own = await collection('feed_comments').findOne({ id: commentId }, { projection: { _id: 0, user_id: 1 } });
  if (!own) return res.status(404).json({ error: 'Comment not found' });
  if (own.user_id !== userId) return res.status(403).json({ error: 'You can only edit your own comments' });
  await collection('feed_comments').updateOne({ id: commentId }, { $set: { body, updated_at: new Date() } });
  const edited = await collection('feed_comments').findOne({ id: commentId }, { projection: { _id: 0 } });
  res.json({ id: edited.id, postId: edited.post_id, userId: edited.user_id, authorName: edited.author_name, body: edited.body, createdAt: edited.created_at, updatedAt: edited.updated_at });
});

router.post('/:id/report', authMiddleware, requireUuidParam('id'), async (req, res) => {
  const postId = req.params.id;
  const userId = req.user.userId;
  const reason = String(req.body?.reason ?? 'inappropriate').trim().slice(0, 50);
  const post = await collection('feed_posts').findOne({ id: postId }, { projection: { _id: 0, user_id: 1 } });
  if (!post) return res.status(404).json({ error: 'Post not found' });
  if (post.user_id === userId) return res.status(400).json({ error: 'You cannot report your own post' });
  await collection('feed_reports').updateOne(
    { post_id: postId, user_id: userId },
    { $setOnInsert: { post_id: postId, user_id: userId, reason: reason || null, created_at: new Date() } },
    { upsert: true }
  );
  res.json({ reported: true });
});

router.post('/:id/save', authMiddleware, requireUuidParam('id'), async (req, res) => {
  const postId = req.params.id;
  const userId = req.user.userId;
  const vis = await assertFeedPostApprovedForInteraction(postId);
  if (!vis.ok) return res.status(vis.code).json({ error: vis.message });
  const exists = await collection('feed_saves').findOne({ post_id: postId, user_id: userId }, { projection: { _id: 1 } });
  if (exists) await collection('feed_saves').deleteOne({ post_id: postId, user_id: userId });
  else await collection('feed_saves').insertOne({ post_id: postId, user_id: userId, created_at: new Date() });
  res.json({ saved: !exists });
});

function optionalUploadImage(req, res, next) {
  const contentType = (req.get('Content-Type') || '').toLowerCase();
  if (contentType.includes('multipart/form-data')) return upload.single('image')(req, res, next);
  return next();
}

router.put('/:id', authMiddleware, requireUuidParam('id'), optionalUploadImage, async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.user.userId;
    const row = await collection('feed_posts').findOne({ id: postId }, { projection: { _id: 0 } });
    if (!row) return res.status(404).json({ error: 'Post not found' });
    const isAdmin = (await collection('users').findOne({ id: userId }, { projection: { _id: 0, is_admin: 1 } }))?.is_admin;
    if (row.user_id !== userId && !isAdmin) return res.status(403).json({ error: 'You can only edit your own posts' });
    const caption = String(req.body?.caption ?? '').trim() || null;
    const removeImage = req.body?.removeImage === 'true' || req.body?.removeImage === true;
    let imageUrl = removeImage ? null : row.image_url;
    let type = removeImage ? (row.video_url ? 'video' : 'news') : (row.type || 'image');
    if (req.file) {
      if (!mediaStorageConfigured()) return res.status(503).json({ error: 'Feed image upload requires ImageKit configuration' });
      imageUrl = await uploadFeedImage(req.file.buffer, req.file);
      type = 'image';
    }
    await collection('feed_posts').updateOne({ id: postId }, { $set: { caption, image_url: imageUrl, type, updated_at: new Date() } });
    const updated = await collection('feed_posts').findOne({ id: postId }, { projection: { _id: 0 } });
    const mapped = await enrichPosts([updated], userId, getRequestLang(req), req);
    res.json(mapped[0]);
  } catch (err) {
    res.status(err.statusCode || 500).json({ error: isProd ? 'Failed to update post' : (err.message || 'Failed to update post') });
  }
});

router.patch('/:id/options', authMiddleware, requireUuidParam('id'), async (req, res) => {
  const postId = req.params.id;
  const userId = req.user.userId;
  const row = await collection('feed_posts').findOne({ id: postId }, { projection: { _id: 0, user_id: 1 } });
  if (!row) return res.status(404).json({ error: 'Post not found' });
  const isAdmin = (await collection('users').findOne({ id: userId }, { projection: { _id: 0, is_admin: 1 } }))?.is_admin;
  if (row.user_id !== userId && !isAdmin) return res.status(403).json({ error: 'You can only edit your own posts' });
  const set = {};
  if (req.body?.hideLikes !== undefined) set.hide_likes = req.body.hideLikes === true || req.body.hideLikes === 'true';
  if (req.body?.commentsDisabled !== undefined) set.comments_disabled = req.body.commentsDisabled === true || req.body.commentsDisabled === 'true';
  if (!Object.keys(set).length) return res.status(400).json({ error: 'Provide hideLikes and/or commentsDisabled' });
  set.updated_at = new Date();
  await collection('feed_posts').updateOne({ id: postId }, { $set: set });
  invalidateByPrefix('feed:');
  const updated = await collection('feed_posts').findOne({ id: postId }, { projection: { _id: 0 } });
  const mapped = await enrichPosts([updated], userId, getRequestLang(req), req);
  res.json(mapped[0]);
});

router.delete('/:id', authMiddleware, requireUuidParam('id'), async (req, res) => {
  const postId = req.params.id;
  const userId = req.user.userId;
  const row = await collection('feed_posts').findOne({ id: postId }, { projection: { _id: 0, user_id: 1, place_id: 1, type: 1 } });
  if (!row) return res.status(404).json({ error: 'Post not found' });
  const isAdmin = (await collection('users').findOne({ id: userId }, { projection: { _id: 0, is_admin: 1 } }))?.is_admin;
  if (row.type === 'video') {
    if (!isAdmin) {
      if (row.place_id) {
        const own = await collection('place_owners').findOne({ user_id: userId, place_id: row.place_id }, { projection: { _id: 1 } });
        if (!own) return res.status(403).json({ error: 'Only admins or the place owner can delete reels' });
      } else return res.status(403).json({ error: 'Only admins can delete this reel' });
    }
  } else if (row.user_id !== userId && !isAdmin) return res.status(403).json({ error: 'You can only delete your own posts' });
  await collection('feed_posts').deleteOne({ id: postId });
  res.json({ deleted: true });
});

module.exports = router;
