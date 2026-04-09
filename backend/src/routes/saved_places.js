const express = require('express');
const { collection } = require('../db');
const { authMiddleware } = require('../middleware/auth');
const { getRequestLang } = require('../utils/requestLang');
const { rowToPlace, getUploadsBaseUrl } = require('../utils/placeRow');
const { loadTranslationMap, withTranslation } = require('../utils/mongoTranslations');

const router = express.Router();
router.use(authMiddleware);

// GET /api/user/saved-places — full place objects (localized like /api/places)
router.get('/saved-places', async (req, res) => {
  try {
    const userId = req.user.userId;
    const lang = getRequestLang(req);
    const baseUrl = getUploadsBaseUrl(req);
    const saves = await collection('saved_places')
      .find({ user_id: userId }, { projection: { _id: 0, place_id: 1 } })
      .toArray();
    const placeIds = saves.map((s) => s.place_id).filter(Boolean);
    const placesRaw = await collection('places')
      .find({ id: { $in: placeIds } }, { projection: { _id: 0 } })
      .sort({ name: 1 })
      .toArray();
    const trMap = await loadTranslationMap(collection('place_translations'), 'place_id', placeIds, lang);
    const places = placesRaw.map((p) =>
      rowToPlace(withTranslation(p, trMap.get(p.id), [
        'name',
        'description',
        'location',
        'category',
        'duration',
        'price',
        'best_time',
        'tags',
      ]), baseUrl)
    );
    res.json({ places });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch saved places' });
  }
});

// Web parity aliases (`favourites`/`favorites`) for the same saved places domain.
router.get('/favourites', async (req, res) => {
  req.url = '/saved-places';
  return router.handle(req, res);
});
router.get('/favorites', async (req, res) => {
  req.url = '/saved-places';
  return router.handle(req, res);
});

// PUT /api/user/saved-places/:placeId — idempotent save
router.put('/saved-places/:placeId', async (req, res) => {
  try {
    const userId = req.user.userId;
    const placeId = (req.params.placeId || '').toString().trim();
    if (!placeId) return res.status(400).json({ error: 'Invalid place id' });
    const exists = await collection('places').findOne(
      { id: placeId },
      { projection: { _id: 1 } }
    );
    if (!exists) return res.status(404).json({ error: 'Place not found' });
    await collection('saved_places').updateOne(
      { user_id: userId, place_id: placeId },
      { $setOnInsert: { user_id: userId, place_id: placeId, created_at: new Date() } },
      { upsert: true }
    );
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to save place' });
  }
});

router.put('/favourites/:placeId', async (req, res) => {
  req.url = `/saved-places/${req.params.placeId}`;
  return router.handle(req, res);
});
router.put('/favorites/:placeId', async (req, res) => {
  req.url = `/saved-places/${req.params.placeId}`;
  return router.handle(req, res);
});

// DELETE /api/user/saved-places/:placeId
router.delete('/saved-places/:placeId', async (req, res) => {
  try {
    const userId = req.user.userId;
    const placeId = (req.params.placeId || '').toString().trim();
    if (!placeId) return res.status(400).json({ error: 'Invalid place id' });
    await collection('saved_places').deleteOne({ user_id: userId, place_id: placeId });
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to remove saved place' });
  }
});

router.delete('/favourites/:placeId', async (req, res) => {
  req.url = `/saved-places/${req.params.placeId}`;
  return router.handle(req, res);
});
router.delete('/favorites/:placeId', async (req, res) => {
  req.url = `/saved-places/${req.params.placeId}`;
  return router.handle(req, res);
});

module.exports = router;
