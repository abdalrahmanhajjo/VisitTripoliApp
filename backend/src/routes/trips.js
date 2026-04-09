const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { collection } = require('../db');

const router = express.Router();

router.use(authMiddleware);

// GET /api/user/trips
router.get('/trips', async (req, res) => {
  try {
    const userId = req.user.userId;
    const rows = await collection('trips')
      .find({ user_id: userId }, { projection: { _id: 0 } })
      .sort({ start_date: -1 })
      .toArray();
    const trips = rows.map(row => ({
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
    await collection('trips').insertOne({
      id,
      user_id: userId,
      name,
      start_date: startDate,
      end_date: endDate,
      description: description || null,
      days: Array.isArray(days) ? days : JSON.parse(daysJson),
      created_at: new Date(),
      updated_at: new Date(),
    });
    const row = await collection('trips').findOne({ id }, { projection: { _id: 0 } });
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
    const set = { updated_at: new Date() };
    if (name !== undefined) set.name = name;
    if (startDate !== undefined) set.start_date = startDate;
    if (endDate !== undefined) set.end_date = endDate;
    if (description !== undefined) set.description = description;
    if (days !== undefined) set.days = days;
    const result = await collection('trips').findOneAndUpdate(
      { id, user_id: userId },
      { $set: set },
      { returnDocument: 'after', projection: { _id: 0 } }
    );
    if (!result.value) {
      return res.status(404).json({ error: 'Trip not found' });
    }
    const row = result.value;
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
    const result = await collection('trips').deleteOne({ id, user_id: userId });
    if (!result.deletedCount) {
      return res.status(404).json({ error: 'Trip not found' });
    }
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to delete trip' });
  }
});

module.exports = router;
