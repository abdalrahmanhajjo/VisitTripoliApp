# AI Planner – Free Groq (no n8n)

The planner uses **Groq’s free API** by default so you don’t need n8n.

## Setup (about 1 minute)

1. **Get a free API key**
   - Go to [console.groq.com](https://console.groq.com)
   - Sign up or log in
   - Create an API key (starts with `gsk_`)

2. **Configure the backend**
   - Open `backend/.env`
   - Set:
     ```env
     GROQ_API_KEY=gsk_your_actual_key_here
     ```
   - Save the file

3. **Restart the backend**
   ```bash
   cd backend
   npm run dev
   ```

4. **Test**
   - In the app, open the **Planner** tab and send e.g. “Plan one day in Tripoli” or “2 days, food and culture”.
   - Or in a browser: `http://localhost:3000/api/ai/test` — you should see `"ok": true`, `"provider": "groq"`.

## Behaviour

- If **GROQ_API_KEY** is set, the backend calls **Groq directly** (no n8n). Same free model (e.g. `llama-3.1-8b-instant`), fewer moving parts.
- If **GROQ_API_KEY** is not set but **N8N_WEBHOOK_URL** is set, the backend uses the n8n webhook as before.
- Optional in `.env`: **GROQ_MODEL** (default `llama-3.1-8b-instant`). You can switch to e.g. `llama-3.1-70b-versatile` if your key allows it.

## Status

- `GET /api/ai/status` — returns `provider: "groq"` or `"n8n"` and whether each is configured.
- `GET /api/ai/test` — sends a short prompt and returns the result so you can confirm the AI is working.
