const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { collection } = require('../db');

const router = express.Router();

router.use(authMiddleware);

function mapTripRow(row, { isHost = false, hostName = null } = {}) {
  return {
    id: row.id,
    name: row.name,
    startDate: row.start_date,
    endDate: row.end_date,
    description: row.description,
    days: Array.isArray(row.days) ? row.days : (row.days ? JSON.parse(row.days) : []),
    createdAt: row.created_at,
    hostUserId: row.user_id || null,
    hostName,
    isHost,
  };
}

// GET /api/user/trips
router.get('/trips', async (req, res) => {
  try {
    const userId = req.user.userId;
    const ownRows = await collection('trips')
      .find({ user_id: userId }, { projection: { _id: 0 } })
      .sort({ start_date: -1 })
      .toArray();

    const collaboratorRows = await collection('trip_collaborators')
      .find({ user_id: userId }, { projection: { _id: 0, trip_id: 1 } })
      .toArray();
    const sharedTripIds = [...new Set(collaboratorRows.map((r) => r.trip_id).filter(Boolean))];
    const sharedRows = sharedTripIds.length
      ? await collection('trips')
          .find(
            { id: { $in: sharedTripIds }, user_id: { $ne: userId } },
            { projection: { _id: 0 } },
          )
          .sort({ start_date: -1 })
          .toArray()
      : [];

    const hostIds = [
      ...new Set([
        ...ownRows.map((r) => r.user_id).filter(Boolean),
        ...sharedRows.map((r) => r.user_id).filter(Boolean),
      ]),
    ];
    const hostNameById = {};
    if (hostIds.length) {
      const users = await collection('users')
        .find(
          { id: { $in: hostIds } },
          { projection: { _id: 0, id: 1, name: 1, email: 1 } },
        )
        .toArray();
      for (const u of users) {
        hostNameById[u.id] = u.name || u.email || null;
      }
    }

    const trips = [
      ...ownRows.map((row) =>
        mapTripRow(row, { isHost: true, hostName: hostNameById[row.user_id] || null }),
      ),
      ...sharedRows.map((row) =>
        mapTripRow(row, { isHost: false, hostName: hostNameById[row.user_id] || null }),
      ),
    ].sort((a, b) => new Date(b.startDate).getTime() - new Date(a.startDate).getTime());

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
    res.status(201).json(mapTripRow(row, { isHost: true }));
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
    const existing = await collection('trips').findOne(
      { id },
      { projection: { _id: 0, id: 1, user_id: 1 } },
    );
    if (!existing) {
      return res.status(404).json({ error: 'Trip not found' });
    }
    if (existing.user_id !== userId) {
      return res.status(403).json({ error: 'Only trip host can edit this trip' });
    }
    const { name, startDate, endDate, description, days } = req.body;
    const set = { updated_at: new Date() };
    if (name !== undefined) set.name = name;
    if (startDate !== undefined) set.start_date = startDate;
    if (endDate !== undefined) set.end_date = endDate;
    if (description !== undefined) set.description = description;
    if (days !== undefined) set.days = days;
    const result = await collection('trips').findOneAndUpdate(
      { id },
      { $set: set },
      { returnDocument: 'after', projection: { _id: 0 } }
    );
    if (!result.value) {
      return res.status(404).json({ error: 'Trip not found' });
    }
    const row = result.value;
    res.json(mapTripRow(row, { isHost: true }));
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
    const existing = await collection('trips').findOne(
      { id },
      { projection: { _id: 0, id: 1, user_id: 1 } },
    );
    if (!existing) {
      return res.status(404).json({ error: 'Trip not found' });
    }
    if (existing.user_id !== userId) {
      return res.status(403).json({ error: 'Only trip host can delete this trip' });
    }
    const result = await collection('trips').deleteOne({ id });
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
router.post('/trip-share-requests', async (req, res) => {
  try {
    const userId = req.user.userId;
    const tripId = (req.body?.tripId || '').toString().trim();
    const toUserId = (req.body?.toUserId || '').toString().trim();
    if (!tripId || !toUserId) {
      return res.status(400).json({ error: 'tripId and toUserId are required' });
    }
    if (toUserId === userId) {
      return res.status(400).json({ error: 'You cannot invite yourself' });
    }

    const trip = await collection('trips').findOne(
      { id: tripId },
      { projection: { _id: 0, id: 1, user_id: 1, name: 1 } },
    );
    if (!trip) return res.status(404).json({ error: 'Trip not found' });
    if (trip.user_id !== userId) {
      return res.status(403).json({ error: 'Only trip host can send invites' });
    }

    const toUser = await collection('users').findOne(
      { id: toUserId },
      { projection: { _id: 0, id: 1, name: 1, email: 1 } },
    );
    if (!toUser) return res.status(404).json({ error: 'Target user not found' });

    const existingCollab = await collection('trip_collaborators').findOne(
      { trip_id: tripId, user_id: toUserId },
      { projection: { _id: 1 } },
    );
    if (existingCollab) {
      return res.status(409).json({ error: 'User already collaborates on this trip' });
    }

    const existingPending = await collection('trip_share_requests').findOne(
      { trip_id: tripId, to_user_id: toUserId, status: 'pending' },
      { projection: { _id: 1 } },
    );
    if (existingPending) {
      return res.status(409).json({ error: 'Invite already pending for this user' });
    }

    const fromUser = await collection('users').findOne(
      { id: userId },
      { projection: { _id: 0, name: 1, email: 1 } },
    );
    const id = `tsr_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
    const now = new Date();
    const requestDoc = {
      id,
      trip_id: tripId,
      trip_name: trip.name,
      from_user_id: userId,
      from_name: fromUser?.name || fromUser?.email || 'Host',
      to_user_id: toUserId,
      to_name: toUser.name || toUser.email || 'Traveler',
      status: 'pending',
      created_at: now,
      updated_at: now,
    };
    await collection('trip_share_requests').insertOne(requestDoc);
    return res.status(201).json({ ok: true, request: requestDoc });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Failed to send invite request' });
  }
});

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

router.get('/trips/:id/members', async (req, res) => {
  try {
    const userId = req.user.userId;
    const tripId = (req.params.id || '').toString().trim();
    if (!tripId) return res.status(400).json({ error: 'Trip id is required' });

    const trip = await collection('trips').findOne(
      { id: tripId },
      { projection: { _id: 0, id: 1, user_id: 1 } },
    );
    if (!trip) return res.status(404).json({ error: 'Trip not found' });

    const isHost = trip.user_id === userId;
    const isCollaborator = !!(await collection('trip_collaborators').findOne(
      { trip_id: tripId, user_id: userId },
      { projection: { _id: 1 } },
    ));
    if (!isHost && !isCollaborator) {
      return res.status(403).json({ error: 'You are not a member of this trip' });
    }

    const collabs = await collection('trip_collaborators')
      .find({ trip_id: tripId }, { projection: { _id: 0, user_id: 1 } })
      .toArray();
    const memberIds = [...new Set([trip.user_id, ...collabs.map((c) => c.user_id).filter(Boolean)])];
    const users = memberIds.length
      ? await collection('users')
          .find(
            { id: { $in: memberIds } },
            { projection: { _id: 0, id: 1, name: 1, email: 1, avatar_url: 1 } },
          )
          .toArray()
      : [];
    const userById = new Map(users.map((u) => [u.id, u]));
    const members = memberIds.map((id) => {
      const u = userById.get(id) || {};
      return {
        userId: id,
        name: u.name || u.email || 'Traveler',
        email: u.email || null,
        avatarUrl: u.avatar_url || null,
        isHost: id === trip.user_id,
      };
    });
    return res.json({ members });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Failed to load trip members' });
  }
});

router.get('/trip-share-requests/:id/trip', async (req, res) => {
  try {
    const userId = req.user.userId;
    const id = (req.params.id || '').toString().trim();
    if (!id) return res.status(400).json({ error: 'Request id is required' });

    const request = await collection('trip_share_requests').findOne(
      {
        id,
        $or: [{ to_user_id: userId }, { from_user_id: userId }],
      },
      { projection: { _id: 0, trip_id: 1 } },
    );
    if (!request) return res.status(404).json({ error: 'Request not found' });

    const trip = await collection('trips').findOne(
      { id: request.trip_id },
      { projection: { _id: 0 } },
    );
    if (!trip) return res.status(404).json({ error: 'Trip not found' });

    const hostUser = await collection('users').findOne(
      { id: trip.user_id },
      { projection: { _id: 0, name: 1, email: 1 } },
    );

    return res.json(
      mapTripRow(trip, {
        isHost: trip.user_id === userId,
        hostName: hostUser?.name || hostUser?.email || null,
      }),
    );
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Failed to fetch invited trip details' });
  }
});

router.post('/trip-share-requests/:id/respond', async (req, res) => {
  const userId = req.user.userId;
  const id = req.params.id;
  const action = String(req.body?.action || '').toLowerCase();
  if (!['accept', 'reject'].includes(action)) {
    return res.status(400).json({ error: 'action must be accept or reject' });
  }
  const request = await collection('trip_share_requests').findOne(
    { id, to_user_id: userId, status: 'pending' },
    { projection: { _id: 0 } },
  );
  if (!request) return res.status(404).json({ error: 'Request not found' });

  const now = new Date();
  await collection('trip_share_requests').updateOne(
    { id: request.id },
    {
      $set: {
        status: action === 'accept' ? 'accepted' : 'rejected',
        responded_at: now,
        updated_at: now,
      },
    },
  );

  if (action === 'accept') {
    await collection('trip_collaborators').updateOne(
      { trip_id: request.trip_id, user_id: userId },
      {
        $set: {
          trip_id: request.trip_id,
          user_id: userId,
          invited_by_user_id: request.from_user_id,
          updated_at: now,
        },
        $setOnInsert: { created_at: now },
      },
      { upsert: true },
    );
  }
  return res.json({ ok: true });
});

module.exports = router;
