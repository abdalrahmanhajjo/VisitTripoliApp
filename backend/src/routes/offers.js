const express = require('express');
const { authMiddleware, optionalAuthMiddleware } = require('../middleware/auth');
const { query } = require('../db');
const { getRequestLang } = require('../utils/requestLang');

const router = express.Router();

// POST /api/offers/propose - User sends offer proposal TO a restaurant
router.post('/propose', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { place_id, message, phone, suggested_discount_type, suggested_discount_value } = req.body || {};
    const placeId = (place_id || '').toString().trim();
    const msg = (message || '').toString().trim();
    const phoneNum = (phone || '').toString().trim();
    if (!placeId || !msg) return res.status(400).json({ error: 'Place ID and message required' });
    if (!phoneNum) return res.status(400).json({ error: 'Phone number required' });
    const discountType = ['percent', 'fixed', 'bogo', 'free_item'].includes(suggested_discount_type) ? suggested_discount_type : null;
    const discountVal = suggested_discount_value != null ? parseFloat(suggested_discount_value) : null;
    await query(
      `INSERT INTO offer_proposals (user_id, place_id, message, phone, suggested_discount_type, suggested_discount_value)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [userId, placeId, msg, phoneNum, discountType, discountVal]
    );
    res.status(201).json({ success: true, message: 'Offer proposal sent to restaurant' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to send proposal' });
  }
});

function toNumber(v) {
  if (v == null) return null;
  if (typeof v === 'number') return v;
  const n = parseFloat(v);
  return isNaN(n) ? null : n;
}

function mapOffer(row) {
  let imgs = row.place_images;
  if (typeof imgs === 'string') {
    try { imgs = JSON.parse(imgs); } catch { imgs = []; }
  }
  return {
    ...row,
    discount_value: toNumber(row.discount_value),
    place_images: Array.isArray(imgs) ? imgs : [],
    expires_at: row.expires_at ? new Date(row.expires_at).toISOString() : null,
  };
}

// GET /api/offers - List active offers from restaurants only (category_id = 'food')
router.get('/', optionalAuthMiddleware, async (req, res) => {
  try {
    const lang = getRequestLang(req);
    const result = await query(
      `SELECT o.id, o.place_id,
              COALESCE(pot.title, o.title) AS title,
              COALESCE(pot.description, o.description) AS description,
              o.discount_type, o.discount_value,
              o.start_time, o.end_time, o.expires_at,
              COALESCE(pt.name, p.name) AS place_name, p.images AS place_images
       FROM place_offers o
       JOIN places p ON p.id = o.place_id AND p.category_id = 'food'
       LEFT JOIN place_translations pt ON pt.place_id = p.id AND pt.lang = $1
       LEFT JOIN place_offer_translations pot ON pot.offer_id = o.id AND pot.lang = $1
       WHERE o.expires_at > NOW()
       ORDER BY o.expires_at ASC
       LIMIT 50`,
      [lang]
    );
    res.json({ offers: result.rows.map(mapOffer) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch offers' });
  }
});

// GET /api/offers/my-proposals - User's proposals with restaurant responses (auth required)
router.get('/my-proposals', authMiddleware, async (req, res) => {
  try {
    const lang = getRequestLang(req);
    const userId = req.user.userId;
    const result = await query(
      `SELECT op.id, op.place_id, op.message, op.phone, op.status, op.created_at,
              op.restaurant_response, op.restaurant_responded_at,
              COALESCE(pt.name, p.name) AS place_name
       FROM offer_proposals op
       JOIN places p ON p.id = op.place_id
       LEFT JOIN place_translations pt ON pt.place_id = p.id AND pt.lang = $1
       WHERE op.user_id = $2
       ORDER BY op.created_at DESC
       LIMIT 50`,
      [lang, userId]
    );
    res.json({
      proposals: result.rows.map(r => ({
        id: r.id,
        placeId: r.place_id,
        placeName: r.place_name,
        message: r.message,
        phone: r.phone,
        status: r.status,
        createdAt: r.created_at,
        restaurantResponse: r.restaurant_response || null,
        restaurantRespondedAt: r.restaurant_responded_at || null,
      })),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch proposals' });
  }
});

// GET /api/offers/place-proposals - Proposals for places owned by current user (business owner)
router.get('/place-proposals', authMiddleware, async (req, res) => {
  try {
    const lang = getRequestLang(req);
    const userId = req.user.userId;
    const result = await query(
      `SELECT op.id, op.place_id, op.user_id, op.message, op.phone, op.status, op.created_at,
              op.restaurant_response, op.restaurant_responded_at,
              COALESCE(pt.name, p.name) AS place_name,
              u.name AS user_name
       FROM offer_proposals op
       JOIN place_owners po ON po.place_id = op.place_id AND po.user_id = $2
       JOIN places p ON p.id = op.place_id
       LEFT JOIN place_translations pt ON pt.place_id = p.id AND pt.lang = $1
       LEFT JOIN users u ON u.id = op.user_id
       ORDER BY op.created_at DESC
       LIMIT 100`,
      [lang, userId]
    );
    res.json({
      proposals: result.rows.map(r => ({
        id: r.id,
        placeId: r.place_id,
        placeName: r.place_name,
        userId: r.user_id,
        userName: r.user_name || 'User',
        message: r.message,
        phone: r.phone,
        status: r.status,
        createdAt: r.created_at,
        restaurantResponse: r.restaurant_response || null,
        restaurantRespondedAt: r.restaurant_responded_at || null,
      })),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch proposals' });
  }
});

// PUT /api/offers/proposals/:id/respond - Restaurant owner responds (auth + must own place)
router.put('/proposals/:id/respond', authMiddleware, async (req, res) => {
  try {
    const proposalId = req.params.id;
    const userId = req.user.userId;
    const response = (req.body?.response ?? req.body?.message ?? '').toString().trim();
    if (!response) return res.status(400).json({ error: 'Response message required' });
    const row = (await query(
      'SELECT op.place_id, po.user_id AS owner_id FROM offer_proposals op LEFT JOIN place_owners po ON po.place_id = op.place_id AND po.user_id = $1 WHERE op.id = $2',
      [userId, proposalId]
    )).rows[0];
    if (!row) return res.status(404).json({ error: 'Proposal not found' });
    if (row.owner_id !== userId) return res.status(403).json({ error: 'You must own this restaurant to respond' });
    await query(
      `UPDATE offer_proposals SET restaurant_response = $1, restaurant_responded_at = NOW(), status = 'accepted' WHERE id = $2`,
      [response, proposalId]
    );
    res.json({ success: true, message: 'Response sent' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to send response' });
  }
});

// GET /api/offers/place/:placeId - Offers for a place
router.get('/place/:placeId', async (req, res) => {
  try {
    const lang = getRequestLang(req);
    const { placeId } = req.params;
    const result = await query(
      `SELECT o.id, o.place_id,
              COALESCE(pot.title, o.title) AS title,
              COALESCE(pot.description, o.description) AS description,
              o.discount_type, o.discount_value,
              o.start_time, o.end_time, o.expires_at
       FROM place_offers o
       LEFT JOIN place_offer_translations pot ON pot.offer_id = o.id AND pot.lang = $2
       WHERE o.place_id = $1 AND o.expires_at > NOW()
       ORDER BY o.expires_at ASC`,
      [placeId, lang]
    );
    res.json({ offers: result.rows.map(mapOffer) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch offers' });
  }
});

module.exports = router;
