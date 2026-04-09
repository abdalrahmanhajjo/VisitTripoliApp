const express = require('express');
const { authMiddleware, optionalAuthMiddleware } = require('../middleware/auth');
const { collection } = require('../db');
const { getRequestLang } = require('../utils/requestLang');
const { withTranslation } = require('../utils/mongoTranslations');

const router = express.Router();

function toNumber(v) {
  if (v == null) return null;
  if (typeof v === 'number') return v;
  const n = parseFloat(v);
  return Number.isNaN(n) ? null : n;
}
function mapOffer(row) {
  return {
    ...row,
    discount_value: toNumber(row.discount_value),
    place_images: Array.isArray(row.place_images) ? row.place_images : [],
    expires_at: row.expires_at ? new Date(row.expires_at).toISOString() : null,
  };
}

router.post('/propose', authMiddleware, async (req, res) => {
  const userId = req.user.userId;
  const { place_id, message, phone, suggested_discount_type, suggested_discount_value } = req.body || {};
  const placeId = String(place_id || '').trim();
  const msg = String(message || '').trim();
  const phoneNum = String(phone || '').trim();
  if (!placeId || !msg) return res.status(400).json({ error: 'Place ID and message required' });
  if (!phoneNum) return res.status(400).json({ error: 'Phone number required' });
  const discountType = ['percent', 'fixed', 'bogo', 'free_item'].includes(suggested_discount_type) ? suggested_discount_type : null;
  const discountVal = suggested_discount_value != null ? parseFloat(suggested_discount_value) : null;
  await collection('offer_proposals').insertOne({
    id: `${Date.now()}_${Math.random().toString(36).slice(2, 9)}`,
    user_id: userId,
    place_id: placeId,
    message: msg,
    phone: phoneNum,
    suggested_discount_type: discountType,
    suggested_discount_value: discountVal,
    status: 'pending',
    created_at: new Date(),
  });
  res.status(201).json({ success: true, message: 'Offer proposal sent to restaurant' });
});

router.get('/', optionalAuthMiddleware, async (_req, res) => {
  const now = new Date();
  const offers = await collection('place_offers').find({ expires_at: { $gt: now } }, { projection: { _id: 0 } }).sort({ expires_at: 1 }).limit(50).toArray();
  const placeIds = offers.map((o) => o.place_id).filter(Boolean);
  const places = new Map((await collection('places').find({ id: { $in: placeIds } }, { projection: { _id: 0, id: 1, name: 1, images: 1, category: 1, category_id: 1 } }).toArray()).map((p) => [p.id, p]));
  const rows = offers
    .map((o) => ({ ...o, place_name: places.get(o.place_id)?.name || null, place_images: places.get(o.place_id)?.images || [] }))
    .filter((o) => (places.get(o.place_id)?.category_id === 'food') || String(places.get(o.place_id)?.category || '').toLowerCase().includes('food'));
  res.json({ offers: rows.map(mapOffer) });
});

router.get('/my-proposals', authMiddleware, async (req, res) => {
  const lang = getRequestLang(req);
  const userId = req.user.userId;
  const proposals = await collection('offer_proposals').find({ user_id: userId }, { projection: { _id: 0 } }).sort({ created_at: -1 }).limit(50).toArray();
  const placeIds = proposals.map((p) => p.place_id).filter(Boolean);
  const places = await collection('places').find({ id: { $in: placeIds } }, { projection: { _id: 0, id: 1, name: 1 } }).toArray();
  const tr = lang && lang !== 'en' ? await collection('place_translations').find({ place_id: { $in: placeIds }, lang }, { projection: { _id: 0 } }).toArray() : [];
  const pMap = new Map(places.map((p) => [p.id, p]));
  const tMap = new Map(tr.map((x) => [x.place_id, x]));
  res.json({
    proposals: proposals.map((r) => ({
      id: r.id,
      placeId: r.place_id,
      placeName: withTranslation(pMap.get(r.place_id) || {}, tMap.get(r.place_id), ['name']).name || '',
      message: r.message,
      phone: r.phone,
      status: r.status,
      createdAt: r.created_at,
      restaurantResponse: r.restaurant_response || null,
      restaurantRespondedAt: r.restaurant_responded_at || null,
    })),
  });
});

router.get('/place-proposals', authMiddleware, async (req, res) => {
  const lang = getRequestLang(req);
  const userId = req.user.userId;
  const ownedIds = (await collection('place_owners').find({ user_id: userId }, { projection: { _id: 0, place_id: 1 } }).toArray()).map((x) => x.place_id);
  const proposals = await collection('offer_proposals').find({ place_id: { $in: ownedIds } }, { projection: { _id: 0 } }).sort({ created_at: -1 }).limit(100).toArray();
  const places = await collection('places').find({ id: { $in: ownedIds } }, { projection: { _id: 0, id: 1, name: 1 } }).toArray();
  const tr = lang && lang !== 'en' ? await collection('place_translations').find({ place_id: { $in: ownedIds }, lang }, { projection: { _id: 0 } }).toArray() : [];
  const users = new Map((await collection('users').find({ id: { $in: proposals.map((p) => p.user_id).filter(Boolean) } }, { projection: { _id: 0, id: 1, name: 1 } }).toArray()).map((u) => [u.id, u]));
  const pMap = new Map(places.map((p) => [p.id, p]));
  const tMap = new Map(tr.map((x) => [x.place_id, x]));
  res.json({
    proposals: proposals.map((r) => ({
      id: r.id,
      placeId: r.place_id,
      placeName: withTranslation(pMap.get(r.place_id) || {}, tMap.get(r.place_id), ['name']).name || '',
      userId: r.user_id,
      userName: users.get(r.user_id)?.name || 'User',
      message: r.message,
      phone: r.phone,
      status: r.status,
      createdAt: r.created_at,
      restaurantResponse: r.restaurant_response || null,
      restaurantRespondedAt: r.restaurant_responded_at || null,
    })),
  });
});

router.put('/proposals/:id/respond', authMiddleware, async (req, res) => {
  const proposalId = req.params.id;
  const userId = req.user.userId;
  const response = String(req.body?.response ?? req.body?.message ?? '').trim();
  if (!response) return res.status(400).json({ error: 'Response message required' });
  const proposal = await collection('offer_proposals').findOne({ id: proposalId }, { projection: { _id: 0, place_id: 1 } });
  if (!proposal) return res.status(404).json({ error: 'Proposal not found' });
  const own = await collection('place_owners').findOne({ user_id: userId, place_id: proposal.place_id }, { projection: { _id: 1 } });
  if (!own) return res.status(403).json({ error: 'You must own this restaurant to respond' });
  await collection('offer_proposals').updateOne(
    { id: proposalId },
    { $set: { restaurant_response: response, restaurant_responded_at: new Date(), status: 'accepted', updated_at: new Date() } }
  );
  res.json({ success: true, message: 'Response sent' });
});

router.get('/place/:placeId', async (req, res) => {
  const lang = getRequestLang(req);
  const placeId = req.params.placeId;
  const offers = await collection('place_offers').find({ place_id: placeId, expires_at: { $gt: new Date() } }, { projection: { _id: 0 } }).sort({ expires_at: 1 }).toArray();
  const tr = lang && lang !== 'en'
    ? await collection('place_offer_translations').find({ offer_id: { $in: offers.map((o) => o.id) }, lang }, { projection: { _id: 0 } }).toArray()
    : [];
  const trMap = new Map(tr.map((x) => [x.offer_id, x]));
  res.json({ offers: offers.map((o) => mapOffer(withTranslation(o, trMap.get(o.id), ['title', 'description']))) });
});

module.exports = router;
