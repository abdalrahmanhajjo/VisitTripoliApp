const express = require('express');
const { collection } = require('../db');
const { responseCache } = require('../middleware/responseCache');
const { getRequestLang } = require('../utils/requestLang');
const { toArray, loadTranslationMap, withTranslation } = require('../utils/mongoTranslations');

const router = express.Router();

function rowToTour(row) {
  return {
    id: row.id,
    name: row.name,
    duration: row.duration,
    durationHours: row.duration_hours,
    locations: row.locations,
    rating: row.rating,
    reviews: row.reviews,
    price: row.price,
    currency: row.currency,
    priceDisplay: row.price_display,
    badge: row.badge,
    badgeColor: row.badge_color,
    description: row.description,
    image: row.image,
    difficulty: row.difficulty,
    languages: toArray(row.languages),
    includes: toArray(row.includes),
    excludes: toArray(row.excludes),
    highlights: toArray(row.highlights),
    itinerary: toArray(row.itinerary),
    placeIds: toArray(row.place_ids)
  };
}

const CACHE_MAX_AGE = 300;

// GET /api/tours (translations from DB when lang=ar|fr)
router.get('/', responseCache(), async (req, res) => {
  res.set('Cache-Control', `public, max-age=${CACHE_MAX_AGE}`);
  try {
    const lang = getRequestLang(req);
    const toursRaw = await collection('tours')
      .find({}, { projection: { _id: 0 } })
      .sort({ name: 1 })
      .toArray();
    const ids = toursRaw.map((t) => t.id).filter(Boolean);
    const trMap = await loadTranslationMap(collection('tour_translations'), 'tour_id', ids, lang);
    const tours = toursRaw.map((t) =>
      rowToTour(
        withTranslation(t, trMap.get(t.id), [
          'name',
          'duration',
          'price_display',
          'badge',
          'description',
          'difficulty',
          'includes',
          'excludes',
          'highlights',
          'itinerary',
        ])
      )
    );
    res.json({ featured: tours });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      error: 'Failed to fetch tours',
      detail: process.env.NODE_ENV !== 'production' ? err.message : undefined,
    });
  }
});

// GET /api/tours/:id
router.get('/:id', async (req, res) => {
  try {
    const lang = getRequestLang(req);
    const base = await collection('tours').findOne(
      { id: req.params.id },
      { projection: { _id: 0 } }
    );
    if (!base) {
      return res.status(404).json({ error: 'Tour not found' });
    }
    const tr = lang && lang !== 'en'
      ? await collection('tour_translations').findOne(
          { tour_id: req.params.id, lang },
          { projection: { _id: 0 } }
        )
      : null;
    const row = withTranslation(base, tr, [
      'name',
      'duration',
      'price_display',
      'badge',
      'description',
      'difficulty',
      'includes',
      'excludes',
      'highlights',
      'itinerary',
    ], lang);
    res.json(rowToTour(row));
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch tour' });
  }
});

module.exports = router;
