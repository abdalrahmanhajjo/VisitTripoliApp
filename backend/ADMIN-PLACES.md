# Places admin page – upload images & edit data (outside the app)

A **standalone HTML page** lets you manage place images and place data **outside** the Flutter app. Images can be served from a **separate URL** (e.g. CDN or static host) for the **fastest possible loading**.

## Open the admin page

1. **If the API is running locally**  
   Open in the browser:
   - `http://localhost:3000/admin-places.html`  
   (Replace `3000` with your `PORT` if different.)

2. **If the API is on Render (or any host)**  
   Open:
   - `https://YOUR-API-HOST/admin-places.html`  
   Example: `https://tripoli-explorer-api.onrender.com/admin-places.html`

3. **Run API locally** (if needed):
   ```bash
   cd backend
   npm install
   npm run dev
   ```
   Then open `http://localhost:3000/admin-places.html`.

## Configure the page

On the admin page:

- **API base URL** – Your backend root (e.g. `https://tripoli-explorer-api.onrender.com`). Required.
- **Admin key** – Same as `ADMIN_SECRET` in the backend env. Required for all API calls.
- **Uploads base URL (optional)** – Use this for **fastest image loading**:
  - **Leave empty** to use the API base; images will be loaded from the same host as the API (e.g. `/uploads/images/...`).
  - **Set to a CDN or static host** so images are loaded from that URL instead (e.g. `https://cdn.example.com` or `https://your-static-bucket.s3.amazonaws.com`). The app and the admin page will then load place images from this URL, reducing load on the API and improving speed.

Values are stored in the browser’s `localStorage` so you don’t have to re-enter them each time.

## What you can do

- **List places** – Load all places from `GET /api/admin/places`.
- **Edit place data** – Change name, description, location, category_id, duration, price, best time, latitude, longitude and save with **Save changes** (calls `PUT /api/admin/places/:id`).
- **Upload a new image** – Choose a file (JPEG, PNG, WebP, GIF). The page:
  1. Uploads it with `POST /api/upload/image` (multipart, `X-Admin-Key`).
  2. Gets back a URL like `/uploads/images/xxx.jpg`.
  3. Appends it to the place’s `images` array and updates the place with `PUT /api/admin/places/:id`.

Images are shown as thumbnails with `loading="lazy"` so they load quickly without blocking the page.

## Fastest image loading (outside the app path)

To have images loaded **as fast as possible** and **outside the main app/API path**:

1. **Backend (API)**  
   Set **`UPLOADS_BASE_URL`** in the backend environment to the URL where uploads are served, e.g.:
   - A CDN: `https://your-cdn.example.com`
   - A separate static server: `https://static.yoursite.com`
   - Same host: leave unset so the API uses its own host (and `/uploads`).

   The places API (`GET /api/places`, `GET /api/places/:id`) already uses `UPLOADS_BASE_URL` when building image URLs. So the **Flutter app** will receive image URLs that point to this base, and will load images from there (fast, off the main API path).

2. **Admin page**  
   In “Uploads base URL” enter the **same** base URL (or leave empty to use the API base). Thumbnails and new uploads will then be shown/loaded from that URL.

3. **Optional: serve uploads from a CDN**  
   - Upload files to your CDN or static bucket (e.g. after `POST /api/upload/image`, copy the file to S3/CloudFront or your CDN).
   - Set `UPLOADS_BASE_URL` to the CDN base (e.g. `https://d1234.cloudfront.net`).
   - The API and admin page will then use that base for all place image URLs, so images load from the CDN and not from the API server.

The backend already serves `/uploads` with long-lived cache headers in production (`Cache-Control: public, max-age=31536000, immutable`) so repeat visits load images from cache when you use the API host. Using a dedicated `UPLOADS_BASE_URL` (e.g. CDN) gives you parallel connections and edge caching for the fastest possible loading outside the app path.
