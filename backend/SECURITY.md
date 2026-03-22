# Security Measures

This backend is hardened for extreme security. Below is a summary of implemented measures.

## Authentication & Authorization

- **JWT**: HS256 only, max token length 1024, 3-day expiry (production) / 7-day (dev)
- **JWT_SECRET**: In production must be set and 32+ characters; server exits on startup if missing/weak
- **Admin routes**: Require `X-Admin-Key` header matching `ADMIN_SECRET`
- **Production**: `ADMIN_SECRET` is required; admin access fails if not set
- **Clock tolerance**: 0 to prevent token replay

## Rate Limiting

| Route | Limit (prod) |
|-------|----------------|
| `/api/*` | 60 req/min per IP |
| `/api/auth/login` | 15 req / 15 min |
| `/api/auth/register` | 15 req / 15 min |
| `/api/auth/forgot-password` | 5 req / hour |
| `/api/admin/*` | 30 req/min |
| `/api/upload/*` | 20 req/min |

## Headers (Helmet)

- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Cross-Origin-Resource-Policy: same-site`
- `Strict-Transport-Security` (production only, with preload)
- `X-Powered-By` disabled
- `trust proxy: 1` for correct client IP in rate limiting

## CORS

- Production: **Required** – server exits on startup if `CORS_ORIGIN` is not set
- Development: Allows all origins
- Methods: GET, POST, PUT, DELETE, PATCH
- Allowed headers: Content-Type, Authorization, X-Admin-Key
- Options: 204

## Input Validation

- **XSS/Path traversal/null bytes**: Requests with `<script`, `javascript:`, `vbscript:`, `data:`, `onerror=`, `onload=`, `<iframe`, `../`, `\0`, and similar patterns in body, query, or Authorization header are rejected
- **Place IDs**: Alphanumeric, underscore, hyphen, max 50 chars
- **UUIDs**: Valid UUID format for user/entity IDs
- **Feed captions**: Sanitized, max 2000 chars
- **Author names**: Sanitized, max 255 chars

## File Uploads

- **MIME whitelist**: JPEG, PNG, GIF, WebP (images); MP4, WebM (video)
- **Size**: 10MB images, 20MB video
- **Filenames**: Random hex (no user input)
- **Extensions**: Forbidden `.exe`, `.bat`, `.php`, `.js`, etc.

## Other

- **JSON body limit**: 256KB
- **Static files**: No directory listing (`index: false`)
- **Error responses**: Generic message in production; only error message logged (no stack in prod)
- **Health**: `/health` returns `{ status: 'ok' }`; `/health/email` returns minimal info only in development
- **TLS**: `NODE_TLS_REJECT_UNAUTHORIZED` only set in development when `ALLOW_INSECURE_TLS=1` (ignored in production)

## Production Checklist

1. Set `NODE_ENV=production`
2. Set `JWT_SECRET` (32+ chars, e.g. `openssl rand -base64 32`) – **server exits if missing or &lt; 32**
3. Set `CORS_ORIGIN` to your app origin(s), e.g. `https://yourapp.com` – **server exits if missing**
4. Set `ADMIN_SECRET` for admin dashboard
5. Use HTTPS (HSTS with preload is enabled in production)
6. Do not set `ALLOW_INSECURE_TLS` in production (it is ignored)
7. Run behind a reverse proxy (e.g. nginx) for TLS termination and set `trust proxy`
