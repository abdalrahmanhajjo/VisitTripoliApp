/**
 * Load backend/.env regardless of cwd (repo root or backend/).
 */
const path = require('path');
const fs = require('fs');

function loadEnv() {
  const backendEnv = path.join(__dirname, '..', '..', '.env');
  require('dotenv').config({ path: backendEnv });
  const backendDir = path.dirname(backendEnv);
  if (!process.env.ADMIN_SECRET && process.cwd() !== backendDir) {
    const cwdBackendEnv = path.join(process.cwd(), 'backend', '.env');
    if (fs.existsSync(cwdBackendEnv)) {
      require('dotenv').config({ path: cwdBackendEnv });
    }
  }
}

module.exports = { loadEnv };
