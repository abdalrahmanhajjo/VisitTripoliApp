const express = require('express');
const { authMiddleware, optionalAuthMiddleware } = require('../middleware/auth');
const { query } = require('../db');

const router = express.Router();

function toNumber(v) {
  if (v == null) return null;
  if (typeof v === 'number') return v;
  const n = parseFloat(v);
  return isNaN(n) ? null : n;
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

router.get('/', optionalAuthMiddleware, async (req, res) => {
  try {
    const result = await query(
      `SELECT c.id, c.code, c.discount_type, c.discount_value, c.min_purchase,
              c.valid_from, c.valid_until, c.usage_limit, c.place_id, c.tour_id, c.event_id,
              p.name AS place_name, t.name AS tour_name, e.name AS event_name
       FROM coupons c
       LEFT JOIN places p ON p.id = c.place_id
       LEFT JOIN tours t ON t.id = c.tour_id
       LEFT JOIN events e ON e.id = c.event_id
       WHERE c.valid_from <= NOW() AND c.valid_until > NOW()
       ORDER BY c.valid_until ASC LIMIT 50`
    );
    let userId = req.user?.userId;
    let usedIds = new Set();
    if (userId) {
      const red = await query('SELECT coupon_id FROM coupon_redemptions WHERE user_id = $1', [userId]);
      usedIds = new Set(red.rows.map(r => r.coupon_id));
    }
    const coupons = result.rows.map(r => {
      const mapped = mapCoupon(r);
      return { ...mapped, used_by_me: usedIds.has(r.id) };
    });
    res.json({ coupons });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch coupons' });
  }
});

router.post('/validate', optionalAuthMiddleware, async (req, res) => {
  try {
    const code = (req.body?.code || '').toString().trim().toUpperCase();
    if (!code) return res.status(400).json({ error: 'Code required' });
    const result = await query(
      `SELECT c.*, p.name AS place_name, t.name AS tour_name, e.name AS event_name
       FROM coupons c
       LEFT JOIN places p ON p.id = c.place_id
       LEFT JOIN tours t ON t.id = c.tour_id
       LEFT JOIN events e ON e.id = c.event_id
       WHERE UPPER(c.code) = $1 AND c.valid_from <= NOW() AND c.valid_until > NOW()`,
      [code]
    );
    const coupon = result.rows[0];
    if (!coupon) return res.status(404).json({ error: 'Invalid or expired code' });
    const usageCount = (await query('SELECT COUNT(*)::int AS c FROM coupon_redemptions WHERE coupon_id = $1', [coupon.id])).rows[0].c;
    if (coupon.usage_limit != null && usageCount >= coupon.usage_limit) {
      return res.status(400).json({ error: 'Offer limit reached' });
    }
    const userId = req.user?.userId;
    if (userId) {
      const redeemed = (await query('SELECT 1 FROM coupon_redemptions WHERE user_id = $1 AND coupon_id = $2', [userId, coupon.id])).rows[0];
      if (redeemed) return res.status(400).json({ error: 'Already used' });
    }
    res.json({ valid: true, coupon: { ...mapCoupon(coupon), usage_count: usageCount } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to validate' });
  }
});

router.post('/redeem', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.userId;
    const code = (req.body?.code || '').toString().trim().toUpperCase();
    if (!code) return res.status(400).json({ error: 'Code required' });
    const result = await query(
      `SELECT c.id, c.code, c.discount_type, c.discount_value, c.min_purchase,
              c.valid_until, c.place_id, p.name AS place_name, t.name AS tour_name, e.name AS event_name
       FROM coupons c
       LEFT JOIN places p ON p.id = c.place_id
       LEFT JOIN tours t ON t.id = c.tour_id
       LEFT JOIN events e ON e.id = c.event_id
       WHERE UPPER(c.code) = $1 AND c.valid_from <= NOW() AND c.valid_until > NOW()`,
      [code]
    );
    const coupon = result.rows[0];
    if (!coupon) return res.status(404).json({ error: 'Invalid or expired code' });
    const usageCount = (await query('SELECT COUNT(*)::int AS c FROM coupon_redemptions WHERE coupon_id = $1', [coupon.id])).rows[0].c;
    if (coupon.usage_limit != null && usageCount >= coupon.usage_limit) return res.status(400).json({ error: 'Limit reached' });
    const existing = (await query('SELECT 1 FROM coupon_redemptions WHERE user_id = $1 AND coupon_id = $2', [userId, coupon.id])).rows[0];
    if (existing) return res.status(400).json({ error: 'Already used' });
    const ins = await query('INSERT INTO coupon_redemptions (user_id, coupon_id) VALUES ($1, $2) RETURNING id', [userId, coupon.id]);
    const redemptionId = ins.rows[0].id;
    const mapped = mapCoupon(coupon);
    res.json({
      success: true,
      message: 'Redeemed',
      redemption_id: redemptionId,
      coupon: mapped,
      code: coupon.code,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to redeem' });
  }
});

module.exports = router;
