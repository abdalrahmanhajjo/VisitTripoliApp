const express = require('express');
const { collection } = require('../db');
const { responseCache } = require('../middleware/responseCache');
const { getRequestLang } = require('../utils/requestLang');
const { asyncHandler } = require('../utils/asyncHandler');
const { AppError } = require('../utils/AppError');
const { toArray, loadTranslationMap, withTranslation } = require('../utils/mongoTranslations');

const router = express.Router();

function rowToCategory(row) {
  return {
    id: row.id,
    name: row.name,
    icon: row.icon,
    description: row.description || '',
    tags: toArray(row.tags),
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
    const categoriesRaw = await collection('categories')
      .find({}, { projection: { _id: 0 } })
      .sort({ name: 1 })
      .toArray();
    const ids = categoriesRaw.map((c) => c.id).filter(Boolean);
    const trMap = await loadTranslationMap(collection('category_translations'), 'category_id', ids, lang);
    const categories = categoriesRaw.map((c) =>
      rowToCategory(withTranslation(c, trMap.get(c.id), ['name', 'description', 'tags']))
    );
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
