const express = require('express');
const { query } = require('../db');
const { authMiddleware } = require('../middleware/auth');
const { getRequestLang } = require('../utils/requestLang');
const { rowToPlace, getUploadsBaseUrl } = require('../utils/placeRow');

const router = express.Router();
router.use(authMiddleware);

// GET /api/user/saved-places — full place objects (localized like /api/places)
router.get('/saved-places', async (req, res) => {
  try {
    const userId = req.user.userId;
    const lang = getRequestLang(req);
    const baseUrl = getUploadsBaseUrl(req);
    const result = await query(
      `SELECT p.id, p.latitude, p.longitude, p.images, p.rating, p.review_count, p.hours, p.search_name, p.category_id,
              COALESCE(pt.name, p.name) AS name, COALESCE(pt.description, p.description) AS description,
              COALESCE(pt.location, p.location) AS location, COALESCE(pt.category, p.category) AS category,
              COALESCE(pt.duration, p.duration) AS duration, COALESCE(pt.price, p.price) AS price,
              COALESCE(pt.best_time, p.best_time) AS best_time, COALESCE(pt.tags, p.tags) AS tags
       FROM saved_places sp
       JOIN places p ON p.id = sp.place_id
       LEFT JOIN place_translations pt ON pt.place_id = p.id AND pt.lang = $1
       WHERE sp.user_id = $2
       ORDER BY p.name`,
      [lang, userId],
    );
    const places = result.rows.map((r) => rowToPlace(r, baseUrl));
    res.json({ places });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch saved places' });
  }
});

// PUT /api/user/saved-places/:placeId — idempotent save
router.put('/saved-places/:placeId', async (req, res) => {
  try {
    const userId = req.user.userId;
    const placeId = (req.params.placeId || '').toString().trim();
    if (!placeId) return res.status(400).json({ error: 'Invalid place id' });
    const exists = await query('SELECT 1 FROM places WHERE id = $1', [placeId]);
    if (exists.rows.length === 0) return res.status(404).json({ error: 'Place not found' });
    await query(
      `INSERT INTO saved_places (user_id, place_id) VALUES ($1, $2)
       ON CONFLICT (user_id, place_id) DO NOTHING`,
      [userId, placeId],
    );
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to save place' });
  }
});

// DELETE /api/user/saved-places/:placeId
router.delete('/saved-places/:placeId', async (req, res) => {
  try {
    const userId = req.user.userId;
    const placeId = (req.params.placeId || '').toString().trim();
    if (!placeId) return res.status(400).json({ error: 'Invalid place id' });
    await query('DELETE FROM saved_places WHERE user_id = $1 AND place_id = $2', [userId, placeId]);
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to remove saved place' });
  }
});

module.exports = router;
