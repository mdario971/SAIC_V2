#!/bin/bash
# SAIC (Strudel AI) - Debian 13 Quick Installation Script
# Uses Git clone method - requires repo to be pushed to GitHub first
# Run as root: sudo bash install-debian.sh

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         SAIC - Debian 13 Installation Script               ║"
echo "╚════════════════════════════════════════════════════════════╝"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo bash install-debian.sh"
    exit 1
fi

echo ""
echo "=== Configuration ==="
echo ""

# Prompt for OpenAI API key
read -p "Enter your OpenAI API key: " OPENAI_KEY
if [ -z "$OPENAI_KEY" ]; then
    echo "OpenAI API key is required!"
    exit 1
fi

# Prompt for authentication (optional)
echo ""
echo "=== Password Protection (Recommended) ==="
echo "Leave blank to skip (app will be publicly accessible)"
echo ""
read -p "Enter admin username: " AUTH_USER
if [ -n "$AUTH_USER" ]; then
    read -s -p "Enter admin password: " AUTH_PASS
    echo ""
    if [ -z "$AUTH_PASS" ]; then
        echo "Password cannot be empty if username is set!"
        exit 1
    fi
    echo "Password protection: ENABLED"
else
    echo "Password protection: DISABLED (public access)"
fi

echo ""

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
if [ -d "SAIC" ]; then
    rm -rf SAIC
fi
git clone https://github.com/mdario971/SAIC.git
cd SAIC

# 6. Install dependencies & build
echo "[6/8] Installing dependencies and building..."
npm install
npm run build

# 7. Create .env file with all credentials
echo "[7/8] Setting up environment..."
cat > .env << EOF
OPENAI_API_KEY=$OPENAI_KEY
EOF

if [ -n "$AUTH_USER" ]; then
    cat >> .env << EOF
AUTH_USER=$AUTH_USER
AUTH_PASS=$AUTH_PASS
EOF
fi

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

# Start with PM2
pm2 start npm --name "saic" -- start
pm2 save
pm2 startup

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              INSTALLATION COMPLETE!                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Your app is live at: http://$(hostname -I | awk '{print $1}')"
echo ""
if [ -n "$AUTH_USER" ]; then
    echo "Login credentials:"
    echo "  Username: $AUTH_USER"
    echo "  Password: (as configured)"
fi
echo ""
echo "Commands:"
echo "  pm2 logs saic    - View logs"
echo "  pm2 restart saic - Restart app"
echo "  pm2 status       - Check status"
echo ""
echo "IMPORTANT: Install SSL for security!"
echo "  apt install certbot python3-certbot-nginx"
echo "  certbot --nginx -d yourdomain.com"
