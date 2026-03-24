const express = require('express');
const { authMiddleware, optionalAuthMiddleware } = require('../middleware/auth');
const { query } = require('../db');
const { isValidPlaceId } = require('../middleware/security');

const router = express.Router();

/** Review title/body are user-generated (single locale per row). Translate via review_translations if you add that table. */

// GET /api/reviews?placeId=...
// Supports place_reviews, Supabase "reviews" table, and works without "profiles" table.
function isRelationNotFound(err) {
  const msg = (err && err.message) || '';
  return /relation ["']?.+["']? does not exist/i.test(msg);
}

router.get('/', optionalAuthMiddleware, async (req, res) => {
  const { placeId } = req.query;
  if (!placeId) return res.status(400).json({ error: 'placeId is required' });
  if (!isValidPlaceId(String(placeId))) {
    return res.status(400).json({ error: 'Invalid placeId' });
  }
  try {
    let result;
    const attempts = [
      {
        sql: `SELECT r.id, r.user_id, r.rating AS stars,
              COALESCE(r.title, '') AS title, COALESCE(r.review, '') AS text,
              COALESCE(TO_CHAR(r.visit_date, 'YYYY-MM-DD'), '') AS date,
              COALESCE(p.name, 'Visitor') AS author
              FROM place_reviews r LEFT JOIN profiles p ON p.user_id = r.user_id
              WHERE r.place_id = $1 ORDER BY r.created_at DESC LIMIT 100`,
        params: [placeId],
      },
      {
        sql: `SELECT r.id, r.user_id, r.rating AS stars,
              COALESCE(r.title, '') AS title, COALESCE(r.review, '') AS text,
              '' AS date, COALESCE(p.name, 'Visitor') AS author
              FROM reviews r LEFT JOIN profiles p ON p.user_id = r.user_id
              WHERE r.place_id = $1 ORDER BY r.id DESC LIMIT 100`,
        params: [placeId],
      },
      {
        sql: `SELECT r.id, r.user_id, r.rating AS stars,
              COALESCE(r.title, '') AS title, COALESCE(r.review, '') AS text,
              COALESCE(TO_CHAR(r.visit_date, 'YYYY-MM-DD'), '') AS date,
              'Visitor' AS author
              FROM place_reviews r WHERE r.place_id = $1 ORDER BY r.created_at DESC LIMIT 100`,
        params: [placeId],
      },
      {
        sql: `SELECT r.id, r.user_id, r.rating AS stars,
              COALESCE(r.title, '') AS title, COALESCE(r.review, '') AS text,
              '' AS date, 'Visitor' AS author
              FROM reviews r WHERE r.place_id = $1 ORDER BY r.id DESC LIMIT 100`,
        params: [placeId],
      },
    ];
    for (const { sql, params } of attempts) {
      try {
        result = await query(sql, params);
        break;
      } catch (e) {
        const msg = (e && e.message) || '';
        if (!isRelationNotFound(e) && !/column .+ does not exist/i.test(msg)) throw e;
      }
    }
    if (!result) {
      console.warn('Reviews: no place_reviews or reviews table; returning empty list.');
      return res.json({ reviews: [] });
    }
    return res.json({ reviews: result.rows });
  } catch (err) {
    console.error('Reviews GET failed:', err.message);
    return res.json({ reviews: [] });
  }
});

// POST /api/reviews
// Supports both place_reviews and Supabase-style reviews table.
router.post('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { placeId, rating, title, text, visitDate } = req.body || {};
    if (!placeId || !rating) {
      return res.status(400).json({ error: 'placeId and rating are required' });
    }
    if (!isValidPlaceId(String(placeId))) {
      return res.status(400).json({ error: 'Invalid placeId' });
    }
    const stars = parseInt(rating, 10);
    if (Number.isNaN(stars) || stars < 1 || stars > 5) {
      return res.status(400).json({ error: 'rating must be between 1 and 5' });
    }
    let useReviewsTable = false;
    try {
      await query(
        'INSERT INTO place_reviews (place_id, user_id, rating, title, review, visit_date) VALUES ($1, $2, $3, $4, $5, $6)',
        [placeId, userId, stars, title || null, text || null, visitDate || null],
      );
    } catch (e) {
      const msg = (e && e.message) || '';
      if (/relation ["']?place_reviews["']? does not exist/i.test(msg)) {
        useReviewsTable = true;
        await query(
          'INSERT INTO reviews (place_id, user_id, rating, title, review) VALUES ($1, $2, $3, $4, $5)',
          [placeId, userId, stars, title || null, text || null],
        );
      } else {
        throw e;
      }
    }
    // Update aggregate rating & review_count on places
    const aggQuery = useReviewsTable
      ? 'SELECT AVG(rating)::float AS rating, COUNT(*)::int AS count FROM reviews WHERE place_id = $1'
      : 'SELECT AVG(rating)::float AS rating, COUNT(*)::int AS count FROM place_reviews WHERE place_id = $1';
    const agg = await query(aggQuery, [placeId]);
    const row = agg.rows[0];
    if (row) {
      await query(
        'UPDATE places SET rating = $1, review_count = $2 WHERE id = $3',
        [row.rating, row.count, placeId],
      );
    }
    res.status(201).json({ success: true });
  } catch (err) {
    console.error(err);
    const isProd = process.env.NODE_ENV === 'production';
    res.status(500).json({ error: 'Failed to create review', ...(isProd ? {} : { detail: err.message }) });
  }
});

