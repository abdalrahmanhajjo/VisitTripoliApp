const crypto = require('crypto');
const express = require('express');
const { collection } = require('../db');
const adminAuth = require('../middleware/adminAuth');
const { getRequestLang } = require('../utils/requestLang');
const { invalidateByPrefix } = require('../middleware/responseCache');
const { withTranslation } = require('../utils/mongoTranslations');

const router = express.Router();

router.post('/login', (req, res) => {
  const secret = process.env.ADMIN_SECRET;
  const { key } = req.body || {};
  if (!secret) return res.json({ success: true, message: 'No admin secret set (dev mode)' });
  if (key === secret) return res.json({ success: true });
  return res.status(401).json({ success: false, error: 'Invalid admin key' });
});

router.use(adminAuth);

function newCheckinToken() {
  return crypto.randomBytes(32).toString('hex');
}

function buildCheckinQrPayload(placeId, checkinToken) {
  return `tripoli-explorer://checkin?p=${encodeURIComponent(placeId)}&token=${encodeURIComponent(checkinToken)}`;
}

async function backfillMissingCheckinTokens() {
  const docs = await collection('places')
    .find({ $or: [{ checkin_token: null }, { checkin_token: '' }] }, { projection: { _id: 0, id: 1 } })
    .toArray();
  await Promise.all(docs.map((d) =>
    collection('places').updateOne({ id: d.id }, { $set: { checkin_token: newCheckinToken(), updated_at: new Date() } })
  ));
}

router.get('/categories', async (_req, res) => {
  const rows = await collection('categories').find({}, { projection: { _id: 0 } }).sort({ name: 1 }).toArray();
  res.json(rows);
});
router.post('/categories', async (req, res) => {
  const p = req.body || {};
  await collection('categories').insertOne({ ...p, tags: Array.isArray(p.tags) ? p.tags : [], created_at: new Date(), updated_at: new Date() });
  res.status(201).json({ id: p.id });
});
router.put('/categories/:id', async (req, res) => {
  const p = req.body || {};
  await collection('categories').updateOne({ id: req.params.id }, { $set: { ...p, tags: Array.isArray(p.tags) ? p.tags : [], updated_at: new Date() } });
  res.json({ ok: true });
});
router.delete('/categories/:id', async (req, res) => {
  await collection('categories').deleteOne({ id: req.params.id });
  res.json({ ok: true });
});

router.get('/places', async (_req, res) => {
  const rows = await collection('places').find({}, { projection: { _id: 0 } }).sort({ name: 1 }).toArray();
  res.json(rows);
});
router.post('/places', async (req, res) => {
  const p = req.body || {};
  const token = newCheckinToken();
  const images = Array.isArray(p.images) ? p.images : (p.image ? [p.image] : []);
  await collection('places').insertOne({
    ...p,
    images,
    category_id: p.categoryId || p.category_id || p.category || '',
    best_time: p.bestTime || p.best_time || '',
    review_count: p.reviewCount ?? p.review_count ?? null,
    checkin_token: token,
    created_at: new Date(),
    updated_at: new Date(),
  });
  res.status(201).json({ id: p.id, checkinToken: token, qrPayload: buildCheckinQrPayload(p.id, token) });
});
router.put('/places/:id', async (req, res) => {
  const p = req.body || {};
  const images = Array.isArray(p.images) ? p.images : (p.image ? [p.image] : undefined);
  const set = {
    ...p,
    category_id: p.categoryId || p.category_id || p.category || '',
    best_time: p.bestTime || p.best_time || '',
    review_count: p.reviewCount ?? p.review_count ?? null,
    updated_at: new Date(),
  };
  if (images) set.images = images;
  await collection('places').updateOne({ id: req.params.id }, { $set: set });
  res.json({ ok: true });
});
router.delete('/places/:id', async (req, res) => {
  await collection('places').deleteOne({ id: req.params.id });
  res.json({ ok: true });
});
router.post('/places/:id/ensure-checkin-token', async (req, res) => {
  const id = req.params.id;
  const row = await collection('places').findOne({ id }, { projection: { _id: 0, id: 1, checkin_token: 1 } });
  if (!row) return res.status(404).json({ error: 'Place not found' });
  let token = row.checkin_token;
  if (!token) {
    token = newCheckinToken();
    await collection('places').updateOne({ id }, { $set: { checkin_token: token, updated_at: new Date() } });
  }
  res.json({ id, checkinToken: token, qrPayload: buildCheckinQrPayload(id, token) });
});
router.post('/places/:id/regenerate-checkin-token', async (req, res) => {
  const id = req.params.id;
  const token = newCheckinToken();
  const r = await collection('places').updateOne({ id }, { $set: { checkin_token: token, updated_at: new Date() } });
  if (!r.matchedCount) return res.status(404).json({ error: 'Place not found' });
  res.json({ id, checkinToken: token, qrPayload: buildCheckinQrPayload(id, token) });
});

