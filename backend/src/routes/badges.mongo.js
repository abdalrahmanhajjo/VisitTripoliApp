const crypto = require('crypto');
const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { collection } = require('../db');
const { getRequestLang } = require('../utils/requestLang');
const { withTranslation } = require('../utils/mongoTranslations');

const router = express.Router();

function timingSafeEqualStrings(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string') return false;
  const ba = Buffer.from(a, 'utf8');
  const bb = Buffer.from(b, 'utf8');
  if (ba.length !== bb.length) return false;
  try { return crypto.timingSafeEqual(ba, bb); } catch { return false; }
}

router.get('/', async (_req, res) => {
  const badges = await collection('badges').find({}, { projection: { _id: 0 } }).sort({ name: 1 }).toArray();
  res.json({ badges });
});

router.get('/me', authMiddleware, async (req, res) => {
  const lang = getRequestLang(req);
  const userId = req.user.userId;
  const [ub, cis] = await Promise.all([
    collection('user_badges').find({ user_id: userId }, { projection: { _id: 0 } }).sort({ earned_at: -1 }).toArray(),
    collection('check_ins').find({ user_id: userId }, { projection: { _id: 0 } }).sort({ checked_at: -1 }).limit(50).toArray(),
  ]);
  const badgeIds = ub.map((x) => x.badge_id);
  const badges = new Map((await collection('badges').find({ id: { $in: badgeIds } }, { projection: { _id: 0 } }).toArray()).map((b) => [b.id, b]));
  const placeIds = cis.map((x) => x.place_id).filter(Boolean);
  const places = await collection('places').find({ id: { $in: placeIds } }, { projection: { _id: 0, id: 1, name: 1 } }).toArray();
  const tr = lang && lang !== 'en' ? await collection('place_translations').find({ place_id: { $in: placeIds }, lang }, { projection: { _id: 0 } }).toArray() : [];
  const pMap = new Map(places.map((p) => [p.id, p]));
  const tMap = new Map(tr.map((x) => [x.place_id, x]));
  const checkIns = cis.map((c) => ({ place_id: c.place_id, checked_at: c.checked_at, place_name: withTranslation(pMap.get(c.place_id) || {}, tMap.get(c.place_id), ['name']).name || '' }));
  const outBadges = ub.map((r) => ({ ...(badges.get(r.badge_id) || {}), earned_at: r.earned_at }));
  const placeCount = new Set(cis.map((c) => c.place_id)).size;
  res.json({ badges: outBadges, checkIns, placesCheckedIn: placeCount });
});

router.post('/check-in', authMiddleware, async (req, res) => {
  const lang = getRequestLang(req);
  const userId = req.user.userId;
  const { placeId, checkinToken } = req.body || {};
  if (!placeId) return res.status(400).json({ error: 'placeId required' });
  if (!checkinToken || typeof checkinToken !== 'string') {
    return res.status(400).json({ error: 'Official check-in QR required. Open Check in in the app and scan the code posted at the entrance.' });
  }
  const place = await collection('places').findOne({ id: placeId }, { projection: { _id: 0, id: 1, name: 1, checkin_token: 1 } });
  if (!place) return res.status(404).json({ error: 'Place not found' });
  if (!timingSafeEqualStrings(place.checkin_token, checkinToken.trim())) {
    return res.status(403).json({ error: 'Invalid check-in code. Use the official QR printed at this place.' });
  }
  if (lang && lang !== 'en') {
    const tr = await collection('place_translations').findOne({ place_id: placeId, lang }, { projection: { _id: 0, name: 1 } });
    if (tr?.name) place.name = tr.name;
  }
  await collection('check_ins').insertOne({ id: crypto.randomUUID(), user_id: userId, place_id: placeId, checked_at: new Date() });
  const checkIns = await collection('check_ins').find({ user_id: userId }, { projection: { _id: 0, place_id: 1 } }).toArray();
  const placeCount = new Set(checkIns.map((c) => c.place_id)).size;
  if (placeCount >= 15) await collection('users').updateOne({ id: userId }, { $set: { feed_discoverable: true, updated_at: new Date() } });
  const tripCount = await collection('trips').countDocuments({ user_id: userId });
  const badgeRules = [{ criteria: 'place_1', minPlaces: 1 }, { criteria: 'place_5', minPlaces: 5 }, { criteria: 'place_10', minPlaces: 10 }, { criteria: 'place_15', minPlaces: 15 }, { criteria: 'trip_1', minTrips: 1 }];
  const newBadges = [];
  for (const b of badgeRules) {
    const badge = await collection('badges').findOne({ criteria: b.criteria }, { projection: { _id: 0, id: 1, name: 1 } });
    if (!badge) continue;
    const has = await collection('user_badges').findOne({ user_id: userId, badge_id: badge.id }, { projection: { _id: 1 } });
    if (has) continue;
    const qualify = (b.minPlaces != null && placeCount >= b.minPlaces) || (b.minTrips != null && tripCount >= b.minTrips);
    if (qualify) {
      await collection('user_badges').insertOne({ id: crypto.randomUUID(), user_id: userId, badge_id: badge.id, earned_at: new Date() });
      newBadges.push(badge);
    }
  }
  res.status(201).json({ success: true, placeName: place.name, newBadges });
});

module.exports = router;
