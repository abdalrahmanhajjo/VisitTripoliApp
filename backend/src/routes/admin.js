const express = require('express');
const { query } = require('../db');
const adminAuth = require('../middleware/adminAuth');

const router = express.Router();
router.use(adminAuth);

// --- Categories ---
router.get('/categories', async (req, res) => {
  try {
    const r = await query('SELECT * FROM categories ORDER BY name');
    res.json(r.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/categories', async (req, res) => {
  try {
    const { id, name, icon, description, tags, count, color } = req.body;
    await query(
      `INSERT INTO categories (id, name, icon, description, tags, count, color) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [id, name || '', icon || 'landmark', description || '', JSON.stringify(tags || []), count ?? 0, color || '#666']
    );
    res.status(201).json({ id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.put('/categories/:id', async (req, res) => {
  try {
    const { name, icon, description, tags, count, color } = req.body;
    await query(
      `UPDATE categories SET name=$1, icon=$2, description=$3, tags=$4, count=$5, color=$6 WHERE id=$7`,
      [name || '', icon || '', description || '', JSON.stringify(tags || []), count ?? 0, color || '', req.params.id]
    );
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.delete('/categories/:id', async (req, res) => {
  try {
    await query('DELETE FROM categories WHERE id=$1', [req.params.id]);
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// --- Places ---
router.get('/places', async (req, res) => {
  try {
    const r = await query('SELECT * FROM places ORDER BY name');
    res.json(r.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/places', async (req, res) => {
  try {
    const p = req.body;
    const images = Array.isArray(p.images) ? p.images : (p.image ? [p.image] : []);
    await query(
      `INSERT INTO places (id, name, description, location, latitude, longitude, images, category, category_id, duration, price, best_time, rating, review_count, tags) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)`,
      [
        p.id, p.name || '', p.description || '', p.location || '',
        p.latitude ?? p.coordinates?.lat ?? null, p.longitude ?? p.coordinates?.lng ?? null,
        JSON.stringify(images), p.category || '', p.categoryId || p.category_id || '',
        p.duration || '', String(p.price ?? ''), p.bestTime || p.best_time || '',
        p.rating ?? null, p.reviewCount ?? p.review_count ?? null, JSON.stringify(p.tags || [])
      ]
    );
    res.status(201).json({ id: p.id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.put('/places/:id', async (req, res) => {
  try {
    const p = req.body;
    const id = req.params.id;
    const images = Array.isArray(p.images) ? p.images : (p.image ? [p.image] : null);
    const lat = p.latitude ?? p.coordinates?.lat;
    const lng = p.longitude ?? p.coordinates?.lng;
    if (images !== null) {
      await query(
        `UPDATE places SET name=$1, description=$2, location=$3, latitude=$4, longitude=$5, images=$6, category=$7, category_id=$8, duration=$9, price=$10, best_time=$11, rating=$12, review_count=$13, tags=$14 WHERE id=$15`,
        [p.name || '', p.description || '', p.location || '', lat ?? null, lng ?? null, JSON.stringify(images),
         p.category || '', p.categoryId || p.category_id || '', p.duration || '', String(p.price ?? ''),
         p.bestTime || p.best_time || '', p.rating ?? null, p.reviewCount ?? p.review_count ?? null,
         JSON.stringify(p.tags || []), id]
      );
    } else {
      await query(
        `UPDATE places SET name=$1, description=$2, location=$3, latitude=$4, longitude=$5, category=$6, category_id=$7, duration=$8, price=$9, best_time=$10, rating=$11, review_count=$12, tags=$13 WHERE id=$14`,
        [p.name || '', p.description || '', p.location || '', lat ?? null, lng ?? null,
         p.category || '', p.categoryId || p.category_id || '', p.duration || '', String(p.price ?? ''),
         p.bestTime || p.best_time || '', p.rating ?? null, p.reviewCount ?? p.review_count ?? null,
         JSON.stringify(p.tags || []), id]
      );
    }
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.delete('/places/:id', async (req, res) => {
  try {
    await query('DELETE FROM places WHERE id=$1', [req.params.id]);
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// --- Tours ---
router.get('/tours', async (req, res) => {
  try {
    const r = await query('SELECT * FROM tours ORDER BY name');
    res.json(r.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/tours', async (req, res) => {
  try {
    const t = req.body;
    await query(
      `INSERT INTO tours (id, name, duration, duration_hours, locations, rating, reviews, price, currency, price_display, badge, badge_color, description, image, difficulty, languages, includes, excludes, highlights, itinerary, place_ids) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)`,
      [t.id, t.name || '', t.duration || '', t.durationHours ?? t.duration_hours ?? 0, t.locations ?? 0,
       t.rating ?? 0, t.reviews ?? 0, t.price ?? 0, t.currency || 'USD', t.priceDisplay || t.price_display || '',
       t.badge || null, t.badgeColor || t.badge_color || null, t.description || '', t.image || '',
       t.difficulty || 'moderate', JSON.stringify(t.languages || []), JSON.stringify(t.includes || []),
       JSON.stringify(t.excludes || []), JSON.stringify(t.highlights || []), JSON.stringify(t.itinerary || []),
       JSON.stringify(t.placeIds || t.place_ids || [])]
    );
    res.status(201).json({ id: t.id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.put('/tours/:id', async (req, res) => {
  try {
    const t = req.body;
    const id = req.params.id;
    await query(
      `UPDATE tours SET name=$1, duration=$2, duration_hours=$3, locations=$4, rating=$5, reviews=$6, price=$7, currency=$8, price_display=$9, badge=$10, badge_color=$11, description=$12, image=$13, difficulty=$14, languages=$15, includes=$16, excludes=$17, highlights=$18, itinerary=$19, place_ids=$20 WHERE id=$21`,
      [t.name || '', t.duration || '', t.durationHours ?? t.duration_hours ?? 0, t.locations ?? 0, t.rating ?? 0,
       t.reviews ?? 0, t.price ?? 0, t.currency || 'USD', t.priceDisplay || t.price_display || '',
       t.badge || null, t.badgeColor || t.badge_color || null, t.description || '', t.image || '',
       t.difficulty || 'moderate', JSON.stringify(t.languages || []), JSON.stringify(t.includes || []),
       JSON.stringify(t.excludes || []), JSON.stringify(t.highlights || []), JSON.stringify(t.itinerary || []),
       JSON.stringify(t.placeIds || t.place_ids || []), id]
    );
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.delete('/tours/:id', async (req, res) => {
  try {
    await query('DELETE FROM tours WHERE id=$1', [req.params.id]);
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// --- Events ---
router.get('/events', async (req, res) => {
  try {
    const r = await query('SELECT * FROM events ORDER BY start_date DESC');
    res.json(r.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/events', async (req, res) => {
  try {
    const e = req.body;
    const start = e.startDate || e.start_date;
    const end = e.endDate || e.end_date;
    await query(
      `INSERT INTO events (id, name, description, start_date, end_date, location, image, category, organizer, price, price_display, status, place_id) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)`,
      [e.id, e.name || '', e.description || '', start, end, e.location || '', e.image || '',
       e.category || '', e.organizer || '', e.price ?? null, e.priceDisplay || e.price_display || '',
       e.status || 'active', e.placeId || e.place_id || null]
    );
    res.status(201).json({ id: e.id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.put('/events/:id', async (req, res) => {
  try {
    const e = req.body;
    const id = req.params.id;
    const start = e.startDate || e.start_date;
    const end = e.endDate || e.end_date;
    await query(
      `UPDATE events SET name=$1, description=$2, start_date=$3, end_date=$4, location=$5, image=$6, category=$7, organizer=$8, price=$9, price_display=$10, status=$11, place_id=$12 WHERE id=$13`,
      [e.name || '', e.description || '', start, end, e.location || '', e.image || '',
       e.category || '', e.organizer || '', e.price ?? null, e.priceDisplay || e.price_display || '',
       e.status || 'active', e.placeId || e.place_id || null, id]
    );
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.delete('/events/:id', async (req, res) => {
  try {
    await query('DELETE FROM events WHERE id=$1', [req.params.id]);
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// --- Interests ---
router.get('/interests', async (req, res) => {
  try {
    const r = await query('SELECT * FROM interests ORDER BY popularity DESC');
    res.json(r.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/interests', async (req, res) => {
  try {
    const i = req.body;
    await query(
      `INSERT INTO interests (id, name, icon, description, color, count, popularity, tags) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [i.id, i.name || '', i.icon || 'star', i.description || '', i.color || '#666', i.count ?? 0, i.popularity ?? 0, JSON.stringify(i.tags || [])]
    );
    res.status(201).json({ id: i.id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.put('/interests/:id', async (req, res) => {
  try {
    const i = req.body;
    await query(
      `UPDATE interests SET name=$1, icon=$2, description=$3, color=$4, count=$5, popularity=$6, tags=$7 WHERE id=$8`,
      [i.name || '', i.icon || '', i.description || '', i.color || '', i.count ?? 0, i.popularity ?? 0, JSON.stringify(i.tags || []), req.params.id]
    );
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.delete('/interests/:id', async (req, res) => {
  try {
    await query('DELETE FROM interests WHERE id=$1', [req.params.id]);
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// --- Users (app users management for web dashboard) ---
router.get('/users', async (req, res) => {
  try {
    const r = await query(
      'SELECT id, email, name, created_at, is_admin, is_business_owner FROM users ORDER BY created_at DESC'
    );
    res.json(r.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.put('/users/:id', async (req, res) => {
  try {
    const { isAdmin } = req.body || {};
    await query(
      'UPDATE users SET is_admin = $1 WHERE id = $2',
      [isAdmin === true, req.params.id]
    );
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/users', async (req, res) => {
  try {
    const bcrypt = require('bcryptjs');
    const { validatePassword } = require('../utils/passwordValidator');
    const { name, email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }
    const pv = validatePassword(password);
    if (!pv.valid) {
      return res.status(400).json({ error: pv.error });
    }
    const hash = await bcrypt.hash(password, 12);
    const result = await query(
      'INSERT INTO users (email, password_hash, name) VALUES ($1, $2, $3) RETURNING id, email, name, created_at',
      [email, hash, name || null]
    );
    const user = result.rows[0];
    res.status(201).json({
      id: user.id,
      email: user.email,
      name: user.name || email.split('@')[0],
      created_at: user.created_at
    });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(400).json({ error: 'Email already registered' });
    }
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.delete('/users/:id', async (req, res) => {
  try {
    await query('DELETE FROM users WHERE id = $1', [req.params.id]);
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// --- Place owners (for feed: business owners who can post) ---
router.get('/place-owners', async (req, res) => {
  try {
    const r = await query(
      'SELECT po.user_id, po.place_id, p.name AS place_name, u.email FROM place_owners po JOIN places p ON p.id = po.place_id JOIN users u ON u.id = po.user_id ORDER BY p.name'
    );
    res.json(r.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.post('/place-owners', async (req, res) => {
  try {
    const { userId, placeId } = req.body || {};
    if (!userId || !placeId) {
      return res.status(400).json({ error: 'userId and placeId required' });
    }
    await query(
      'INSERT INTO place_owners (user_id, place_id) VALUES ($1, $2) ON CONFLICT (user_id, place_id) DO NOTHING',
      [userId, placeId]
    );
    await query('UPDATE users SET is_business_owner = true WHERE id = $1', [userId]);
    res.status(201).json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.delete('/place-owners/:userId/:placeId', async (req, res) => {
  try {
    await query(
      'DELETE FROM place_owners WHERE user_id = $1 AND place_id = $2',
      [req.params.userId, req.params.placeId]
    );
    const remain = await query('SELECT 1 FROM place_owners WHERE user_id = $1', [req.params.userId]);
    if (remain.rows.length === 0) {
      await query('UPDATE users SET is_business_owner = false WHERE id = $1', [req.params.userId]);
    }
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// --- Stats (for dashboard home) ---
router.get('/stats', async (req, res) => {
  try {
    const [places, categories, tours, events, interests] = await Promise.all([
      query('SELECT COUNT(*)::int FROM places'),
      query('SELECT COUNT(*)::int FROM categories'),
      query('SELECT COUNT(*)::int FROM tours'),
      query('SELECT COUNT(*)::int FROM events'),
      query('SELECT COUNT(*)::int FROM interests')
    ]);
    res.json({
      places: places.rows[0].count,
      categories: categories.rows[0].count,
      tours: tours.rows[0].count,
      events: events.rows[0].count,
      interests: interests.rows[0].count
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// --- Login (validate admin key) ---
router.post('/login', (req, res) => {
  const secret = process.env.ADMIN_SECRET;
  const { key } = req.body || {};
  if (!secret) {
    return res.json({ success: true, message: 'No admin secret set (dev mode)' });
  }
  if (key === secret) {
    return res.json({ success: true });
  }
  res.status(401).json({ success: false, error: 'Invalid admin key' });
});

module.exports = router;
