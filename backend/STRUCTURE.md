# Backend structure

All application and tooling code lives under the `backend/` folder. This document describes the layout and where to add or find things.

## Directory layout

```
backend/
├── config/                 # Runtime config (created at runtime)
│   └── smtp.json           # SMTP settings saved from app (optional; else use .env)
├── scripts/                # One-off and setup scripts
│   ├── setup.js            # npm run setup: .env, migrate, seed
│   ├── check-feed-db.js    # npm run db:check-feed: verify feed tables
│   └── supabase-setup.sql   # Optional: one-shot schema for Supabase SQL Editor
├── src/                    # Application source
│   ├── index.js            # Express entry: security, CORS, listen, graceful shutdown
│   ├── registerRoutes.js  # Mounts all /api/* routers (single overview of API surface)
│   ├── config/             # Config loaders
│   │   ├── loadEnv.js      # Loads backend/.env from any cwd
│   │   ├── validateEnv.js # Production fail-fast (JWT, DATABASE_URL, CORS)
│   │   └── smtpConfig.js   # SMTP from env or config/smtp.json
│   ├── db/                 # Database
│   │   ├── index.js        # Pool and query helper
│   │   ├── schema.sql      # Full schema (run by migrate)
│   │   ├── migrate.js      # npm run db:migrate
│   │   ├── run-migration.js
│   │   ├── seed.js         # npm run db:seed
│   │   ├── seed-trips-from-places.js
│   │   ├── seed-tours-from-places.js
│   │   └── fix-places-images-type.js  # npm run db:fix-images
│   ├── middleware/         # Express middleware
│   │   ├── auth.js         # JWT auth, optionalAuth, requireBusinessOwner
│   │   ├── adminAuth.js    # X-Admin-Key check
│   │   ├── security.js     # blockSuspiciousInput, sanitize, validators
│   │   ├── secureUpload.js # Multer config, file filters, paths
│   │   └── responseCache.js # GET response caching
│   ├── routes/             # API route modules (one per resource)
│   │   ├── admin.js
│   │   ├── auth.js
│   │   ├── business.js
│   │   ├── categories.js
│   │   ├── directions.js   # GET /route (OSRM), GET /google (Google Directions + traffic)
│   │   ├── events.js
│   │   ├── feed.js
│   │   ├── interests.js
│   │   ├── places.js
│   │   ├── profile.js
│   │   ├── tours.js
│   │   ├── trips.js
│   │   └── upload.js
│   ├── services/           # External services
│   │   ├── emailService.js # Password reset, verification emails
│   │   └── smsService.js   # Twilio OTP
│   └── utils/              # Shared utilities
│       ├── AppError.js     # Operational HTTP errors → central error middleware
│       ├── asyncHandler.js # Wrap async route handlers (rejections → next(err))
│       ├── passwordValidator.js
│       └── requestLang.js
├── uploads/                # Uploaded files (created on startup if missing)
├── .env                    # Secrets (not committed; copy from .env.example)
├── .env.example             # Template for .env
├── package.json
├── README.md               # Setup and API overview
├── SECURITY.md             # Security measures
└── STRUCTURE.md            # This file
```

## Conventions

- **Routes:** One file per resource under `src/routes/`. Mounts are centralized in `src/registerRoutes.js` (keep that list in sync when adding a router).
- **Async routes:** Wrap handlers with `utils/asyncHandler.js` so promise rejections reach the error middleware. Use `utils/AppError.js` for expected failures (4xx/5xx with a safe message). See `routes/categories.js`.
- **Config:** Environment in `.env`. Optional runtime file: `config/smtp.json`.
- **DB:** Schema and migrations in `src/db/`. One-off fixes in `src/db/` or `scripts/`.
- **No code outside `backend/`:** All server code and scripts live under this folder.

## NPM scripts

| Script | Purpose |
|--------|---------|
| `npm start` | Production: run API |
| `npm run dev` | Development: run API with --watch |
| `npm run setup` | Create .env, run migrations, seed |
| `npm run db:migrate` | Run schema + migrations |
| `npm run db:seed` | Seed places, categories, etc. |
| `npm run db:seed-trips` | Seed trips from places |
| `npm run db:seed-tours` | Seed tours from places |
| `npm run db:fix-images` | Fix places.images column type (JSONB) |
| `npm run db:check-feed` | Check feed_likes / feed_comments tables |
