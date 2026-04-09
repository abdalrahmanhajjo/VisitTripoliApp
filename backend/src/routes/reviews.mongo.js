const express = require('express');
const { authMiddleware, optionalAuthMiddleware } = require('../middleware/auth');
const { collection } = require('../db');
const { isValidPlaceId } = require('../middleware/security');

const router = express.Router();

function mapReview(r, author) {
  return {
    id: r.id,
    user_id: r.user_id,
    stars: r.rating,
    title: r.title || '',
    text: r.review || '',
    date: r.visit_date ? new Date(r.visit_date).toISOString().slice(0, 10) : '',
    author: author || 'Visitor',
  };
}

async function refreshPlaceRating(placeId) {
  const agg = await collection('place_reviews').aggregate([
    { $match: { place_id: placeId } },
    { $group: { _id: null, rating: { $avg: '$rating' }, count: { $sum: 1 } } },
  ]).toArray();
  const row = agg[0] || { rating: null, count: 0 };
  await collection('places').updateOne({ id: placeId }, { $set: { rating: row.rating, review_count: row.count, updated_at: new Date() } });
}

router.get('/', optionalAuthMiddleware, async (req, res) => {
  const { placeId } = req.query;
  if (!placeId) return res.status(400).json({ error: 'placeId is required' });
  if (!isValidPlaceId(String(placeId))) return res.status(400).json({ error: 'Invalid placeId' });
  try {
    const rows = await collection('place_reviews').find({ place_id: String(placeId) }, { projection: { _id: 0 } }).sort({ created_at: -1 }).limit(100).toArray();
    const users = new Map((await collection('profiles').find({ user_id: { $in: rows.map((r) => r.user_id).filter(Boolean) } }, { projection: { _id: 0, user_id: 1, name: 1 } }).toArray()).map((u) => [u.user_id, u.name]));
    return res.json({ reviews: rows.map((r) => mapReview(r, users.get(r.user_id))) });
  } catch {
    return res.json({ reviews: [] });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { placeId, rating, title, text, visitDate } = req.body || {};
    if (!placeId || !rating) return res.status(400).json({ error: 'placeId and rating are required' });
    if (!isValidPlaceId(String(placeId))) return res.status(400).json({ error: 'Invalid placeId' });
    const stars = parseInt(rating, 10);
    if (Number.isNaN(stars) || stars < 1 || stars > 5) return res.status(400).json({ error: 'rating must be between 1 and 5' });
    await collection('place_reviews').insertOne({
      id: `${Date.now()}_${Math.random().toString(36).slice(2, 9)}`,
      place_id: String(placeId),
      user_id: userId,
      rating: stars,
      title: title || null,
      review: text || null,
      visit_date: visitDate || null,
      created_at: new Date(),
      updated_at: new Date(),
    });
    await refreshPlaceRating(String(placeId));
    return res.status(201).json({ success: true });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to create review', ...(process.env.NODE_ENV === 'production' ? {} : { detail: err.message }) });
  }
});

router.patch('/:id', authMiddleware, async (req, res) => {
  const reviewId = req.params.id;
  const userId = req.user.userId;
  const { rating, title, text, visitDate } = req.body || {};
  const stars = rating != null ? parseInt(rating, 10) : null;
  if (stars != null && (Number.isNaN(stars) || stars < 1 || stars > 5)) return res.status(400).json({ error: 'rating must be between 1 and 5' });
  const row = await collection('place_reviews').findOne({ id: reviewId }, { projection: { _id: 0 } });
  if (!row) return res.status(404).json({ error: 'Review not found' });
  if (row.user_id !== userId) return res.status(403).json({ error: 'You can only edit your own review' });
  const set = { updated_at: new Date() };
  if (stars != null) set.rating = stars;
  if (title !== undefined) set.title = title || null;
  if (text !== undefined) set.review = text || null;
  if (visitDate !== undefined) set.visit_date = visitDate || null;
  if (Object.keys(set).length === 1) return res.status(400).json({ error: 'No fields to update' });
  await collection('place_reviews').updateOne({ id: reviewId }, { $set: set });
  await refreshPlaceRating(row.place_id);
  return res.json({ success: true });
});

router.delete('/:id', authMiddleware, async (req, res) => {
  const reviewId = req.params.id;
  const userId = req.user.userId;
  const row = await collection('place_reviews').findOne({ id: reviewId }, { projection: { _id: 0 } });
  if (!row) return res.status(404).json({ error: 'Review not found' });
  if (row.user_id !== userId) return res.status(403).json({ error: 'You can only delete your own review' });
  await collection('place_reviews').deleteOne({ id: reviewId });
  await refreshPlaceRating(row.place_id);
  return res.json({ success: true });
});

module.exports = router;
