const express = require('express');
const { query } = require('../db');
const { responseCache } = require('../middleware/responseCache');
const { getRequestLang } = require('../utils/requestLang');
const { asyncHandler } = require('../utils/asyncHandler');
const { AppError } = require('../utils/AppError');

const router = express.Router();

function rowToCategory(row) {
  return {
    id: row.id,
    name: row.name,
    icon: row.icon,
    description: row.description || '',
    tags: Array.isArray(row.tags) ? row.tags : (row.tags ? JSON.parse(row.tags) : []),
    count: row.count ?? 0,
    color: row.color || '#666666'
  };
}

const CACHE_MAX_AGE = 300;

// GET /api/categories (translations from DB when lang=ar|fr)
router.get('/', responseCache(), asyncHandler(async (req, res) => {
  res.set('Cache-Control', `public, max-age=${CACHE_MAX_AGE}`);
  const lang = getRequestLang(req);
  try {
    const result = await query(
      `SELECT c.id, c.icon, c.count, c.color,
              COALESCE(ct.name, c.name) AS name,
              COALESCE(ct.description, c.description) AS description,
              COALESCE(ct.tags, c.tags) AS tags
       FROM categories c
       LEFT JOIN category_translations ct ON ct.category_id = c.id AND ct.lang = $1
       ORDER BY c.name`,
      [lang]
    );
    const categories = result.rows.map(rowToCategory);
    res.json({ categories });
  } catch (err) {
    console.error(err);
    throw new AppError(
      500,
      process.env.NODE_ENV === 'production' ? 'Failed to fetch categories' : (err.message || 'Failed to fetch categories')
    );
  }
}));

module.exports = router;
