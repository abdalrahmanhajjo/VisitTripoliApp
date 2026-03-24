const crypto = require('crypto');
const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { query } = require('../db');
const { getRequestLang } = require('../utils/requestLang');

function timingSafeEqualStrings(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string') return false;
  const ba = Buffer.from(a, 'utf8');
  const bb = Buffer.from(b, 'utf8');
  if (ba.length !== bb.length) return false;
  try {
    return crypto.timingSafeEqual(ba, bb);
  } catch {
    return false;
  }
}

const router = express.Router();

// GET /api/badges - list all badges
router.get('/', async (req, res) => {
  try {
    const result = await query('SELECT id, name, icon, description, criteria FROM badges ORDER BY name');
    res.json({ badges: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch badges' });
  }
});

// GET /api/badges/me - user's badges and check-ins
router.get('/me', authMiddleware, async (req, res) => {
  try {
    const lang = getRequestLang(req);
    const userId = req.user.userId;
    const [badges, checkIns] = await Promise.all([
      query(
        `SELECT b.id, b.name, b.icon, b.description, ub.earned_at
         FROM user_badges ub
         JOIN badges b ON b.id = ub.badge_id
         WHERE ub.user_id = $1
         ORDER BY ub.earned_at DESC`,
        [userId]
      ),
      query(
        `SELECT c.place_id, c.checked_at, COALESCE(pt.name, p.name) AS place_name
         FROM check_ins c
         JOIN places p ON p.id = c.place_id
         LEFT JOIN place_translations pt ON pt.place_id = p.id AND pt.lang = $2
         WHERE c.user_id = $1
         ORDER BY c.checked_at DESC
         LIMIT 50`,
        [userId, lang]
      ),
    ]);
    const placeCount = (await query('SELECT COUNT(DISTINCT place_id)::int AS c FROM check_ins WHERE user_id = $1', [userId])).rows[0].c;
    res.json({ badges: badges.rows, checkIns: checkIns.rows, placesCheckedIn: placeCount });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch badges' });
  }
});

// POST /api/badges/check-in - check in at a place (requires official door QR: checkinToken)
router.post('/check-in', authMiddleware, async (req, res) => {
  try {
    const lang = getRequestLang(req);
    const userId = req.user.userId;
    const { placeId, checkinToken } = req.body || {};
    if (!placeId) return res.status(400).json({ error: 'placeId required' });
    if (!checkinToken || typeof checkinToken !== 'string') {
      return res.status(400).json({
        error: 'Official check-in QR required. Open Check in in the app and scan the code posted at the entrance.',
      });
    }

    const row = (await query(
      `SELECT p.id, p.checkin_token, COALESCE(pt.name, p.name) AS name FROM places p
       LEFT JOIN place_translations pt ON pt.place_id = p.id AND pt.lang = $2
       WHERE p.id = $1`,
      [placeId, lang]
    )).rows[0];
    if (!row) return res.status(404).json({ error: 'Place not found' });
    if (!timingSafeEqualStrings(row.checkin_token, checkinToken.trim())) {
      return res.status(403).json({
        error: 'Invalid check-in code. Use the official QR printed at this place.',
      });
    }
    const place = { id: row.id, name: row.name };

    await query('INSERT INTO check_ins (user_id, place_id) VALUES ($1, $2)', [userId, placeId]);

    const placeCount = (await query('SELECT COUNT(DISTINCT place_id)::int AS c FROM check_ins WHERE user_id = $1', [userId])).rows[0].c;
    if (placeCount >= 15) {
      await query('UPDATE users SET feed_discoverable = true WHERE id = $1', [userId]);
    }
    const tripCount = (await query('SELECT COUNT(*)::int AS c FROM trips WHERE user_id = $1', [userId])).rows[0].c;

    const newBadges = [];
    const badgesToAdd = [
      { criteria: 'place_1', minPlaces: 1 },
      { criteria: 'place_5', minPlaces: 5 },
      { criteria: 'place_10', minPlaces: 10 },
      { criteria: 'place_15', minPlaces: 15 },
      { criteria: 'trip_1', minTrips: 1 },
    ];
    for (const b of badgesToAdd) {
      const badge = (await query('SELECT id, name FROM badges WHERE criteria = $1', [b.criteria])).rows[0];
      if (!badge) continue;
      const has = (await query('SELECT 1 FROM user_badges WHERE user_id = $1 AND badge_id = $2', [userId, badge.id])).rows[0];
      if (has) continue;
      const qualify = (b.minPlaces != null && placeCount >= b.minPlaces) || (b.minTrips != null && tripCount >= b.minTrips);
      if (qualify) {
        await query('INSERT INTO user_badges (user_id, badge_id) VALUES ($1, $2)', [userId, badge.id]);
        newBadges.push(badge);
      }
    }

    res.status(201).json({ success: true, placeName: place.name, newBadges });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to check in' });
  }
});

module.exports = router;
