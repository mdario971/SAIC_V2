# Strudel AI - Debian 13 VPS Deployment Guide

This guide provides step-by-step instructions to deploy the Strudel AI application on a Debian 13 server.

## Prerequisites

- Debian 13 (Trixie) server with root or sudo access
- SSH access to your server
- A domain name (optional, but recommended)
- OpenAI API key

## Quick Deploy (One-Command)

SSH into your server and run:

```bash
curl -sSL https://raw.githubusercontent.com/your-repo/strudel-ai/main/deploy/install.sh | bash
```

Or manually copy the scripts and run:

```bash
chmod +x deploy/*.sh
sudo ./deploy/install.sh
```

## Manual Installation Steps

### 1. Install System Dependencies

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git nginx certbot python3-certbot-nginx
```

### 2. Install Node.js 20

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### 3. Install PM2 Process Manager

```bash
sudo npm install -g pm2
```

### 4. Clone and Setup Application

```bash
cd /opt
sudo git clone https://your-repo-url/strudel-ai.git
cd strudel-ai
sudo npm install
sudo npm run build
```

### 5. Configure Environment Variables

```bash
sudo cp .env.example .env
sudo nano .env
# Add your OPENAI_API_KEY and other secrets
```

### 6. Start with PM2

```bash
pm2 start npm --name "strudel-ai" -- start
pm2 save
pm2 startup
```

### 7. Configure Nginx

See `nginx.conf` in this directory for the configuration template.

### 8. Setup SSL (Optional)

```bash
sudo certbot --nginx -d yourdomain.com
```

## Audio Streaming Setup (Optional)

For live audio streaming to online listeners:

### Install Icecast2

```bash
sudo apt install -y icecast2
sudo nano /etc/icecast2/icecast.xml
# Configure source password, admin password, hostname
sudo systemctl enable icecast2
sudo systemctl start icecast2
```

## Firewall Configuration

```bash
sudo apt install -y ufw
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 8000/tcp  # For Icecast streaming
sudo ufw enable
```

## Monitoring

```bash
# View logs
pm2 logs strudel-ai

# Monitor resources
pm2 monit

# Restart application
pm2 restart strudel-ai
```

## Troubleshooting

1. **Application won't start**: Check logs with `pm2 logs strudel-ai`
2. **Nginx 502 error**: Ensure PM2 is running and check port 5000
3. **Audio not working**: Web Audio API requires HTTPS in production
