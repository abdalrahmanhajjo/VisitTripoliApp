const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { query } = require('../db');

const isProd = process.env.NODE_ENV === 'production';
const router = express.Router();

router.get('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.userId;
    const result = await query(
      `SELECT b.id, b.place_id, b.tour_id, b.booking_type, b.booking_date, b.time_slot,
              b.party_size, b.status, b.notes, b.created_at,
              p.name AS place_name, t.name AS tour_name
       FROM bookings b
       LEFT JOIN places p ON p.id = b.place_id
       LEFT JOIN tours t ON t.id = b.tour_id
       WHERE b.user_id = $1 AND b.status != 'cancelled'
       ORDER BY b.booking_date DESC LIMIT 50`,
      [userId]
    );
    res.json({ bookings: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch bookings', ...(isProd ? {} : { detail: err.message }) });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { placeId, tourId, bookingType, bookingDate, timeSlot, partySize, notes } = req.body || {};
    if (!bookingType || !bookingDate) return res.status(400).json({ error: 'bookingType and bookingDate required' });
    if (bookingType === 'place' && !placeId) return res.status(400).json({ error: 'placeId required' });
    if (bookingType === 'tour' && !tourId) return res.status(400).json({ error: 'tourId required' });
    await query(
      `INSERT INTO bookings (user_id, place_id, tour_id, booking_type, booking_date, time_slot, party_size, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [userId, placeId || null, tourId || null, bookingType, bookingDate, timeSlot || null, partySize || 1, notes || null]
    );
    res.status(201).json({ success: true, message: 'Booking created' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create booking', ...(isProd ? {} : { detail: err.message }) });
  }
});

router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.userId;
    const result = await query('UPDATE bookings SET status = $1 WHERE id = $2 AND user_id = $3 RETURNING id', ['cancelled', req.params.id, userId]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to cancel', ...(isProd ? {} : { detail: err.message }) });
  }
});

module.exports = router;
