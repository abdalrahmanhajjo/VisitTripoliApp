const express = require('express');
const { collection } = require('../db');
const { responseCache } = require('../middleware/responseCache');
const { getRequestLang } = require('../utils/requestLang');
const { loadTranslationMap, withTranslation } = require('../utils/mongoTranslations');

const router = express.Router();

function rowToEvent(row) {
  return {
    id: row.id,
    name: row.name,
    description: row.description,
    startDate: row.start_date instanceof Date ? row.start_date.toISOString() : row.start_date,
    endDate: row.end_date instanceof Date ? row.end_date.toISOString() : row.end_date,
    location: row.location,
    image: row.image,
    category: row.category,
    organizer: row.organizer,
    price: row.price,
    priceDisplay: row.price_display,
    status: row.status,
    placeId: row.place_id
  };
}

// GET /api/events (translations from DB when lang=ar|fr)
router.get('/', responseCache(2 * 60 * 1000), async (req, res) => {
  try {
    const lang = getRequestLang(req);
    const eventsRaw = await collection('events')
      .find({}, { projection: { _id: 0 } })
      .sort({ start_date: -1 })
      .toArray();
    const ids = eventsRaw.map((e) => e.id).filter(Boolean);
    const trMap = await loadTranslationMap(collection('event_translations'), 'event_id', ids, lang);
    const events = eventsRaw.map((e) =>
      rowToEvent(
        withTranslation(e, trMap.get(e.id), [
          'name',
          'description',
          'location',
          'category',
          'organizer',
          'price_display',
          'status',
        ])
      )
    );
    res.json({ events });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      error: 'Failed to fetch events',
      detail: process.env.NODE_ENV !== 'production' ? err.message : undefined,
    });
  }
});

// GET /api/events/:id
router.get('/:id', async (req, res) => {
  try {
    const lang = getRequestLang(req);
    const base = await collection('events').findOne(
      { id: req.params.id },
      { projection: { _id: 0 } }
    );
    if (!base) {
      return res.status(404).json({ error: 'Event not found' });
    }
    const tr = lang && lang !== 'en'
      ? await collection('event_translations').findOne(
          { event_id: req.params.id, lang },
          { projection: { _id: 0 } }
        )
      : null;
    const row = withTranslation(base, tr, [
      'name',
      'description',
      'location',
      'category',
      'organizer',
      'price_display',
      'status',
    ], lang);
    res.json(rowToEvent(row));
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch event' });
  }
});

module.exports = router;
