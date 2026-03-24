const express = require('express');
const { query } = require('../db');
const { responseCache } = require('../middleware/responseCache');
const { getRequestLang } = require('../utils/requestLang');
const { rowToPlace, getUploadsBaseUrl } = require('../utils/placeRow');
const { isValidPlaceId } = require('../middleware/security');

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
    const whereClause = categoryId ? ' AND p.category_id = $2' : '';
    const params = categoryId ? [lang, categoryId] : [lang];
    const result = await query(
      `SELECT p.id, p.latitude, p.longitude, p.images, p.rating, p.review_count, p.hours, p.search_name, p.category_id,
              COALESCE(pt.name, p.name) AS name, COALESCE(pt.description, p.description) AS description,
              COALESCE(pt.location, p.location) AS location, COALESCE(pt.category, p.category) AS category,
              COALESCE(pt.duration, p.duration) AS duration, COALESCE(pt.price, p.price) AS price,
              COALESCE(pt.best_time, p.best_time) AS best_time, COALESCE(pt.tags, p.tags) AS tags
       FROM places p
       LEFT JOIN place_translations pt ON pt.place_id = p.id AND pt.lang = $1
       WHERE 1=1${whereClause}
       ORDER BY p.name`,
      params,
    );
    const places = result.rows.map((r) => rowToPlace(r, baseUrl));
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
    const result = await query(
      `SELECT p.id, p.latitude, p.longitude, p.images, p.rating, p.review_count, p.hours, p.search_name, p.category_id,
              COALESCE(pt.name, p.name) AS name, COALESCE(pt.description, p.description) AS description,
              COALESCE(pt.location, p.location) AS location, COALESCE(pt.category, p.category) AS category,
              COALESCE(pt.duration, p.duration) AS duration, COALESCE(pt.price, p.price) AS price,
              COALESCE(pt.best_time, p.best_time) AS best_time, COALESCE(pt.tags, p.tags) AS tags
       FROM places p
       LEFT JOIN place_translations pt ON pt.place_id = p.id AND pt.lang = $1
       WHERE p.id = $2`,
      [lang, req.params.id],
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Place not found' });
    }
    res.json(rowToPlace(result.rows[0], baseUrl));
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch place' });
  }
});

module.exports = router;
