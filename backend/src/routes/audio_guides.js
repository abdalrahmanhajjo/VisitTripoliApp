const express = require('express');
const { query } = require('../db');
const { getRequestLang } = require('../utils/requestLang');
const { isValidPlaceId, isValidUUID } = require('../middleware/security');

const router = express.Router();

const SELECT_GUIDES = `
  SELECT ag.id, ag.place_id, ag.tour_id, ag.language, ag.audio_url, ag.duration_seconds,
         COALESCE(agt.title, ag.title) AS title
  FROM audio_guides ag
  LEFT JOIN audio_guide_translations agt ON agt.audio_guide_id = ag.id AND agt.lang = $1
`;

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

    let result;
    if (placeId) {
      result = await query(
        `${SELECT_GUIDES}
         WHERE ag.place_id = $2
         ORDER BY ag.language`,
        [lang, placeId]
      );
    } else {
      result = await query(
        `${SELECT_GUIDES}
         WHERE ag.tour_id = $2
         ORDER BY ag.language`,
        [lang, tourId]
      );
    }

    res.json({ audioGuides: result.rows });
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
    const result = await query(
      `${SELECT_GUIDES}
       WHERE ag.id = $2`,
      [lang, req.params.id]
    );
    const row = result.rows[0];
    if (!row) return res.status(404).json({ error: 'Not found' });
    res.json(row);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch audio guide' });
  }
});

module.exports = router;
