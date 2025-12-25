#!/bin/bash
# SAIC (Strudel AI) - Debian 13 Quick Installation Script
# Uses Git clone method - requires repo to be pushed to GitHub first
# Run as root: sudo bash install-debian.sh

set -e

echo "=== SAIC - Debian 13 Installation ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo bash install-debian.sh"
    exit 1
fi

# 1. Update system
echo "[1/8] Updating system..."
apt update && apt upgrade -y

# 2. Install essentials
echo "[2/8] Installing dependencies..."
apt install -y curl git nginx ufw build-essential

# 3. Install Node.js 20
echo "[3/8] Installing Node.js 20..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
fi

# 4. Install PM2
echo "[4/8] Installing PM2..."
npm install -g pm2

# 5. Clone repo
echo "[5/8] Cloning repository..."
cd /opt
git clone https://github.com/mdario971/SAIC.git
cd SAIC

# 6. Install dependencies & build
echo "[6/8] Installing dependencies and building..."
npm install
npm run build

# 7. Create .env file
echo "[7/8] Setting up environment..."
echo ""
echo "IMPORTANT: Create your .env file with your OpenAI API key:"
echo "  echo 'OPENAI_API_KEY=your-key-here' > /opt/SAIC/.env"
echo "  chmod 600 /opt/SAIC/.env"
echo ""
touch .env
chmod 600 .env

# 8. Configure Nginx
echo "[8/8] Configuring Nginx..."
cat > /etc/nginx/sites-available/saic << 'EOF'
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
ln -sf /etc/nginx/sites-available/saic /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Configure firewall
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable

echo ""
echo "=== INSTALLATION COMPLETE ==="
echo ""
echo "NEXT STEP - Add your OpenAI API key:"
echo "  echo 'OPENAI_API_KEY=sk-your-key' > /opt/SAIC/.env"
echo ""
echo "Then start the app:"
echo "  cd /opt/SAIC && pm2 start npm --name saic -- start"
echo "  pm2 save && pm2 startup"
echo ""
echo "Your app will be at: http://$(hostname -I | awk '{print $1}')"
