const express = require('express');
const { query } = require('../db');
const { responseCache } = require('../middleware/responseCache');
const { getRequestLang } = require('../utils/requestLang');

const router = express.Router();

function resolveImageUrls(images, baseUrl) {
  if (!Array.isArray(images)) return [];
  const base = (baseUrl || process.env.UPLOADS_BASE_URL || '').replace(/\/$/, '');
  return images.filter(Boolean).map((url) => {
    if (!url || typeof url !== 'string') return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/') && base) return `${base}${url}`;
    return url;
  }).filter(Boolean);
}

function safeParseJson(val, fallback = []) {
  if (Array.isArray(val)) return val;
  if (typeof val !== 'string') return fallback;
  try { return JSON.parse(val); } catch { return fallback; }
}

function rowToPlace(row, baseUrl) {
  let images = safeParseJson(row.images, []);
  images = resolveImageUrls(images, baseUrl);
  const result = {
    id: row.id,
    name: row.name,
    description: row.description || '',
    location: row.location || '',
    latitude: row.latitude ?? null,
    longitude: row.longitude ?? null,
    images,
    category: row.category || '',
    categoryId: row.category_id,
    duration: row.duration,
    price: row.price,
    bestTime: row.best_time,
    rating: row.rating,
    reviewCount: row.review_count,
    hours: row.hours,
    tags: row.tags,
    searchName: row.search_name
  };
  if (row.latitude != null && row.longitude != null) {
    result.coordinates = { lat: row.latitude, lng: row.longitude };
  }
  if (images.length === 1) result.image = images[0];
  return result;
}

function getUploadsBaseUrl(req) {
  if (process.env.UPLOADS_BASE_URL) return process.env.UPLOADS_BASE_URL;
  const proto = req.get('x-forwarded-proto') || (req.secure ? 'https' : 'http');
  const host = req.get('x-forwarded-host') || req.get('host') || `localhost:${process.env.PORT || 3000}`;
  if (process.env.UPLOADS_PATH) return `${proto}://${host}`;
  const uploadsPort = process.env.UPLOADS_PORT || process.env.WEBTRIPOLI_PORT || '3001';
  const hostOnly = host.includes(':') ? host.split(':')[0] : host;
  return `${proto}://${hostOnly}:${uploadsPort}`;
}

const CACHE_MAX_AGE = 300; // 5 min for client/CDN

// GET /api/places (cached 3 min; translations from DB when lang=ar|fr)
// Optional query: ?category_id=food (restaurants only)
router.get('/', responseCache(3 * 60 * 1000, { includeHost: true }), async (req, res) => {
  res.set('Cache-Control', `public, max-age=${CACHE_MAX_AGE}`);
  try {
    const baseUrl = getUploadsBaseUrl(req);
    const lang = getRequestLang(req);
    const categoryId = (req.query.category_id || '').toString().trim();
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
      params
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
      [lang, req.params.id]
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
