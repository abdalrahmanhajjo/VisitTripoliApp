const express = require('express');
const { collection } = require('../db');
const { responseCache } = require('../middleware/responseCache');
const { authMiddleware } = require('../middleware/auth');
const { getRequestLang } = require('../utils/requestLang');
const { rowToPlace, getUploadsBaseUrl } = require('../utils/placeRow');
const { isValidPlaceId } = require('../middleware/security');
const { loadTranslationMap, withTranslation } = require('../utils/mongoTranslations');

const router = express.Router();

const CACHE_MAX_AGE = 300; // 5 min for client/CDN

// GET /api/places (cached 3 min; translations from DB when lang=ar|fr)
// Optional query: ?category_id=food (restaurants only)
router.get('/', responseCache(3 * 60 * 1000, { includeHost: true }), async (req, res) => {
  res.set('Cache-Control', `public, max-age=${CACHE_MAX_AGE}`);
  try {
    const baseUrl = getUploadsBaseUrl(req);
    const lang = getRequestLang(req);
    const categoryId = (req.query.category_id || '').toString().trim();
    if (categoryId && !isValidPlaceId(categoryId)) {
      return res.status(400).json({ error: 'Invalid category id' });
    }
    const filter = categoryId ? { category_id: categoryId } : {};
    const placesRaw = await collection('places')
      .find(filter, { projection: { _id: 0 } })
      .sort({ name: 1 })
      .toArray();
    const ids = placesRaw.map((p) => p.id).filter(Boolean);
    const trMap = await loadTranslationMap(collection('place_translations'), 'place_id', ids, lang);
    const places = placesRaw.map((p) =>
      rowToPlace(
        withTranslation(p, trMap.get(p.id), [
          'name',
          'description',
          'location',
          'category',
          'duration',
          'price',
          'best_time',
          'tags',
        ]),
        baseUrl
      )
    );
    res.json({ popular: places, locations: places });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      error: 'Failed to fetch places',
      detail: process.env.NODE_ENV !== 'production' ? err.message : undefined,
    });
  }
});

// GET /api/places/:id
router.get('/:id', async (req, res) => {
  try {
    if (!isValidPlaceId(req.params.id)) {
      return res.status(400).json({ error: 'Invalid place id' });
    }
    const baseUrl = getUploadsBaseUrl(req);
    const lang = getRequestLang(req);
    const base = await collection('places').findOne(
      { id: req.params.id },
      { projection: { _id: 0 } }
    );
    if (!base) {
      return res.status(404).json({ error: 'Place not found' });
    }
    const tr = lang && lang !== 'en'
      ? await collection('place_translations').findOne(
          { place_id: req.params.id, lang },
          { projection: { _id: 0 } }
        )
      : null;
    const row = withTranslation(base, tr, [
      'name',
      'description',
      'location',
      'category',
      'duration',
      'price',
      'best_time',
      'tags',
    ]);
    res.json(rowToPlace(row, baseUrl));
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch place' });
  }
});

// Web parity aliases for place-scoped resources.
router.get('/:id/reviews', async (req, res) => {
  try {
    const placeId = String(req.params.id || '').trim();
    if (!isValidPlaceId(placeId)) {
      return res.status(400).json({ error: 'Invalid place id' });
    }
    const rows = await collection('place_reviews')
      .find({ place_id: placeId }, { projection: { _id: 0 } })
      .sort({ created_at: -1 })
      .limit(100)
      .toArray();
    const users = new Map(
      (
        await collection('profiles')
          .find(
            { user_id: { $in: rows.map((r) => r.user_id).filter(Boolean) } },
            { projection: { _id: 0, user_id: 1, name: 1 } },
          )
          .toArray()
      ).map((u) => [u.user_id, u.name])
    );
    return res.json({
      reviews: rows.map((r) => ({
        id: r.id,
        user_id: r.user_id,
        stars: r.rating,
        title: r.title || '',
        text: r.review || '',
        date: r.visit_date ? new Date(r.visit_date).toISOString().slice(0, 10) : '',
        author: users.get(r.user_id) || 'Visitor',
      })),
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Failed to fetch reviews' });
  }
});

router.post('/:id/reviews', authMiddleware, async (req, res) => {
  try {
    const placeId = String(req.params.id || '').trim();
    if (!isValidPlaceId(placeId)) {
      return res.status(400).json({ error: 'Invalid place id' });
    }
    const stars = parseInt(req.body?.rating, 10);
    if (Number.isNaN(stars) || stars < 1 || stars > 5) {
      return res.status(400).json({ error: 'rating must be between 1 and 5' });
    }
    await collection('place_reviews').insertOne({
      id: `${Date.now()}_${Math.random().toString(36).slice(2, 9)}`,
      place_id: placeId,
      user_id: req.user.userId,
      rating: stars,
      title: req.body?.title || null,
      review: req.body?.text || req.body?.review || null,
      visit_date: req.body?.visitDate || req.body?.visit_date || null,
      created_at: new Date(),
      updated_at: new Date(),
    });
    return res.status(201).json({ success: true });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Failed to create review' });
  }
});

router.delete('/:id/reviews/:reviewId', authMiddleware, async (req, res) => {
  try {
    const placeId = String(req.params.id || '').trim();
    if (!isValidPlaceId(placeId)) {
      return res.status(400).json({ error: 'Invalid place id' });
    }
    const row = await collection('place_reviews').findOne(
      { id: req.params.reviewId, place_id: placeId },
      { projection: { _id: 0, user_id: 1 } },
    );
    if (!row) return res.status(404).json({ error: 'Review not found' });
    if (row.user_id !== req.user.userId) {
      return res.status(403).json({ error: 'You can only delete your own review' });
    }
    await collection('place_reviews').deleteOne({
      id: req.params.reviewId,
      place_id: placeId,
    });
    return res.status(204).send();
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Failed to delete review' });
  }
});

router.get('/:id/promotions', async (req, res) => {
  try {
    const placeId = String(req.params.id || '').trim();
    if (!isValidPlaceId(placeId)) {
      return res.status(400).json({ error: 'Invalid place id' });
    }
    const offers = await collection('place_offers')
      .find(
        { place_id: placeId, expires_at: { $gt: new Date() } },
        { projection: { _id: 0 } },
      )
      .sort({ expires_at: 1 })
      .toArray();
    return res.json({ offers });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Failed to fetch promotions' });
  }
});

router.post('/:id/checkin', authMiddleware, async (req, res) => {
  try {
    const placeId = String(req.params.id || '').trim();
    if (!isValidPlaceId(placeId)) {
      return res.status(400).json({ error: 'Invalid place id' });
    }
    const checkinToken = String(req.body?.checkinToken || req.body?.checkin_token || '').trim();
    if (!checkinToken) {
      return res.status(400).json({ error: 'checkinToken required' });
    }
    const place = await collection('places').findOne(
      { id: placeId },
      { projection: { _id: 0, checkin_token: 1 } },
    );
    if (!place) return res.status(404).json({ error: 'Place not found' });
    if (place.checkin_token !== checkinToken) {
      return res.status(403).json({ error: 'Invalid check-in code' });
    }
    await collection('check_ins').insertOne({
      id: `${Date.now()}_${Math.random().toString(36).slice(2, 9)}`,
      user_id: req.user.userId,
      place_id: placeId,
      checked_at: new Date(),
    });
    return res.status(201).json({ success: true });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Failed to check in' });
  }
});

module.exports = router;