// PATCH /api/reviews/:id - Update own review (auth required)
router.patch('/:id', authMiddleware, async (req, res) => {
  const reviewId = req.params.id;
  const userId = req.user.userId;
  const { rating, title, text, visitDate } = req.body || {};
  if (!reviewId) return res.status(400).json({ error: 'Review id is required' });
  const stars = rating != null ? parseInt(rating, 10) : null;
  if (stars != null && (Number.isNaN(stars) || stars < 1 || stars > 5)) {
    return res.status(400).json({ error: 'rating must be between 1 and 5' });
  }
  try {
    /** SQL identifiers only — never from request input. */
    const tables = ['place_reviews', 'reviews'];
    let updated = false;
    let placeId = null;
    let usedTable = null;
    for (const table of tables) {
      try {
        const owner = await query(
          `SELECT user_id, place_id FROM ${table} WHERE id = $1`,
          [reviewId],
        );
        if (owner.rows.length === 0) continue;
        if (owner.rows[0].user_id !== userId) {
          return res.status(403).json({ error: 'You can only edit your own review' });
        }
        placeId = owner.rows[0].place_id;
        const updates = [];
        const values = [];
        let i = 1;
        if (stars != null) {
          updates.push(`rating = $${i++}`);
          values.push(stars);
        }
        if (title !== undefined) {
          updates.push(`title = $${i++}`);
          values.push(title || null);
        }
        if (text !== undefined) {
          updates.push(`review = $${i++}`);
          values.push(text || null);
        }
        if (visitDate !== undefined && table === 'place_reviews') {
          updates.push(`visit_date = $${i++}`);
          values.push(visitDate || null);
        }
        if (updates.length === 0) {
          return res.status(400).json({ error: 'No fields to update' });
        }
        values.push(reviewId);
        await query(
          `UPDATE ${table} SET ${updates.join(', ')} WHERE id = $${i}`,
          values,
        );
        updated = true;
        usedTable = table;
        break;
      } catch (e) {
        const msg = (e && e.message) || '';
        if (/relation ["']?.+["']? does not exist/i.test(msg)) continue;
        throw e;
      }
    }
    if (!updated) return res.status(404).json({ error: 'Review not found' });
    if (placeId) {
      try {
        const agg = await query(
          `SELECT AVG(rating)::float AS rating, COUNT(*)::int AS count FROM ${usedTable} WHERE place_id = $1`,
          [placeId],
        );
        const row = agg.rows[0];
        if (row) {
          await query('UPDATE places SET rating = $1, review_count = $2 WHERE id = $3', [row.rating, row.count, placeId]);
        }
      } catch (_) {}
    }
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    const isProd = process.env.NODE_ENV === 'production';
    res.status(500).json({ error: 'Failed to update review', ...(isProd ? {} : { detail: err.message }) });
  }
});

// DELETE /api/reviews/:id - Delete own review (auth required)
router.delete('/:id', authMiddleware, async (req, res) => {
  const reviewId = req.params.id;
  const userId = req.user.userId;
  if (!reviewId) return res.status(400).json({ error: 'Review id is required' });
  try {
    const tables = ['place_reviews', 'reviews'];
    let deleted = false;
    let placeId = null;
    for (const table of tables) {
      try {
        const row = await query(
          `SELECT place_id, user_id FROM ${table} WHERE id = $1`,
          [reviewId],
        );
        if (row.rows.length === 0) continue;
        if (row.rows[0].user_id !== userId) {
          return res.status(403).json({ error: 'You can only delete your own review' });
        }
        placeId = row.rows[0].place_id;
        await query(`DELETE FROM ${table} WHERE id = $1`, [reviewId]);
        deleted = true;
        break;
      } catch (e) {
        const msg = (e && e.message) || '';
        if (/relation ["']?.+["']? does not exist/i.test(msg)) continue;
        throw e;
      }
    }
    if (!deleted) return res.status(404).json({ error: 'Review not found' });
    if (placeId) {
      try {
        const agg = await query(
          'SELECT AVG(rating)::float AS rating, COUNT(*)::int AS count FROM place_reviews WHERE place_id = $1',
          [placeId],
        );
        const row = agg.rows[0];
        if (row) {
          await query('UPDATE places SET rating = $1, review_count = $2 WHERE id = $3', [row.rating, row.count, placeId]);
        }
      } catch (_) {
        try {
          const agg = await query(
            'SELECT AVG(rating)::float AS rating, COUNT(*)::int AS count FROM reviews WHERE place_id = $1',
            [placeId],
          );
          const row = agg.rows[0];
          if (row) {
            await query('UPDATE places SET rating = $1, review_count = $2 WHERE id = $3', [row.rating, row.count, placeId]);
          }
        } catch (__) {}
      }
    }
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    const isProd = process.env.NODE_ENV === 'production';
    res.status(500).json({ error: 'Failed to delete review', ...(isProd ? {} : { detail: err.message }) });
  }
});

module.exports = router;

