const express = require('express');
const { collection } = require('../db');
const { responseCache } = require('../middleware/responseCache');
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

module.exports = router;
