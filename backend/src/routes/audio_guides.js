const express = require('express');
const { query } = require('../db');

const router = express.Router();

// GET /api/audio-guides - List by place or tour
router.get('/', async (req, res) => {
  try {
    const { placeId, tourId } = req.query;
    if (!placeId && !tourId) return res.status(400).json({ error: 'placeId or tourId required' });

    let result;
    if (placeId) {
      result = await query(
        `SELECT id, place_id, tour_id, language, audio_url, duration_seconds, title
         FROM audio_guides
         WHERE place_id = $1
         ORDER BY language`,
        [placeId]
      );
    } else {
      result = await query(
        `SELECT id, place_id, tour_id, language, audio_url, duration_seconds, title
         FROM audio_guides
         WHERE tour_id = $1
         ORDER BY language`,
        [tourId]
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
    const result = await query(
      `SELECT id, place_id, tour_id, language, audio_url, duration_seconds, title
       FROM audio_guides WHERE id = $1`,
      [req.params.id]
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
