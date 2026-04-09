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

// Web parity stubs for collaborative trip sharing workflow.
router.get('/trip-share-requests', async (req, res) => {
  const userId = req.user.userId;
  const incoming = await collection('trip_share_requests')
    .find({ to_user_id: userId }, { projection: { _id: 0 } })
    .sort({ created_at: -1 })
    .toArray();
  const sent = await collection('trip_share_requests')
    .find({ from_user_id: userId }, { projection: { _id: 0 } })
    .sort({ created_at: -1 })
    .toArray();
  res.json({ incoming, sent });
});

router.get('/trip-share-users', async (_req, res) => {
  const users = await collection('users')
    .find({}, { projection: { _id: 0, id: 1, name: 1, email: 1 } })
    .sort({ name: 1 })
    .limit(500)
    .toArray();
  res.json({ users });
});

router.post('/trip-share-requests/:id/respond', async (req, res) => {
  const userId = req.user.userId;
  const id = req.params.id;
  const action = String(req.body?.action || '').toLowerCase();
  if (!['accept', 'reject'].includes(action)) {
    return res.status(400).json({ error: 'action must be accept or reject' });
  }
  const update = await collection('trip_share_requests').updateOne(
    { id, to_user_id: userId, status: 'pending' },
    {
      $set: {
        status: action === 'accept' ? 'accepted' : 'rejected',
        responded_at: new Date(),
        updated_at: new Date(),
      },
    },
  );
  if (!update.matchedCount) return res.status(404).json({ error: 'Request not found' });
  return res.json({ ok: true });
});

module.exports = router;
