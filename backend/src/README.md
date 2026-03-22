# Backend `src/` — Role of Each File

Overview of what each file and folder does in the Visit Tripoli API.

---

## Entry point

| File | Role |
|------|------|
| **`index.js`** | Main app entry. Loads `.env`, sets up Express, CORS, Helmet, compression, rate limits, mounts all routes under `/api/*`, serves `/uploads` and `/health`, and starts the server. |

---

## `config/`

| File | Role |
|------|------|
| **`smtpConfig.js`** | SMTP settings for email. Reads from `config/smtp.json` (saved by admin) or from env (`SMTP_HOST`, `SMTP_PORT`, etc.). Used by the auth flow and email service for password reset and verification emails. |

---

## `middleware/`

| File | Role |
|------|------|
| **`auth.js`** | JWT auth: validates `Authorization: Bearer <token>`, sets `req.user`. Also has `requireBusinessOwner` for routes that need a business-owner account. |
| **`adminAuth.js`** | Checks `X-Admin-Key` (or similar) for admin-only routes. |
| **`security.js`** | Request hardening: sanitizes strings, validates UUIDs/place IDs, limits sizes, strips HTML and control chars. Used globally to block suspicious input. |
| **`responseCache.js`** | Optional response caching (e.g. for public GETs) to reduce load. |
| **`secureUpload.js`** | Validates file type/size for uploads and restricts allowed MIME types. |

---

## `routes/`

Each file defines Express routes under a base path (e.g. `/api/auth`, `/api/places`). They handle HTTP, call DB or services, and return JSON.

| File | Base path | Role |
|------|-----------|------|
| **`auth.js`** | `/api/auth` | Login, register, logout, forgot-password, reset-password, email/phone verification, OAuth (Google/Apple). Issues and validates JWTs. |
| **`admin.js`** | `/api/admin` | Admin-only: users, places, feed moderation, SMTP config, etc. |
| **`ai.js`** | `/api/ai` | AI/n8n proxy: `POST /api/ai/complete` forwards the prompt to the n8n webhook (Groq). Returns `{ text }` for the app’s planner chat. `GET /api/ai/status` reports if AI is configured. |
| **`places.js`** | `/api/places` | CRUD for places (POIs). List, get by ID, search, filters. |
| **`categories.js`** | `/api/categories` | List categories used for places/tours. |
| **`tours.js`** | `/api/tours` | Tours (grouped places). List, get by ID. |
| **`events.js`** | `/api/events` | Events (date-bound). List, get by ID. |
| **`interests.js`** | `/api/interests` | User interests (for onboarding and personalization). |
| **`profile.js`** | `/api/user` | Current user profile: get/update profile, avatar, onboarding status. |
| **`trips.js`** | `/api/user` | User trips (saved itineraries): list, create, update, delete. |
| **`trip_shares.js`** | `/api/trip-shares` | Share trip by link; resolve shared trip by token. |
| **`feed.js`** | `/api/feed` | Social feed: posts, create post, like, comment, save, report. |
| **`business.js`** | `/api/business` | Business-owner: manage own places, offers, proposals. |
| **`upload.js`** | `/api/upload` | File uploads (images): auth or admin; writes to `UPLOADS_PATH`, returns URL. |
| **`bookings.js`** | `/api/bookings` | Bookings (e.g. tours/experiences). |
| **`badges.js`** | `/api/badges` | User badges/achievements. |
| **`coupons.js`** | `/api/coupons` | Coupons/discounts. |
| **`offers.js`** | `/api/offers` | Offers and deal proposals (e.g. restaurant responses). |
| **`audio_guides.js`** | `/api/audio-guides` | Audio guide content for places/tours. |

---

## `services/`

| File | Role |
|------|------|
| **`emailService.js`** | Sends emails via SMTP (using `smtpConfig`): password reset codes, verification emails. Falls back to logging in dev if SMTP is not configured. |
| **`smsService.js`** | Sending SMS (e.g. verification codes). Uses provider config from env. |

---

## `lib/`

| File | Role |
|------|------|
| **`supabaseStorage.js`** | Supabase Storage client for uploading/serving files (e.g. feed images) when not using local `uploads/`. |

---

## `utils/`

| File | Role |
|------|------|
| **`requestLang.js`** | Reads preferred language from request (e.g. `Accept-Language` or query) for i18n. |
| **`passwordValidator.js`** | Validates password strength (length, rules) for registration and reset. |

---

## `db/`

Database connection, schema, migrations, seeds, and one-off scripts.

| File | Role |
|------|------|
| **`index.js`** | PostgreSQL connection pool (using `DATABASE_URL`). Exposes `pool` and `query()`. Handles Supabase/SSL. |
| **`schema.sql`** | Base schema: core tables (users, places, categories, etc.) created initially. |
| **`migrate.js`** | Runs `schema.sql` then all migrations in order. Usage: `node src/db/migrate.js`. |
| **`run-migration.js`** | Helper to run a single migration file. |
| **`seed.js`** | Seeds DB with initial data (e.g. categories, sample places) for development. |
| **`seed-trips-from-places.js`** | Builds sample trips from existing places (dev/seed). |
| **`seed-tours-from-places.js`** | Builds sample tours from existing places (dev/seed). |
| **`fix-places-images-type.js`** | One-off script to fix place image column type/data. |
| **`migrations/add_*.sql`** | Each file adds or alters tables/columns (e.g. password reset, feed, coupons, trip shares, OAuth). Applied in the order listed in `migrate.js`. |

---

## Request flow (summary)

1. **`index.js`** — App starts, loads config, applies security middleware and rate limits.
2. **Request** hits a route under `/api/...`.
3. **Middleware** — `security.js` sanitizes input; `auth.js` or `adminAuth.js` when the route is protected.
4. **Route** (e.g. `auth.js`, `places.js`) — Reads body/query, uses `db` and optionally `services` or `lib`.
5. **Response** — JSON back to the client; errors handled by the global error handler in `index.js`.
