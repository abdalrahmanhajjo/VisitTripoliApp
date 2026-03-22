# Backend always running online (free)

Run your backend **on the internet 24/7**, not on your computer. Use **Supabase** for the database and **Render** (or similar) to host the Node.js API so it’s always available at a public URL.

---

## 1. Supabase database (free)

1. Go to [supabase.com](https://supabase.com) → **Start your project** → sign in with GitHub.
2. **New project**: pick an org, name (e.g. `tripoli-explorer`), database password (save it), region.
3. Wait for the project to be ready.
4. **Connection string**:
   - **Project Settings** (gear) → **Database**.
   - Under **Connection string** choose **URI**.
   - Copy the URI. It looks like:
     ```
     postgresql://postgres.[project-ref]:[YOUR-PASSWORD]@aws-0-[region].pooler.supabase.com:6543/postgres
     ```
   - For **Node.js (long-lived connections)** use the **Session pooler** on port **5432** (not 6543). In the same Database page, switch to **Session** mode and copy the URI that uses port **5432**.
   - Replace `[YOUR-PASSWORD]` with your database password (URL-encode it if it has special characters).

---

## 2. Run migrations and seed (local, one time)

From the `backend` folder, using the Supabase URI:

1. Create a `.env` file (copy from `.env.example`).
2. Set in `.env`:
   ```env
   DATABASE_URL=postgresql://postgres.[project-ref]:YOUR_PASSWORD@aws-0-xx.pooler.supabase.com:5432/postgres
   NODE_ENV=development
   JWT_SECRET=your-minimum-32-character-secret-here
   ```
   If you see SSL/cert errors, add:
   ```env
   DB_ACCEPT_SELF_SIGNED=1
   ```
3. Install and run schema + migrations + seed:
   ```bash
   npm install
   npm run db:migrate
   npm run db:seed
   npm run db:seed-trips
   npm run db:seed-tours
   ```
4. Start the API locally to verify:
   ```bash
   npm run dev
   ```
   Then open `http://localhost:3000/api/categories` — you should get JSON.

---

## 3. Deploy the API so it always runs online (free)

Deploy the **Node.js backend** to a host. It will run on their servers (not your PC) and stay available at a public URL.

### Option A: Render (recommended, 100% free, no credit card)

**One-click (Blueprint):** The project has a `render.yaml` in the **repo root**. Push to GitHub, then on [render.com](https://render.com) go to **New** → **Blueprint**, connect the repo, and apply. Add `DATABASE_URL` and `CORS_ORIGIN` when prompted (or in the Dashboard). The backend will deploy and run online.

**Manual:**  
1. Push your code to **GitHub** (repo that contains the `backend` folder or the whole project).  
2. Go to [render.com](https://render.com) → **Sign up** → **New** → **Web Service**.  
3. Connect your GitHub repo. If the backend is in a subfolder, set **Root Directory** to `backend`.
4. **Build command:** `npm install`
5. **Start command:** `npm start`
6. **Environment** → Add these variables:
   - `DATABASE_URL` = your Supabase Session URI (port 5432)
   - `NODE_ENV` = `production`
   - `JWT_SECRET` = at least 32 characters (e.g. run `openssl rand -base64 32` and paste the result)
   - `CORS_ORIGIN` = your app’s origin(s), e.g. `https://your-app.web.app` or `http://localhost:8080,https://localhost:8080` for dev
   - Optional: `ADMIN_SECRET`, `RESET_PASSWORD_BASE_URL`, SMTP vars, etc.
7. If you see Supabase SSL errors in the logs, add:
   - `DB_ACCEPT_SELF_SIGNED` = `1`
8. Click **Create Web Service**. Render will build and start your backend and give you a URL like `https://your-api.onrender.com`. **Use this URL in your Flutter app** as the API base URL so the app talks to the backend that’s always running online.

**Free tier:** The service may sleep after ~15 minutes with no traffic. When someone hits it again, it wakes up (first request can take 30–60 seconds). To keep it awake, use the keep-alive step below.

### Keep the backend awake (optional, free)

So the backend doesn’t go to sleep on Render’s free tier, ping it regularly:

1. Use a free **cron / uptime** service, e.g. [cron-job.org](https://cron-job.org) or [UptimeRobot](https://uptimerobot.com).
2. Create a job that sends a **GET** request to:
   ```
   https://your-api.onrender.com/health
   ```
   (replace with your actual Render URL.)
3. Set the interval to **every 10–14 minutes**. That keeps the service from sleeping so it responds quickly for your users.

Your backend then runs online and stays responsive without running anything on your own machine.

### Option B: Railway

1. [railway.app](https://railway.app) → **Start a New Project** → **Deploy from GitHub**.
2. Select the repo; set root to `backend` if needed.
3. Add the same env vars as above (`DATABASE_URL`, `NODE_ENV`, `JWT_SECRET`, `CORS_ORIGIN`, etc.).
4. Deploy; Railway will assign a public URL.

### Option C: Fly.io

1. Install [flyctl](https://fly.io/docs/hands-on/install-flyctl/).
2. In `backend`: `fly launch` (create app, no DB).
3. `fly secrets set DATABASE_URL="your-supabase-uri"` (and other vars).
4. `fly deploy`.

---

## 4. Point the Flutter app at the API

In your Flutter app, set the API base URL to the deployed backend, e.g.:

- `https://your-api.onrender.com`  
or  
- `https://your-app.railway.app`

Where that is configured depends on your app (e.g. env file, `ApiConfig`, or build flavors). Use the same URL (with `https://` and no trailing slash) for all API requests.

---

## 5. Supabase free tier limits

- **Database**: 500 MB, 2 projects.
- **Auth / Storage**: generous free limits; your backend uses only the **database** (Postgres).
- **Connection pooler**: Session pooler (port 5432) is the right choice for this Node.js API.

---

## Quick checklist

| Step | What to do |
|------|------------|
| 1 | Create Supabase project, get **Session** connection URI (port 5432). |
| 2 | Locally: in `backend/.env` set `DATABASE_URL`, `JWT_SECRET`; run `db:migrate`, `db:seed`, `db:seed-trips`, `db:seed-tours`. |
| 3 | Deploy backend to **Render** (or Railway / Fly.io) with the same env vars so it **always runs online**. |
| 4 | Set your Flutter app’s API base URL to the deployed URL (e.g. `https://your-api.onrender.com`). |
| 5 | (Optional) Add a cron that pings `https://your-api.onrender.com/health` every 10–14 minutes so the free tier doesn’t sleep. |
