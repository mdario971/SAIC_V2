# Deployment Guide

Complete instructions for deploying Strudel AI to a Debian 13 VPS.

## Prerequisites

- Debian 13 VPS with root access
- OpenAI API key
- Domain name (optional, for SSL)

## Quick Deploy

SSH into your server and run:

```bash
# Download the installer
curl -o install.sh https://raw.githubusercontent.com/mdario971/SAIC/main/deploy/full-install.sh

# Make executable and run
chmod +x install.sh
sudo bash install.sh
```

The script will prompt you for your OpenAI API key.

## Manual Installation

### 1. System Setup

```bash
# Update system
apt update && apt upgrade -y

# Install dependencies
apt install -y curl git nginx ufw build-essential

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install PM2
npm install -g pm2
```

### 2. Application Setup

```bash
# Clone repository
cd /opt
git clone https://github.com/mdario971/SAIC.git
cd strudel-ai

# Install dependencies
npm install

# Build for production
npm run build

# Create environment file
echo 'OPENAI_API_KEY=your-key-here' > .env
```

### 3. Nginx Configuration

```bash
cat > /etc/nginx/sites-available/strudel-ai << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 120s;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/strudel-ai /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and reload
nginx -t && systemctl reload nginx
```

### 4. Firewall

```bash
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable
```

### 5. Start Application

```bash
# Start with PM2
pm2 start npm --name "strudel-ai" -- start

# Save PM2 config
pm2 save

# Enable startup on boot
pm2 startup
```

## SSL Certificate (Optional)

For HTTPS with Let's Encrypt:

```bash
# Install Certbot
apt install -y certbot python3-certbot-nginx

# Get certificate (replace with your domain)
certbot --nginx -d yourdomain.com

# Auto-renewal is configured automatically
```

## Management Commands

```bash
# View logs
pm2 logs strudel-ai

# Restart application
pm2 restart strudel-ai

# Check status
pm2 status

# Stop application
pm2 stop strudel-ai

# Update application
cd /opt/strudel-ai
git pull
npm install
npm run build
pm2 restart strudel-ai
```

## Environment Variables

Store in `/opt/strudel-ai/.env`:

```bash
OPENAI_API_KEY=sk-your-api-key-here
PORT=5000
NODE_ENV=production
```

## Troubleshooting

### Application not starting

```bash
# Check PM2 logs
pm2 logs strudel-ai --lines 50

# Check if port is in use
lsof -i :5000
```

### Nginx errors

```bash
# Test configuration
nginx -t

# Check error logs
tail -f /var/log/nginx/error.log
```

### Firewall issues

```bash
# Check status
ufw status

# Allow port if needed
ufw allow 5000
```

## Security Notes

1. **API Key**: Keep your `.env` file secure with `chmod 600 .env`
2. **Updates**: Regularly update system packages with `apt update && apt upgrade`
3. **Firewall**: Only expose necessary ports (80, 443, 22)
4. **SSL**: Always use HTTPS in production
