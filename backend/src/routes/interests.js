const express = require('express');
const { collection } = require('../db');
const { responseCache } = require('../middleware/responseCache');
const { getRequestLang } = require('../utils/requestLang');
const { toArray, loadTranslationMap, withTranslation } = require('../utils/mongoTranslations');

const router = express.Router();

function rowToInterest(row) {
  const tags = toArray(row.tags);
  return {
    id: row.id,
    name: row.name,
    icon: row.icon,
    description: row.description || '',
    color: row.color || '#666666',
    count: row.count ?? 0,
    popularity: row.popularity ?? 0,
    tags
  };
}

// GET /api/interests (translations from DB when lang=ar|fr)
router.get('/', responseCache(), async (req, res) => {
  try {
    const lang = getRequestLang(req);
    const interestsRaw = await collection('interests')
      .find({}, { projection: { _id: 0 } })
      .sort({ popularity: -1, name: 1 })
      .toArray();
    const ids = interestsRaw.map((i) => i.id).filter(Boolean);
    const trMap = await loadTranslationMap(collection('interest_translations'), 'interest_id', ids, lang);
    const interests = interestsRaw.map((i) =>
      rowToInterest(withTranslation(i, trMap.get(i.id), ['name', 'description', 'tags']))
    );
    res.json({ interests });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      error: 'Failed to fetch interests',
      detail: process.env.NODE_ENV !== 'production' ? err.message : undefined,
    });
  }
});

module.exports = router;
