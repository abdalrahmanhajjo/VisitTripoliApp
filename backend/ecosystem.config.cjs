/**
 * PM2 process manager config. Keeps the server running and restarts on crash.
 * Install PM2: npm install -g pm2
 * Start server: pm2 start ecosystem.config.cjs
 * Start on Windows boot: pm2 startup (run as Admin); then pm2 save
 */
module.exports = {
  apps: [
    {
      name: 'tripoli-api',
      script: 'src/index.js',
      cwd: __dirname,
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '400M',
      env: { NODE_ENV: 'development' },
      env_production: { NODE_ENV: 'production' },
    },
  ],
};