router.get('/places-qr-codes', async (req, res) => {
  try {
    const places = await collection('places').find({}, { projection: { _id: 0, id: 1, name: 1, checkin_token: 1 } }).sort({ name: 1 }).toArray();
    const qrs = places.map(p => ({
      id: p.id,
      name: p.name,
      checkinToken: p.checkin_token,
      qrPayload: p.checkin_token ? buildCheckinQrPayload(p.id, p.checkin_token) : null
    }));
    res.json(qrs);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch QR codes' });
  }
});

for (const name of ['tours', 'events', 'interests']) {
  router.get(`/${name}`, async (_req, res) => {
    const rows = await collection(name).find({}, { projection: { _id: 0 } }).toArray();
    res.json(rows);
  });
  
  async function injectTourItineraryIfNeeded(doc) {
    if (name === 'tours' && (!doc.itinerary || !doc.itinerary.length) && Array.isArray(doc.place_ids) && doc.place_ids.length > 0) {
      const places = await collection('places').find({ id: { $in: doc.place_ids } }).toArray();
      const placeMap = new Map(places.map(p => [p.id, p]));
      doc.itinerary = doc.place_ids.map((pId, idx) => {
        const place = placeMap.get(pId);
        return {
          day: `Day ${idx + 1}`,
          title: `Visit ${place?.name || 'Destination'}`,
          description: place?.short_description || place?.description || `Explore ${place?.name || 'this location'}.`,
          time: 'Flexible'
        };
      });
    }
    return doc;
  }

  router.post(`/${name}`, async (req, res) => {
    let doc = req.body || {};
    doc = await injectTourItineraryIfNeeded(doc);
    await collection(name).insertOne({ ...doc, created_at: new Date(), updated_at: new Date() });
    res.status(201).json({ id: doc.id });
  });
  router.put(`/${name}/:id`, async (req, res) => {
    let doc = req.body || {};
    doc = await injectTourItineraryIfNeeded(doc);
    await collection(name).updateOne({ id: req.params.id }, { $set: { ...doc, updated_at: new Date() } });
    res.json({ ok: true });
  });
  router.delete(`/${name}/:id`, async (req, res) => {
    await collection(name).deleteOne({ id: req.params.id });
    res.json({ ok: true });
  });
}

router.get('/users', async (_req, res) => {
  const rows = await collection('users')
    .find({}, { projection: { _id: 0, password_hash: 0 } })
    .sort({ created_at: -1 })
    .toArray();
  res.json(rows);
});
router.put('/users/:id', async (req, res) => {
  const set = {
    is_admin: req.body?.isAdmin === true,
    updated_at: new Date(),
  };
  if (req.body?.feedUploadBlocked !== undefined) {
    set.feed_upload_blocked = req.body.feedUploadBlocked === true;
  }
  await collection('users').updateOne({ id: req.params.id }, { $set: set });
  res.json({ ok: true });
});
router.post('/users', async (req, res) => {
  const bcrypt = require('bcryptjs');
  const { validatePassword } = require('../utils/passwordValidator');
  const { name, email, password } = req.body || {};
  if (!email || !password) return res.status(400).json({ error: 'Email and password required' });
  const pv = validatePassword(password);
  if (!pv.valid) return res.status(400).json({ error: pv.error });
  const lower = String(email).toLowerCase();
  const exists = await collection('users').findOne({ email_lower: lower }, { projection: { _id: 1 } });
  if (exists) return res.status(400).json({ error: 'Email already registered' });
  const id = crypto.randomUUID();
  await collection('users').insertOne({
    id,
    email,
    email_lower: lower,
    name: name || null,
    password_hash: await bcrypt.hash(password, 12),
    auth_provider: 'email',
    auth_provider_id: null,
    email_verified: true,
    is_business_owner: false,
    is_admin: false,
    feed_upload_blocked: false,
    created_at: new Date(),
    updated_at: new Date(),
  });
  res.status(201).json({ id, email, name: name || email.split('@')[0], created_at: new Date().toISOString() });
});
router.delete('/users/:id', async (req, res) => {
  await collection('users').deleteOne({ id: req.params.id });
  res.json({ ok: true });
});

