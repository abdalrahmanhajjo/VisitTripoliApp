# Keep the server running always

The server can run 24/7 and restart automatically if it crashes. Optionally, it can start when Windows starts.

## 1. Install PM2 (one time)

Open PowerShell or Command Prompt and run:

```bash
npm install -g pm2
```

If you get permission errors, run the same in **Run as Administrator**, or use:

```bash
npm install -g pm2 --prefix %APPDATA%\npm
```

Make sure the npm global bin folder is in your PATH (often `%APPDATA%\npm`).

## 2. Start the server (keeps running until you stop it)

From the **backend** folder:

```bash
cd path\to\Figma1\backend
npm run start:always
```

Or directly:

```bash
pm2 start ecosystem.config.cjs
```

The server will keep running in the background. If it crashes, PM2 restarts it.

**Useful commands:**

| Command | Description |
|--------|-------------|
| `npm run status:always` or `pm2 status` | See if the server is running |
| `npm run restart:always` or `pm2 restart tripoli-api` | Restart the server |
| `npm run stop:always` or `pm2 stop tripoli-api` | Stop the server |
| `pm2 logs tripoli-api` | View server logs |

## 3. Start the server when Windows starts (optional)

So the server is online as soon as you turn on your PC:

1. Open **PowerShell as Administrator** (right‑click → Run as administrator).
2. Run:
   ```bash
   pm2 startup
   ```
3. PM2 will print a command; **copy and run that command** in the same Admin PowerShell.
4. Start your app and save the process list:
   ```bash
   cd path\to\Figma1\backend
   pm2 start ecosystem.config.cjs
   pm2 save
   ```

After that, the server will start automatically at Windows boot.

## 4. Network access (for your phone)

The server listens on `0.0.0.0` by default, so it accepts connections from your phone on the same Wi‑Fi. In the app’s **Settings → API Server URL**, use your PC’s IP, e.g. `http://192.168.1.5:3000`.

To bind to a different host, set the `HOST` environment variable (e.g. in `.env` or in the PM2 ecosystem file).
