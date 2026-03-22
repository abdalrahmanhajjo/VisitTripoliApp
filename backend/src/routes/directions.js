/**
 * Proxies routing for the Flutter app:
 * - GET /route — OSRM (no traffic; fallback)
 * - GET /google — Google Directions (traffic-aware driving; matches Google Maps when key is set)
 */
const express = require('express');

const router = express.Router();

const DEFAULT_OSRM = 'https://router.project-osrm.org/route/v1';

const GOOGLE_DIRECTIONS =
  'https://maps.googleapis.com/maps/api/directions/json';

function googleMapsKey() {
  return (
    process.env.GOOGLE_MAPS_DIRECTIONS_KEY ||
    process.env.GOOGLE_MAPS_API_KEY ||
    ''
  ).trim();
}

/** "lat,lng" */
function parseLatLngPair(s) {
  if (typeof s !== 'string') return null;
  const m = s.trim().match(/^(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)$/);
  if (!m) return null;
  const lat = parseFloat(m[1]);
  const lng = parseFloat(m[2]);
  if (Number.isNaN(lat) || Number.isNaN(lng)) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return { lat, lng };
}

/** Optional middle stops: "lat,lng|lat,lng" */
function safeWaypoints(raw) {
  if (raw == null || raw === '') return '';
  const parts = String(raw).split('|').map((p) => p.trim()).filter(Boolean);
  if (parts.length > 23) return null;
  for (const p of parts) {
    if (!parseLatLngPair(p)) return null;
  }
  return parts.join('|');
}

function allowedProfile(p) {
  const s = String(p || '').toLowerCase();
  if (s === 'walking' || s === 'foot') return 'foot';
  if (s === 'driving' || s === 'car') return 'driving';
  if (s === 'bike' || s === 'cycling') return 'bike';
  return null;
}

/** lon,lat;lon,lat — strict character set, length cap */
function safeCoords(coords) {
  if (typeof coords !== 'string') return null;
  const c = coords.trim();
  if (c.length < 5 || c.length > 8192) return null;
  if (!/^[\d.,;\-\s]+$/.test(c)) return null;
  return c;
}

router.get('/route', async (req, res, next) => {
  try {
    const profile = allowedProfile(req.query.profile);
    const coords = safeCoords(req.query.coords);
    if (!profile || !coords) {
      return res.status(400).json({ error: 'Invalid or missing profile or coords' });
    }

    const overview = req.query.overview === 'simplified' ? 'simplified' : 'full';
    const continueStraight =
      req.query.continue_straight === 'true' || req.query.continue_straight === '1'
        ? 'true'
        : 'false';

    const base = (process.env.OSRM_BASE_URL || DEFAULT_OSRM).replace(/\/+$/, '');
    const url = `${base}/${profile}/${coords}?overview=${overview}&geometries=geojson&steps=true&continue_straight=${continueStraight}`;

    const ac = new AbortController();
    const t = setTimeout(() => ac.abort(), 10000);
    let r;
    try {
      r = await fetch(url, { redirect: 'follow', signal: ac.signal });
    } finally {
      clearTimeout(t);
    }

    const text = await r.text();
    res.status(r.status).type('application/json').send(text);
  } catch (err) {
    next(err);
  }
});

/**
 * Google Directions API — same routing engine as Google Maps (with live traffic for driving).
 * Requires GOOGLE_MAPS_API_KEY (or GOOGLE_MAPS_DIRECTIONS_KEY) with Directions API enabled.
 *
 * Query: origin=lat,lng&destination=lat,lng&mode=driving|walking
 * Optional: waypoints=lat,lng|lat,lng (via points between origin and destination)
 */
router.get('/google', async (req, res, next) => {
  try {
    const key = googleMapsKey();
    if (!key) {
      return res.status(503).json({
        error: 'Google Directions not configured',
        code: 'GOOGLE_DIRECTIONS_DISABLED',
      });
    }

    const origin = parseLatLngPair(req.query.origin);
    const destination = parseLatLngPair(req.query.destination);
    if (!origin || !destination) {
      return res.status(400).json({ error: 'Invalid origin or destination (use lat,lng)' });
    }

    const modeRaw = String(req.query.mode || 'driving').toLowerCase();
    const mode = modeRaw === 'walking' ? 'walking' : 'driving';

    const wp = safeWaypoints(req.query.waypoints);
    if (wp === null) {
      return res.status(400).json({ error: 'Invalid waypoints' });
    }

    const params = new URLSearchParams({
      origin: `${origin.lat},${origin.lng}`,
      destination: `${destination.lat},${destination.lng}`,
      mode,
      key,
      alternatives: 'false',
      units: 'metric',
      // Same region bias as google.com/maps for Libya (ccTLD).
      region: 'ly',
    });
    if (wp) {
      // Critical: without optimize:false, Google may reorder stops — different path than Maps “in order”.
      params.set('waypoints', `optimize:false|${wp}`);
    }

    // Traffic-aware duration (closest to Google Maps). Walking ignores these.
    if (mode === 'driving') {
      params.set('departure_time', String(Math.floor(Date.now() / 1000)));
      params.set('traffic_model', 'best_guess');
    }

    const url = `${GOOGLE_DIRECTIONS}?${params.toString()}`;

    const ac = new AbortController();
    const t = setTimeout(() => ac.abort(), 15000);
    let r;
    try {
      r = await fetch(url, { redirect: 'follow', signal: ac.signal });
    } finally {
      clearTimeout(t);
    }

    const text = await r.text();
    res.status(r.status).type('application/json').send(text);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
