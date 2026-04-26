const express = require('express');
const { collection } = require('../db');
const { getRequestLang } = require('../utils/requestLang');
const { isValidPlaceId, isValidUUID } = require('../middleware/security');
const { loadTranslationMap, withTranslation } = require('../utils/mongoTranslations');

const router = express.Router();

// GET /api/audio-guides - List by place or tour
router.get('/', async (req, res) => {
  try {
    const lang = getRequestLang(req);
    const { placeId, tourId } = req.query;
    if (!placeId && !tourId) return res.status(400).json({ error: 'placeId or tourId required' });
    if (placeId && !isValidPlaceId(String(placeId))) {
      return res.status(400).json({ error: 'Invalid placeId' });
    }
    if (tourId && !isValidPlaceId(String(tourId))) {
      return res.status(400).json({ error: 'Invalid tourId' });
    }

    const filter = {};
    if (placeId) {
      filter.place_id = String(placeId);
    } else {
      filter.tour_id = String(tourId);
    }
    const guides = await collection('audio_guides')
      .find(filter, { projection: { _id: 0 } })
      .sort({ language: 1 })
      .toArray();
    const ids = guides.map((g) => g.id).filter(Boolean);
    const trMap = await loadTranslationMap(collection('audio_guide_translations'), 'audio_guide_id', ids, lang);
    const audioGuides = guides.map((g) => withTranslation(g, trMap.get(g.id), ['title']));
    res.json({ audioGuides });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch audio guides' });
  }
});

// GET /api/audio-guides/:id - Single audio guide
router.get('/:id', async (req, res) => {
  try {
    if (!isValidUUID(req.params.id)) {
      return res.status(400).json({ error: 'Invalid id' });
    }
    const lang = getRequestLang(req);
    const rowBase = await collection('audio_guides').findOne(
      { id: req.params.id },
      { projection: { _id: 0 } }
    );
    const tr = lang && lang !== 'en'
      ? await collection('audio_guide_translations').findOne(
          { audio_guide_id: req.params.id, lang },
          { projection: { _id: 0 } }
        )
      : null;
    const row = rowBase ? withTranslation(rowBase, tr, ['title'], lang) : null;
    if (!row) return res.status(404).json({ error: 'Not found' });
    res.json(row);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch audio guide' });
  }
});

module.exports = router;
