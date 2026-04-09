const crypto = require('crypto');
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
function mapCoupon(row) {
  return {
    ...row,
    discount_value: toNumber(row.discount_value) ?? 0,
    min_purchase: toNumber(row.min_purchase),
    usage_limit: row.usage_limit != null ? parseInt(row.usage_limit, 10) : null,
    valid_until: row.valid_until ? new Date(row.valid_until).toISOString() : null,
  };
}
async function enrichCoupons(coupons, lang) {
  const placeIds = coupons.map((c) => c.place_id).filter(Boolean);
  const tourIds = coupons.map((c) => c.tour_id).filter(Boolean);
  const eventIds = coupons.map((c) => c.event_id).filter(Boolean);
  const [places, tours, events, pt, tt, et] = await Promise.all([
    collection('places').find({ id: { $in: placeIds } }, { projection: { _id: 0, id: 1, name: 1 } }).toArray(),
    collection('tours').find({ id: { $in: tourIds } }, { projection: { _id: 0, id: 1, name: 1 } }).toArray(),
    collection('events').find({ id: { $in: eventIds } }, { projection: { _id: 0, id: 1, name: 1 } }).toArray(),
    lang && lang !== 'en' ? collection('place_translations').find({ place_id: { $in: placeIds }, lang }, { projection: { _id: 0 } }).toArray() : Promise.resolve([]),
    lang && lang !== 'en' ? collection('tour_translations').find({ tour_id: { $in: tourIds }, lang }, { projection: { _id: 0 } }).toArray() : Promise.resolve([]),
    lang && lang !== 'en' ? collection('event_translations').find({ event_id: { $in: eventIds }, lang }, { projection: { _id: 0 } }).toArray() : Promise.resolve([]),
  ]);
  const pMap = new Map(places.map((x) => [x.id, x]));
  const tMap = new Map(tours.map((x) => [x.id, x]));
  const eMap = new Map(events.map((x) => [x.id, x]));
  const ptMap = new Map(pt.map((x) => [x.place_id, x]));
  const ttMap = new Map(tt.map((x) => [x.tour_id, x]));
  const etMap = new Map(et.map((x) => [x.event_id, x]));
  return coupons.map((c) => ({
    ...c,
    place_name: c.place_id ? withTranslation(pMap.get(c.place_id) || {}, ptMap.get(c.place_id), ['name']).name || null : null,
    tour_name: c.tour_id ? withTranslation(tMap.get(c.tour_id) || {}, ttMap.get(c.tour_id), ['name']).name || null : null,
    event_name: c.event_id ? withTranslation(eMap.get(c.event_id) || {}, etMap.get(c.event_id), ['name']).name || null : null,
  }));
}

router.get('/', optionalAuthMiddleware, async (req, res) => {
  const lang = getRequestLang(req);
  const couponsRaw = await collection('coupons').find({ valid_from: { $lte: new Date() }, valid_until: { $gt: new Date() } }, { projection: { _id: 0 } }).sort({ valid_until: 1 }).limit(50).toArray();
  const coupons = await enrichCoupons(couponsRaw, lang);
  const userId = req.user?.userId;
  let usedSet = new Set();
  if (userId) usedSet = new Set((await collection('coupon_redemptions').find({ user_id: userId }, { projection: { _id: 0, coupon_id: 1 } }).toArray()).map((x) => x.coupon_id));
  res.json({ coupons: coupons.map((c) => ({ ...mapCoupon(c), used_by_me: usedSet.has(c.id) })) });
});

router.post('/validate', optionalAuthMiddleware, async (req, res) => {
  const lang = getRequestLang(req);
  const code = String(req.body?.code || '').trim().toUpperCase();
  if (!code) return res.status(400).json({ error: 'Code required' });
  const coupon = await collection('coupons').findOne({ code: { $regex: `^${code}$`, $options: 'i' }, valid_from: { $lte: new Date() }, valid_until: { $gt: new Date() } }, { projection: { _id: 0 } });
  if (!coupon) return res.status(404).json({ error: 'Invalid or expired code' });
  const usageCount = await collection('coupon_redemptions').countDocuments({ coupon_id: coupon.id });
  if (coupon.usage_limit != null && usageCount >= coupon.usage_limit) return res.status(400).json({ error: 'Offer limit reached' });
  if (req.user?.userId) {
    const redeemed = await collection('coupon_redemptions').findOne({ user_id: req.user.userId, coupon_id: coupon.id }, { projection: { _id: 1 } });
    if (redeemed) return res.status(400).json({ error: 'Already used' });
  }
  const [mapped] = await enrichCoupons([coupon], lang);
  res.json({ valid: true, coupon: { ...mapCoupon(mapped), usage_count: usageCount } });
});

router.post('/redeem', authMiddleware, async (req, res) => {
  const lang = getRequestLang(req);
  const userId = req.user.userId;
  const code = String(req.body?.code || '').trim().toUpperCase();
  if (!code) return res.status(400).json({ error: 'Code required' });
  const coupon = await collection('coupons').findOne({ code: { $regex: `^${code}$`, $options: 'i' }, valid_from: { $lte: new Date() }, valid_until: { $gt: new Date() } }, { projection: { _id: 0 } });
  if (!coupon) return res.status(404).json({ error: 'Invalid or expired code' });
  const usageCount = await collection('coupon_redemptions').countDocuments({ coupon_id: coupon.id });
  if (coupon.usage_limit != null && usageCount >= coupon.usage_limit) return res.status(400).json({ error: 'Limit reached' });
  const existing = await collection('coupon_redemptions').findOne({ user_id: userId, coupon_id: coupon.id }, { projection: { _id: 1 } });
  if (existing) return res.status(400).json({ error: 'Already used' });
  const redemptionId = crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}_${Math.random()}`;
  await collection('coupon_redemptions').insertOne({ id: redemptionId, user_id: userId, coupon_id: coupon.id, created_at: new Date() });
  const [mapped] = await enrichCoupons([coupon], lang);
  res.json({ success: true, message: 'Redeemed', redemption_id: redemptionId, coupon: mapCoupon(mapped), code: coupon.code });
});

module.exports = router;
