const express = require('express');
const crypto = require('crypto');
const { authMiddleware } = require('../middleware/auth');
const { collection } = require('../db');

const router = express.Router();

// POST /api/trip-shares - Create share link for a trip
router.post('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { tripId, canEdit = false, expiresInHours } = req.body || {};
    const tripIdStr = (tripId || '').toString().trim();
    if (!tripIdStr) return res.status(400).json({ error: 'tripId required' });

    const trip = await collection('trips').findOne(
      { id: tripIdStr, user_id: userId },
      { projection: { _id: 0, id: 1 } }
    );
    if (!trip) return res.status(404).json({ error: 'Trip not found' });

    const shareToken = crypto.randomBytes(32).toString('hex');
    let expiresAt = null;
    if (expiresInHours != null && expiresInHours > 0) {
      const h = parseInt(expiresInHours, 10);
      if (h > 0) expiresAt = new Date(Date.now() + h * 60 * 60 * 1000);
    }

    await collection('trip_shares').insertOne({
      trip_id: tripIdStr,
      share_token: shareToken,
      expires_at: expiresAt,
      can_edit: !!canEdit,
      created_at: new Date(),
    });

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

    const share = await collection('trip_shares').findOne(
      { share_token: token },
      { projection: { _id: 0 } }
    );

    if (!share) return res.status(404).json({ error: 'Share not found' });
    if (share.expires_at && new Date(share.expires_at) < new Date()) {
      return res.status(410).json({ error: 'Share link expired' });
    }
    const trip = await collection('trips').findOne(
      { id: share.trip_id },
      { projection: { _id: 0, id: 1, name: 1, start_date: 1, end_date: 1, description: 1, days: 1 } }
    );
    if (!trip) return res.status(404).json({ error: 'Trip not found' });

    res.json({
      tripId: share.trip_id,
      name: trip.name,
      startDate: trip.start_date,
      endDate: trip.end_date,
      description: trip.description,
      days: trip.days,
      canEdit: share.can_edit,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch share' });
  }
});

module.exports = router;
