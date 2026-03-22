const express = require('express');
const { query } = require('../db');
const { responseCache } = require('../middleware/responseCache');
const { getRequestLang } = require('../utils/requestLang');

const router = express.Router();

function rowToInterest(row) {
  let tags = [];
  if (Array.isArray(row.tags)) tags = row.tags;
  else if (row.tags) {
    try {
      tags = typeof row.tags === 'string' ? JSON.parse(row.tags) : (row.tags || []);
    } catch (_) { tags = []; }
  }
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
    const result = await query(
      `SELECT i.id, i.icon, i.color, i.count, i.popularity,
              COALESCE(it.name, i.name) AS name,
              COALESCE(it.description, i.description) AS description,
              COALESCE(it.tags, i.tags) AS tags
       FROM interests i
       LEFT JOIN interest_translations it ON it.interest_id = i.id AND it.lang = $1
       ORDER BY i.popularity DESC, i.name`,
      [lang]
    );
    const interests = result.rows.map(rowToInterest);
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
