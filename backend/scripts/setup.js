#!/usr/bin/env node
/**
 * One-shot setup: ensure .env exists, run migrations, seed.
 * Run from backend/: node scripts/setup.js
 * Or: npm run setup
 */
const path = require('path');
const fs = require('fs');
const { execSync } = require('child_process');

const root = path.join(__dirname, '..');
const envPath = path.join(root, '.env');
const envExamplePath = path.join(root, '.env.example');

function run(cmd, opts = {}) {
  try {
    execSync(cmd, { cwd: root, stdio: 'inherit', ...opts });
    return true;
  } catch (e) {
    return false;
  }
}

// 1. Ensure .env exists
if (!fs.existsSync(envPath)) {
  fs.copyFileSync(envExamplePath, envPath);
  console.log('Created .env from .env.example. Set DATABASE_URL (and other vars) in backend/.env');
}

// 2. Load .env to check DATABASE_URL
require('dotenv').config({ path: envPath });
const dbUrl = process.env.DATABASE_URL || '';
const isPlaceholder = dbUrl.includes('localhost:5432/tripoli_explorer') && dbUrl.includes('password');

if (!dbUrl || isPlaceholder) {
  console.log('\nNext: set DATABASE_URL in backend/.env');
  console.log('  - Local: postgresql://user:password@localhost:5432/tripoli_explorer');
  console.log('  - Supabase: Project Settings → Database → Connection string (URI, Session)');
  process.exit(1);
}

// 3. Migrate
console.log('\nRunning migrations...');
if (!run('node src/db/migrate.js')) {
  console.error('\nMigration failed. Check DATABASE_URL and that the DB is reachable.');
  process.exit(1);
}

// 4. Seed
console.log('\nSeeding...');
if (!run('node src/db/seed.js')) {
  console.warn('Seed failed or skipped (non-fatal).');
}

console.log('\nSetup done. Start the API with: npm run dev');
process.exit(0);