router.get('/place-owners', async (_req, res) => {
  const owners = await collection('place_owners').find({}, { projection: { _id: 0 } }).toArray();
  const users = new Map((await collection('users').find({}, { projection: { _id: 0, id: 1, email: 1 } }).toArray()).map((u) => [u.id, u]));
  const places = new Map((await collection('places').find({}, { projection: { _id: 0, id: 1, name: 1 } }).toArray()).map((p) => [p.id, p]));
  res.json(owners.map((o) => ({
    user_id: o.user_id,
    place_id: o.place_id,
    place_name: places.get(o.place_id)?.name || '',
    email: users.get(o.user_id)?.email || '',
  })));
});
router.post('/place-owners', async (req, res) => {
  const { userId, placeId } = req.body || {};
  if (!userId || !placeId) return res.status(400).json({ error: 'userId and placeId required' });
  await collection('place_owners').updateOne(
    { user_id: userId, place_id: placeId },
    { $setOnInsert: { user_id: userId, place_id: placeId, created_at: new Date() } },
    { upsert: true }
  );
  await collection('users').updateOne({ id: userId }, { $set: { is_business_owner: true, updated_at: new Date() } });
  res.status(201).json({ ok: true });
});
router.delete('/place-owners/:userId/:placeId', async (req, res) => {
  const { userId, placeId } = req.params;
  await collection('place_owners').deleteOne({ user_id: userId, place_id: placeId });
  const remain = await collection('place_owners').findOne({ user_id: userId }, { projection: { _id: 1 } });
  if (!remain) await collection('users').updateOne({ id: userId }, { $set: { is_business_owner: false, updated_at: new Date() } });
  res.json({ ok: true });
});

router.get('/feed/pending', async (req, res) => {
  const lang = getRequestLang(req);
  const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
  const posts = await collection('feed_posts')
    .find({ moderation_status: 'pending', author_role: 'discoverer' }, { projection: { _id: 0 } })
    .sort({ created_at: 1 })
    .limit(limit)
    .toArray();
  const placeIds = posts.map((p) => p.place_id).filter(Boolean);
  const places = new Map((await collection('places').find({ id: { $in: placeIds } }, { projection: { _id: 0, id: 1, name: 1 } }).toArray()).map((p) => [p.id, p]));
  const tr = new Map((await collection('place_translations').find({ place_id: { $in: placeIds }, lang }, { projection: { _id: 0 } }).toArray()).map((x) => [x.place_id, x]));
  const users = new Map((await collection('users').find({ id: { $in: posts.map((p) => p.user_id).filter(Boolean) } }, { projection: { _id: 0, id: 1, email: 1 } }).toArray()).map((u) => [u.id, u]));
  res.json({
    posts: posts.map((p) => ({
      ...p,
      place_name: withTranslation(places.get(p.place_id) || {}, tr.get(p.place_id), ['name']).name || null,
      author_email: users.get(p.user_id)?.email || null,
    })),
  });
});
router.post('/feed/:postId/moderate', async (req, res) => {
  const { postId } = req.params;
  const action = String(req.body?.action || '').toLowerCase();
  if (action !== 'approve' && action !== 'reject') return res.status(400).json({ error: 'body.action must be "approve" or "reject"' });
  const status = action === 'approve' ? 'approved' : 'rejected';
  const r = await collection('feed_posts').updateOne(
    { id: postId, author_role: 'discoverer', moderation_status: 'pending' },
    { $set: { moderation_status: status, updated_at: new Date() } }
  );
  if (!r.matchedCount) return res.status(404).json({ error: 'Pending discoverer post not found' });
  invalidateByPrefix('feed:');
  res.json({ ok: true });
});

router.get('/feed/place-link-blocks', async (_req, res) => {
  const rows = await collection('feed_place_link_blocks')
    .find({}, { projection: { _id: 0 } })
    .sort({ updated_at: -1 })
    .toArray();
  res.json(rows);
});

router.post('/feed/place-link-blocks', async (req, res) => {
  const placeId = String(req.body?.placeId || '').trim();
  if (!placeId) return res.status(400).json({ error: 'placeId is required' });
  const blocked = req.body?.blocked === true;
  await collection('feed_place_link_blocks').updateOne(
    { place_id: placeId },
    {
      $set: {
        place_id: placeId,
        blocked,
        reason: req.body?.reason ? String(req.body.reason).trim().slice(0, 200) : null,
        updated_at: new Date(),
      },
      $setOnInsert: { created_at: new Date() },
    },
    { upsert: true },
  );
  res.json({ ok: true, placeId, blocked });
});

router.get('/stats', async (_req, res) => {
  const [places, categories, tours, events, interests] = await Promise.all([
    collection('places').countDocuments({}),
    collection('categories').countDocuments({}),
    collection('tours').countDocuments({}),
    collection('events').countDocuments({}),
    collection('interests').countDocuments({}),
  ]);
  res.json({ places, categories, tours, events, interests });
});

module.exports = router;
