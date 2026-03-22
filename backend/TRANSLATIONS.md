# Database translations (no API)

Content is translated **once** and stored in the database. The API returns the right language using `?lang=ar` or `Accept-Language: ar` (same for `fr`). No external translation API is used.

## 1. Run the migration

```bash
cd backend
node src/db/migrate.js
```

This creates: `place_translations`, `category_translations`, `event_translations`, `tour_translations`, `interest_translations`.

## 2. Fill translations

Add one row per entity per language. Use `lang = 'ar'` for Arabic and `lang = 'fr'` for French. Source (English) stays in the main tables (`places`, `categories`, etc.).

### Places

```sql
INSERT INTO place_translations (place_id, lang, name, description, location, category, duration, price, best_time, tags)
VALUES (
  'your_place_id',
  'ar',
  'الاسم بالعربية',
  'الوصف بالعربية',
  'الموقع',
  'الفئة',
  'المدة',
  'السعر',
  'أفضل وقت',
  '["وسم1","وسم2"]'::jsonb
)
ON CONFLICT (place_id, lang) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  location = EXCLUDED.location,
  category = EXCLUDED.category,
  duration = EXCLUDED.duration,
  price = EXCLUDED.price,
  best_time = EXCLUDED.best_time,
  tags = EXCLUDED.tags;
```

### Categories

```sql
INSERT INTO category_translations (category_id, lang, name, description, tags)
VALUES ('cultural', 'ar', 'ثقافي', 'وصف الفئة', '[]'::jsonb)
ON CONFLICT (category_id, lang) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, tags = EXCLUDED.tags;
```

### Events

```sql
INSERT INTO event_translations (event_id, lang, name, description, location, category, organizer, price_display, status)
VALUES ('event_id', 'ar', 'اسم الحدث', 'الوصف', 'الموقع', 'الفئة', 'المنظم', 'السعر', 'الحالة')
ON CONFLICT (event_id, lang) DO UPDATE SET
  name = EXCLUDED.name, description = EXCLUDED.description, location = EXCLUDED.location,
  category = EXCLUDED.category, organizer = EXCLUDED.organizer, price_display = EXCLUDED.price_display, status = EXCLUDED.status;
```

### Tours

```sql
INSERT INTO tour_translations (tour_id, lang, name, description, difficulty, badge, duration, price_display, includes, excludes, highlights, itinerary)
VALUES (
  'tour_id',
  'ar',
  'اسم الجولة',
  'الوصف',
  'الصعوبة',
  'الشارة',
  'المدة',
  'السعر',
  '[]'::jsonb,
  '[]'::jsonb,
  '[]'::jsonb,
  '[]'::jsonb
)
ON CONFLICT (tour_id, lang) DO UPDATE SET
  name = EXCLUDED.name, description = EXCLUDED.description, difficulty = EXCLUDED.difficulty,
  badge = EXCLUDED.badge, duration = EXCLUDED.duration, price_display = EXCLUDED.price_display,
  includes = EXCLUDED.includes, excludes = EXCLUDED.excludes, highlights = EXCLUDED.highlights, itinerary = EXCLUDED.itinerary;
```

`itinerary` is a JSON array of `{ "time": "...", "activity": "...", "description": "..." }` — translate `activity` and `description` in each item and store the full JSON.

### Interests

```sql
INSERT INTO interest_translations (interest_id, lang, name, description, tags)
VALUES ('history', 'ar', 'تاريخ', 'الوصف', '[]'::jsonb)
ON CONFLICT (interest_id, lang) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, tags = EXCLUDED.tags;
```

## 3. How the API uses it

- `GET /api/places?lang=ar` (or `Accept-Language: ar`) returns places with Arabic from `place_translations` when present; otherwise the main table (English) is used.
- Same for `/api/categories`, `/api/events`, `/api/tours`, `/api/interests` and their `/:id` endpoints.

You can translate in a spreadsheet, then run INSERTs, or build a small admin screen to edit these tables.
