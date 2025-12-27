module.exports = {
  apps: [{
    name: 'saic',
    script: 'npm',
    args: 'run start',
    cwd: '/opt/SAIC',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 5000
    }
  }]
};
