# Fix API 500 errors on Render (places, reviews, feed, bookings, etc.)

500 errors on **add review**, **post**, **book**, **fetch places**, and similar usually mean the **database** your Render app uses is missing **tables** or **data**. Run **migrations** and **seed** once against the **same** DATABASE_URL that Render uses.

## 1. Fix "self-signed certificate in certificate chain" (if you see it in Render logs)

In **Render Dashboard** → **tripoli-explorer-api** → **Environment** add:

- **Key:** `DB_ACCEPT_SELF_SIGNED`
- **Value:** `1`

Then **Save** and **Manual Deploy** → **Deploy latest commit**.

## 2. One-time database setup (fixes 500 for places, reviews, feed, bookings, trips, etc.)

1. **Get your production database URL**
   - **Render Dashboard** → **tripoli-explorer-api** → **Environment** → copy **DATABASE_URL** (Supabase connection string, port 5432).

2. **Use that URL locally** – in `backend/.env` set:
   ```env
   DATABASE_URL=<paste the exact URL from Render>
   NODE_ENV=development
   ```
   If you see SSL/cert errors when running commands below, add:
   ```env
   DB_ACCEPT_SELF_SIGNED=1
   ```

3. **From the project root**, run (in order):
   ```bash
   cd backend
   npm install
   npm run db:migrate
   npm run db:seed-all
   ```
   Or run seeds individually: `npm run db:seed`, `npm run db:seed-trips`, `npm run db:seed-tours`, `npm run db:seed-reviews`. `db:seed-all` runs all of these (categories, places, interests, trips, tours, **and reviews**).

4. **Check that DB is reachable from Render**
   - Open: `https://tripoli-explorer-api.onrender.com/health/db` or `https://tripoli-explorer-api.onrender.com/api/health/db`
   - You should see: `{"status":"ok","db":"connected"}`
   - If you see **Cannot GET /health/db**: the backend deploy may not include this route yet — push your code and redeploy on Render, then try again.
   - If you see `db: "failed"`, the DB URL or SSL setting on Render is wrong (re-check step 1 and DATABASE_URL).

5. **Reload your app** – no need to redeploy; Render already uses that DATABASE_URL. Try again: places list, add review, create post, booking, etc.

After this, tables like `places`, `place_reviews`, `feed_posts`, `bookings`, `trips`, `tours`, and the rest exist with data, and API 500s for those features should stop.

**If you use Supabase with a table named `reviews`** (not `place_reviews`): the reviews API will try `place_reviews` first, then `reviews`. If the `profiles` table is missing, it will fall back to queries without the join (author shown as "Visitor"). Ensure `reviews` has columns: `id`, `place_id`, `user_id`, `rating`, `title`, `review`.

---

## Apply Supabase schema dump to a database

If you have exported your Supabase schema to `backend/supabase_schema.sql` (via `npm run db:dump-schema`), you can apply it to any database (e.g. a new Supabase project or local Postgres):

1. Set **DATABASE_URL** in `backend/.env` to the target database.
2. Run:
   ```bash
   cd backend
   npm run db:apply-supabase-schema
   ```
   This runs all `CREATE TABLE IF NOT EXISTS` from `supabase_schema.sql`. Then run all seeds (including reviews): `npm run db:seed-all`.

## 3. If 500s persist

- In **Render** → **Logs**, look for `DB check failed:` after deploy. If you see it, the app cannot reach the database (wrong URL or SSL).
- For **feed posts**: creating a post with an image needs **SUPABASE_URL** and **SUPABASE_SERVICE_ROLE_KEY** in Render Environment (see backend feed/upload docs). Without them, image upload returns 503, not 500.
- Locally, run the same API call with `NODE_ENV=development`; the 500 response body may include a `detail` field with the real error (e.g. missing table or column).

---

## Enable AI Planner on Render ("AI not configured")

If the app shows **"AI is not available. AI not configured"** in the Planner tab:

1. Get a **free Groq API key**: [console.groq.com](https://console.groq.com) → sign up → create an API key (starts with `gsk_`).
2. In **Render Dashboard** → **tripoli-explorer-api** → **Environment**, add:
   - **Key:** `GROQ_API_KEY`
   - **Value:** your key (e.g. `gsk_...`)
3. **Save** and **Manual Deploy** → **Deploy latest commit**.
4. In the app, open **AI Planner** and try again (e.g. "hello" or "Plan one day in Tripoli").
