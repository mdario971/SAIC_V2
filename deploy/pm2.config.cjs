module.exports = {
  apps: [{
    name: 'saic',
    script: 'npm',
    args: 'run start',
    env: {
      NODE_ENV: 'production',
      PORT: 80
    },
    env_production: {
      NODE_ENV: 'production'
    }
  }]
};
