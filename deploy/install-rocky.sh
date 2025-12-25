#!/bin/bash
# Strudel AI - Rocky Linux 9 Quick Installation Script
# Uses Git clone method - requires repo to be pushed to GitHub first
# Run as root: sudo bash install-rocky.sh

set -e

echo "=== Strudel AI - Rocky Linux 9 Installation ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo bash install-rocky.sh"
    exit 1
fi

# 1. Update system
echo "[1/8] Updating system..."
dnf update -y

# 2. Install essentials
echo "[2/8] Installing dependencies..."
dnf install -y curl git nginx firewalld epel-release

# 3. Install Node.js 20
echo "[3/8] Installing Node.js 20..."
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs

# 4. Install PM2
echo "[4/8] Installing PM2..."
npm install -g pm2

# 5. Clone repo (REPLACE WITH YOUR GITHUB URL)
echo "[5/8] Cloning repository..."
cd /opt
git clone https://github.com/YOUR_USERNAME/strudel-ai.git
cd strudel-ai

# 6. Install dependencies & build
echo "[6/8] Installing dependencies and building..."
npm install
npm run build

# 7. Set OpenAI API key
read -p "Enter your OpenAI API key: " OPENAI_KEY
echo "OPENAI_API_KEY=$OPENAI_KEY" > .env
chmod 600 .env

# 8. Configure Nginx
echo "[7/8] Configuring Nginx..."

# SELinux - allow nginx to connect to network
setsebool -P httpd_can_network_connect 1

cat > /etc/nginx/conf.d/strudel-ai.conf << 'EOF'
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
    }
}
EOF

systemctl enable nginx
systemctl start nginx
nginx -t && systemctl reload nginx

# Configure firewalld
echo "[8/8] Configuring firewall..."
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# Start with PM2
pm2 start npm --name "strudel-ai" -- start
pm2 save
pm2 startup

echo ""
echo "=== DONE! ==="
echo "Your app is live at: http://$(hostname -I | awk '{print $1}')"
echo ""
echo "Commands:"
echo "  pm2 logs strudel-ai    - View logs"
echo "  pm2 restart strudel-ai - Restart"
