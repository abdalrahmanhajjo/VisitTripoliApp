const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { collection } = require('../db');
const { getRequestLang } = require('../utils/requestLang');
const { loadTranslationMap, withTranslation } = require('../utils/mongoTranslations');

const isProd = process.env.NODE_ENV === 'production';
const router = express.Router();

router.get('/', authMiddleware, async (req, res) => {
  try {
    const lang = getRequestLang(req);
    const userId = req.user.userId;
    const bookings = await collection('bookings')
      .find({ user_id: userId, status: { $ne: 'cancelled' } }, { projection: { _id: 0 } })
      .sort({ booking_date: -1 })
      .limit(50)
      .toArray();
    const placeIds = bookings.map((b) => b.place_id).filter(Boolean);
    const tourIds = bookings.map((b) => b.tour_id).filter(Boolean);
    const [places, tours] = await Promise.all([
      collection('places')
        .find({ id: { $in: placeIds } }, { projection: { _id: 0, id: 1, name: 1 } })
        .toArray(),
      collection('tours')
        .find({ id: { $in: tourIds } }, { projection: { _id: 0, id: 1, name: 1 } })
        .toArray(),
    ]);
    const [placeTrMap, tourTrMap] = await Promise.all([
      loadTranslationMap(collection('place_translations'), 'place_id', placeIds, lang),
      loadTranslationMap(collection('tour_translations'), 'tour_id', tourIds, lang),
    ]);
    const placeMap = new Map(
      places.map((p) => {
        const row = withTranslation(p, placeTrMap.get(p.id), ['name']);
        return [p.id, row.name];
      })
    );
    const tourMap = new Map(
      tours.map((t) => {
        const row = withTranslation(t, tourTrMap.get(t.id), ['name']);
        return [t.id, row.name];
      })
    );
    const out = bookings.map((b) => ({
      ...b,
      place_name: b.place_id ? (placeMap.get(b.place_id) || null) : null,
      tour_name: b.tour_id ? (tourMap.get(b.tour_id) || null) : null,
    }));
    res.json({ bookings: out });
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
    await collection('bookings').insertOne({
      id: new Date().getTime().toString(36) + Math.random().toString(36).slice(2, 8),
      user_id: userId,
      place_id: placeId || null,
      tour_id: tourId || null,
      booking_type: bookingType,
      booking_date: bookingDate,
      time_slot: timeSlot || null,
      party_size: partySize || 1,
      notes: notes || null,
      status: 'pending',
      created_at: new Date(),
    });
    res.status(201).json({ success: true, message: 'Booking created' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create booking', ...(isProd ? {} : { detail: err.message }) });
  }
});

router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.userId;
    const result = await collection('bookings').updateOne(
      { id: req.params.id, user_id: userId },
      { $set: { status: 'cancelled', updated_at: new Date() } }
    );
    if (!result.matchedCount) return res.status(404).json({ error: 'Not found' });
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to cancel', ...(isProd ? {} : { detail: err.message }) });
  }
});

module.exports = router;
