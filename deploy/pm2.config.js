// PM2 Configuration for Strudel AI
// Usage: pm2 start pm2.config.js

module.exports = {
  apps: [
    {
      name: 'strudel-ai',
      script: 'npm',
      args: 'start',
      cwd: '/opt/strudel-ai',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 5000,
      },
      env_file: '/opt/strudel-ai/.env',
      error_file: '/var/log/strudel-ai/error.log',
      out_file: '/var/log/strudel-ai/out.log',
      log_file: '/var/log/strudel-ai/combined.log',
      time: true,
      // Graceful shutdown
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 10000,
    },
  ],
};
