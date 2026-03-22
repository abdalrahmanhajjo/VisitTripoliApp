const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { query } = require('../db');

const router = express.Router();

router.use(authMiddleware);

// GET /api/user/trips
router.get('/trips', async (req, res) => {
  try {
    const userId = req.user.userId;
    const result = await query(
      'SELECT id, name, start_date, end_date, description, days, created_at FROM trips WHERE user_id = $1 ORDER BY start_date DESC',
      [userId]
    );
    const trips = result.rows.map(row => ({
      id: row.id,
      name: row.name,
      startDate: row.start_date,
      endDate: row.end_date,
      description: row.description,
      days: Array.isArray(row.days) ? row.days : (row.days ? JSON.parse(row.days) : []),
      createdAt: row.created_at
    }));
    res.json({ trips });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch trips' });
  }
});

// POST /api/user/trips
router.post('/trips', async (req, res) => {
  try {
    const userId = req.user.userId;
    const { name, startDate, endDate, description, days } = req.body;
    if (!name || !startDate || !endDate) {
      return res.status(400).json({ error: 'name, startDate, endDate required' });
    }
    const id = `trip_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
    const daysJson = JSON.stringify(days || []);
    await query(
      'INSERT INTO trips (id, user_id, name, start_date, end_date, description, days) VALUES ($1, $2, $3, $4, $5, $6, $7)',
      [id, userId, name, startDate, endDate, description || null, daysJson]
    );
    const result = await query('SELECT id, name, start_date, end_date, description, days, created_at FROM trips WHERE id = $1', [id]);
    const row = result.rows[0];
    res.status(201).json({
      id: row.id,
      name: row.name,
      startDate: row.start_date,
      endDate: row.end_date,
      description: row.description,
      days: Array.isArray(row.days) ? row.days : JSON.parse(row.days),
      createdAt: row.created_at
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create trip' });
  }
});

// PUT /api/user/trips/:id
router.put('/trips/:id', async (req, res) => {
  try {
    const userId = req.user.userId;
    const { id } = req.params;
    const { name, startDate, endDate, description, days } = req.body;
    const result = await query(
      'UPDATE trips SET name = COALESCE($1, name), start_date = COALESCE($2, start_date), end_date = COALESCE($3, end_date), description = COALESCE($4, description), days = COALESCE($5::jsonb, days) WHERE id = $6 AND user_id = $7 RETURNING *',
      [name, startDate, endDate, description, days ? JSON.stringify(days) : null, id, userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Trip not found' });
    }
    const row = result.rows[0];
    res.json({
      id: row.id,
      name: row.name,
      startDate: row.start_date,
      endDate: row.end_date,
      description: row.description,
      days: Array.isArray(row.days) ? row.days : JSON.parse(row.days),
      createdAt: row.created_at
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to update trip' });
  }
});

// DELETE /api/user/trips/:id
router.delete('/trips/:id', async (req, res) => {
  try {
    const userId = req.user.userId;
    const { id } = req.params;
    const result = await query('DELETE FROM trips WHERE id = $1 AND user_id = $2 RETURNING id', [id, userId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Trip not found' });
    }
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to delete trip' });
  }
});

module.exports = router;
