/**
 * SMTP config: read from file (saved from app) or env.
 */
const fs = require('fs');
const path = require('path');

const CONFIG_PATH = path.join(__dirname, '../../config/smtp.json');

function loadFromFile() {
  try {
    const data = fs.readFileSync(CONFIG_PATH, 'utf8');
    return JSON.parse(data);
  } catch (_) {
    return null;
  }
}

function saveToFile(config) {
  const dir = path.dirname(CONFIG_PATH);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2), 'utf8');
}

function getSmtpConfig() {
  const file = loadFromFile();
  return {
    host: file?.host || process.env.SMTP_HOST || '',
    port: file?.port || process.env.SMTP_PORT || '587',
    user: file?.user || process.env.SMTP_USER || '',
    pass: file?.pass ?? process.env.SMTP_PASS ?? '',
  };
}

function isConfigured() {
  const c = getSmtpConfig();
  return !!(c.host && c.user && c.pass);
}

module.exports = {
  getSmtpConfig,
  saveToFile,
  loadFromFile,
  isConfigured,
};
