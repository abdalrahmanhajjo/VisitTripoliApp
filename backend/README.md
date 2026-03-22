# Visit Tripoli — Backend API

Node.js (Express) + PostgreSQL API for the Visit Tripoli Flutter app. All code and scripts live under this folder.

- **Structure:** See [STRUCTURE.md](STRUCTURE.md) for directory layout and conventions.
- **Security:** See [SECURITY.md](SECURITY.md) for rate limits, JWT, and CORS.

## Setup

### 1. Install dependencies

```bash
cd backend
npm install
```

### 2. Create PostgreSQL database (or use Supabase)

**Option A – Local Postgres**

```bash
createdb tripoli_explorer
```

**Option B – Supabase**

1. Create a project at [supabase.com](https://supabase.com) → New project.
2. Open **Project Settings → Database**.
3. Under **Connection string**, choose **URI** and copy the URL. Use the **Session** pooler (port 5432) for this Node server.
4. Replace `[YOUR-PASSWORD]` with your database password. Put the result in `.env` as `DATABASE_URL`. SSL is enabled automatically when the URL contains `supabase`.

### 3. Configure environment

```bash
cp .env.example .env
```

Edit `.env`:

```
PORT=3000
DATABASE_URL=postgresql://user:password@localhost:5432/tripoli_explorer
JWT_SECRET=your-secret-key-min-32-chars-for-production
NODE_ENV=development
```

### 4. Run schema (create all tables)

```bash
npm run db:migrate
```

**If Node cannot connect** (e.g. local firewall), run the schema in Supabase manually:
1. Supabase project → **SQL Editor**
2. Paste the contents of `src/db/schema.sql` and run (or use optional one-shot `scripts/supabase-setup.sql`)

**For existing databases** (run migrations in order):
```bash
psql $DATABASE_URL -f src/db/migrations/add_onboarding_completed.sql
psql $DATABASE_URL -f src/db/migrations/add_password_reset_tokens.sql
psql $DATABASE_URL -f src/db/migrations/add_email_phone_verification.sql
```

Or without psql: `npm run db:migrate:reset-tokens` then `npm run db:migrate:verification`

### 5. (Optional) Seed sample data

```bash
npm run db:seed
```

### 6. Start server

```bash
npm run dev    # development with auto-reload
npm start      # production
```

API runs at `http://localhost:3000`. The `uploads/` directory is created automatically if missing.

**Useful scripts:** `npm run setup` (env + migrate + seed) · `npm run db:check-feed` (verify feed tables) · `npm run db:fix-images` (fix places.images type)

## Flutter app connection

In the Flutter project, set the API base URL:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Or for Android emulator (use `10.0.2.2` instead of `localhost`):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

## API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/health`, `/health/email` | No | Health check |
| POST | `/api/auth/register`, `/api/auth/login` | No | Register, login |
| POST | `/api/auth/forgot-password`, `/api/auth/reset-password` | No | Password reset |
| POST | `/api/auth/verify-email`, `/api/auth/request-verification-email` | No | Email verification |
| POST | `/api/auth/request-phone-otp`, `/api/auth/register-phone`, `/api/auth/login-phone` | No | Phone OTP / register / login |
| GET | `/api/places`, `/api/places/:id` | No | List places, get place |
| GET | `/api/categories` | No | List categories |
| GET | `/api/tours`, `/api/tours/:id` | No | List tours, get tour |
| GET | `/api/events`, `/api/events/:id` | No | List events, get event |
| GET | `/api/interests` | No | List interests |
| GET/PUT | `/api/user/profile` | Yes | Get / update profile |
| GET/POST/PUT/DELETE | `/api/user/trips`, `/api/user/trips/:id` | Yes | Trips CRUD |
| GET/POST | `/api/feed`, `/api/feed/can-post` | Optional / Yes | Feed list, post permission |
| POST/PUT/DELETE | `/api/feed/:id`, like, save, comments | Yes | Feed post, like, save, comments |
| GET/POST | `/api/business/feed`, place posts | Yes (business) | Business feed |
| POST | `/api/upload/*` | Yes (admin) | Admin uploads |
| * | `/api/admin/*` | Admin key | Admin CRUD (places, tours, events, etc.) |

Protected routes use `Authorization: Bearer <token>`. Admin routes use `X-Admin-Key` header. Uploads served at `/uploads`.
