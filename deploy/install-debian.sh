#!/bin/bash
# Strudel AI - Debian 13 Installation Script
# Run as root or with sudo

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Strudel AI - Debian 13 Installation Script         ║"
echo "╚════════════════════════════════════════════════════════════╝"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="/opt/strudel-ai"
APP_USER="strudel"
APP_PORT="5000"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

echo -e "${GREEN}[1/8] Updating system packages...${NC}"
apt update && apt upgrade -y

echo -e "${GREEN}[2/8] Installing system dependencies...${NC}"
apt install -y curl git nginx ufw build-essential

echo -e "${GREEN}[3/8] Installing Node.js 20...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
fi

echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"

echo -e "${GREEN}[4/8] Installing PM2 globally...${NC}"
npm install -g pm2

echo -e "${GREEN}[5/8] Creating application user...${NC}"
if ! id "$APP_USER" &>/dev/null; then
    useradd -m -s /bin/bash $APP_USER
fi

echo -e "${GREEN}[6/8] Setting up application directory...${NC}"
mkdir -p $APP_DIR
chown -R $APP_USER:$APP_USER $APP_DIR

echo -e "${GREEN}[7/8] Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/strudel-ai << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }

    # WebSocket support for real-time updates
    location /ws {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }
}
EOF

ln -sf /etc/nginx/sites-available/strudel-ai /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo -e "${GREEN}[8/8] Configuring firewall...${NC}"
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Installation Complete!                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Copy your application files to $APP_DIR"
echo "2. Create .env file with your OPENAI_API_KEY:"
echo "   echo 'OPENAI_API_KEY=your-key-here' > $APP_DIR/.env"
echo ""
echo "3. Install dependencies and build:"
echo "   cd $APP_DIR && npm install && npm run build"
echo ""
echo "4. Start the application with PM2:"
echo "   pm2 start npm --name strudel-ai -- start"
echo "   pm2 save && pm2 startup"
echo ""
echo -e "${GREEN}Your application will be available at http://your-server-ip${NC}"
