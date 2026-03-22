const express = require('express');
const crypto = require('crypto');
const { authMiddleware } = require('../middleware/auth');
const { query } = require('../db');

const router = express.Router();

// POST /api/trip-shares - Create share link for a trip
router.post('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { tripId, canEdit = false, expiresInHours } = req.body || {};
    const tripIdStr = (tripId || '').toString().trim();
    if (!tripIdStr) return res.status(400).json({ error: 'tripId required' });

    const trip = (await query('SELECT id FROM trips WHERE id = $1 AND user_id = $2', [tripIdStr, userId])).rows[0];
    if (!trip) return res.status(404).json({ error: 'Trip not found' });

    const shareToken = crypto.randomBytes(32).toString('hex');
    let expiresAt = null;
    if (expiresInHours != null && expiresInHours > 0) {
      const h = parseInt(expiresInHours, 10);
      if (h > 0) expiresAt = new Date(Date.now() + h * 60 * 60 * 1000);
    }

    await query(
      'INSERT INTO trip_shares (trip_id, share_token, expires_at, can_edit) VALUES ($1, $2, $3, $4)',
      [tripIdStr, shareToken, expiresAt, !!canEdit]
    );

    const baseUrl = process.env.APP_URL || 'https://tripoli-explorer.app';
    const shareUrl = `${baseUrl}/trip-share/${shareToken}`;

    res.status(201).json({ success: true, shareToken, shareUrl, expiresAt: expiresAt?.toISOString() });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create share' });
  }
});

// GET /api/trip-shares/:token - Get shared trip (public, for viewing)
router.get('/:token', async (req, res) => {
  try {
    const token = (req.params.token || '').trim();
    if (!token) return res.status(400).json({ error: 'Token required' });

    const share = (await query(
      `SELECT ts.id, ts.trip_id, ts.share_token, ts.expires_at, ts.can_edit, t.name, t.start_date, t.end_date, t.description, t.days
       FROM trip_shares ts
       JOIN trips t ON t.id = ts.trip_id
       WHERE ts.share_token = $1`,
      [token]
    )).rows[0];

    if (!share) return res.status(404).json({ error: 'Share not found' });
    if (share.expires_at && new Date(share.expires_at) < new Date()) {
      return res.status(410).json({ error: 'Share link expired' });
    }

    res.json({
      tripId: share.trip_id,
      name: share.name,
      startDate: share.start_date,
      endDate: share.end_date,
      description: share.description,
      days: share.days,
      canEdit: share.can_edit,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch share' });
  }
});

module.exports = router;
