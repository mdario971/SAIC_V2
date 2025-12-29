#!/bin/bash
# SAIC - Universal One-Command Installer
# Works on Debian 13+ and Rocky Linux 9+
# Run as root: curl -fsSL https://raw.githubusercontent.com/mdario971/SAIC/main/deploy/install.sh | sudo bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if being piped - if so, give instructions
if [ ! -t 0 ]; then
    echo ""
    echo -e "${YELLOW}This script requires interactive input.${NC}"
    echo -e "${GREEN}Please run with:${NC}"
    echo ""
    echo "  curl -O https://raw.githubusercontent.com/mdario971/SAIC/main/deploy/install.sh && sudo bash install.sh"
    echo ""
    exit 1
fi

clear
echo -e "${PURPLE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║     ███████╗ █████╗ ██╗ ██████╗                           ║"
echo "║     ██╔════╝██╔══██╗██║██╔════╝                           ║"
echo "║     ███████╗███████║██║██║                                ║"
echo "║     ╚════██║██╔══██║██║██║                                ║"
echo "║     ███████║██║  ██║██║╚██████╗                           ║"
echo "║     ╚══════╝╚═╝  ╚═╝╚═╝ ╚═════╝                           ║"
echo "║                                                            ║"
echo "║          Strudel AI - Universal Installer                  ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# =============================================
# VERSION SELECTION WITH COMPREHENSIVE MENU
# =============================================
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                         INSTALLATION OPTIONS                                  ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║  OPTION           │ STACK              │ EXTERNAL     │ API KEY REQUIRED     ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  1) SAIC Classic  ${CYAN}│${NC} Node.js + PM2      ${CYAN}│${NC} 22,80,443    ${CYAN}│${NC} ${YELLOW}Optional${NC}             ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  2) SAIC Pro      ${CYAN}│${NC} Node.js + PM2      ${CYAN}│${NC} 22,80,443    ${CYAN}│${NC} ${YELLOW}Optional${NC}             ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  3) Remote + AI   ${CYAN}│${NC} Tomcat + MariaDB   ${CYAN}│${NC} 22,80,443,8080${CYAN}│${NC} ${GREEN}FREE (MCP)${NC}           ${CYAN}║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}NETWORK & FIREWALL:${NC}                                                          ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ├─ External ports: 22 (SSH), 80 (HTTP), 443 (HTTPS)                          ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ├─ Internal only:  5000 (Node.js), 4822 (guacd) - NOT exposed                ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ├─ Option 3 adds:  8080 (Guacamole web interface)                            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  └─ Firewall:       UFW (Debian) / firewalld (Rocky) auto-configured          ${CYAN}║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}COMPONENTS INSTALLED:${NC}                                                       ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ├─ All Options: Nginx, UFW/firewalld, fail2ban, certbot                     ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ├─ Options 1,2: Node.js 20, PM2, build-essential                            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  └─ Option 3:    Tomcat9, MariaDB, guacd, libguac*, Java 11                  ${CYAN}║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}OPTION DETAILS:${NC}                                                              ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ├─ 1) Classic:    Simple editor + DJ mode + quick patterns                  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  │                 Best for: Beginners, mobile music making                  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ├─ 2) Pro:        Embedded strudel.cc REPL + music theory tools             ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  │                 Best for: Experienced live coders                         ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  └─ 3) Remote+AI:  Guacamole + Strudel MCP Server (no API keys)              ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                    Best for: Remote VPS access, headless automation          ${CYAN}║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}GET API KEY (Options 1 & 2 only):${NC}                                            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  └─ OpenAI:    ${GREEN}https://platform.openai.com/api-keys${NC}                        ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}     Option 3 is ${GREEN}FREE${NC} - uses MCP protocol, no API keys needed              ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                                              ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}NEED TEMP EMAIL/PHONE FOR SIGNUP?${NC}                                           ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ├─ Email:  ${BLUE}https://mail.tm${NC} or ${BLUE}https://temp-mail.io${NC}                       ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  └─ SMS:    ${BLUE}https://quackr.io${NC} or ${BLUE}https://sms-activate.io/freeNumbers${NC}      ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
read -p "Enter choice (1, 2, or 3) [2]: " VERSION_CHOICE </dev/tty
VERSION_CHOICE=${VERSION_CHOICE:-2}

INSTALL_GUACAMOLE=false

case $VERSION_CHOICE in
    1)
        GIT_BRANCH="main"
        echo -e "${GREEN}Selected: SAIC Classic (main branch)${NC}"
        ;;
    2)
        GIT_BRANCH="Pro"
        echo -e "${GREEN}Selected: SAIC Pro (Pro branch)${NC}"
        ;;
    3)
        GIT_BRANCH="Pro"
        INSTALL_GUACAMOLE=true
        echo -e "${GREEN}Selected: Remote Desktop + Strudel MCP (FREE)${NC}"
        ;;
    *)
        GIT_BRANCH="Pro"
        echo -e "${YELLOW}Invalid choice, defaulting to SAIC Pro${NC}"
        ;;
esac

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root: sudo bash install.sh${NC}"
    exit 1
fi

# =============================================
# Check for existing installation
# =============================================
echo ""
echo -e "${CYAN}=== Checking for Existing Installation ===${NC}"
echo ""

FOUND_EXISTING=false
EXISTING_ITEMS=""

# Check for SAIC directory
if [ -d "/opt/SAIC" ]; then
    FOUND_EXISTING=true
    EXISTING_ITEMS="${EXISTING_ITEMS}\n  - /opt/SAIC (application directory)"
fi

# Check for PM2 process
if command -v pm2 &> /dev/null; then
    if pm2 list 2>/dev/null | grep -q "saic"; then
        FOUND_EXISTING=true
        EXISTING_ITEMS="${EXISTING_ITEMS}\n  - PM2 process 'saic'"
    fi
fi

# Check for nginx config
if [ -f "/etc/nginx/sites-available/saic" ] || [ -f "/etc/nginx/conf.d/saic.conf" ]; then
    FOUND_EXISTING=true
    EXISTING_ITEMS="${EXISTING_ITEMS}\n  - Nginx configuration"
fi

# Check for SSL helper script
if [ -f "/usr/local/bin/saic-ssl" ]; then
    FOUND_EXISTING=true
    EXISTING_ITEMS="${EXISTING_ITEMS}\n  - /usr/local/bin/saic-ssl"
fi

if [ "$FOUND_EXISTING" = true ]; then
    echo -e "${YELLOW}Existing SAIC installation detected:${NC}"
    echo -e "$EXISTING_ITEMS"
    echo ""
    read -p "Remove existing installation before continuing? (Y/n): " CLEAN_EXISTING </dev/tty
    
    if [[ ! "$CLEAN_EXISTING" =~ ^[Nn]$ ]]; then
        echo ""
        echo -e "${BLUE}Cleaning existing installation...${NC}"
        
        # Stop and delete PM2 process
        if command -v pm2 &> /dev/null; then
            pm2 stop saic 2>/dev/null || true
            pm2 delete saic 2>/dev/null || true
            pm2 save 2>/dev/null || true
        fi
        
        # Remove app directory
        if [ -d "/opt/SAIC" ]; then
            rm -rf /opt/SAIC
            echo -e "  Removed /opt/SAIC"
        fi
        
        # Remove nginx configs
        if [ -f "/etc/nginx/sites-available/saic" ]; then
            rm -f /etc/nginx/sites-available/saic
            rm -f /etc/nginx/sites-enabled/saic
            echo -e "  Removed Nginx config (Debian)"
        fi
        if [ -f "/etc/nginx/conf.d/saic.conf" ]; then
            rm -f /etc/nginx/conf.d/saic.conf
            echo -e "  Removed Nginx config (Rocky)"
        fi
        
        # Remove SSL helper
        if [ -f "/usr/local/bin/saic-ssl" ]; then
            rm -f /usr/local/bin/saic-ssl
            echo -e "  Removed saic-ssl command"
        fi
        
        # Reload nginx if running
        if systemctl is-active --quiet nginx; then
            nginx -t 2>/dev/null && systemctl reload nginx
        fi
        
        echo -e "${GREEN}Cleanup complete!${NC}"
    else
        echo -e "${YELLOW}Keeping existing installation. Will overwrite files.${NC}"
    fi
else
    echo -e "${GREEN}No existing installation detected.${NC}"
    echo ""
    read -p "Check and clean any leftover files anyway? (y/N): " CLEAN_ANYWAY </dev/tty
    
    if [[ "$CLEAN_ANYWAY" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Checking for leftover files...${NC}"
        
        # Stop and delete PM2 process if exists
        if command -v pm2 &> /dev/null; then
            pm2 stop saic 2>/dev/null || true
            pm2 delete saic 2>/dev/null || true
        fi
        
        # Remove potential leftovers
        rm -rf /opt/SAIC 2>/dev/null || true
        rm -f /etc/nginx/sites-available/saic 2>/dev/null || true
        rm -f /etc/nginx/sites-enabled/saic 2>/dev/null || true
        rm -f /etc/nginx/conf.d/saic.conf 2>/dev/null || true
        rm -f /usr/local/bin/saic-ssl 2>/dev/null || true
        
        echo -e "${GREEN}Cleanup complete!${NC}"
    fi
fi

echo ""

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
    else
        OS_ID="unknown"
    fi
}

detect_os

echo ""
echo -e "${CYAN}=== Step 1: Operating System ===${NC}"
echo ""

# Auto-detect or ask
if [[ "$OS_ID" == "debian" || "$OS_ID" == "ubuntu" ]]; then
    DETECTED_OS="debian"
    echo -e "Detected: ${GREEN}Debian/Ubuntu${NC}"
elif [[ "$OS_ID" == "rocky" || "$OS_ID" == "rhel" || "$OS_ID" == "centos" || "$OS_ID" == "fedora" || "$OS_ID" == "almalinux" ]]; then
    DETECTED_OS="rocky"
    echo -e "Detected: ${GREEN}Rocky/RHEL-based${NC}"
else
    DETECTED_OS=""
    echo -e "${YELLOW}Could not auto-detect OS${NC}"
fi

if [ -n "$DETECTED_OS" ]; then
    echo ""
    read -p "Use detected OS? (Y/n): " USE_DETECTED </dev/tty
    if [[ "$USE_DETECTED" =~ ^[Nn]$ ]]; then
        DETECTED_OS=""
    fi
fi

if [ -z "$DETECTED_OS" ]; then
    echo ""
    echo "Select your operating system:"
    echo -e "  ${CYAN}1)${NC} Debian / Ubuntu"
    echo -e "  ${CYAN}2)${NC} Rocky Linux / RHEL / AlmaLinux / CentOS"
    echo ""
    read -p "Enter choice (1 or 2): " OS_CHOICE </dev/tty
    case $OS_CHOICE in
        1) DETECTED_OS="debian" ;;
        2) DETECTED_OS="rocky" ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac
fi

echo ""
OPENAI_KEY=""
ANTHROPIC_KEY=""

if [ "$INSTALL_GUACAMOLE" = true ]; then
    # Option 3: Uses MCP protocol - NO API keys needed
    echo -e "${CYAN}=== Step 2: AI Integration (No API Keys) ===${NC}"
    echo ""
    echo -e "${GREEN}Good news! Option 3 requires NO API keys.${NC}"
    echo ""
    echo "This option installs:"
    echo "  - Guacamole (remote desktop via browser)"
    echo "  - Strudel MCP Server (headless Playwright automation)"
    echo ""
    echo "You can then:"
    echo "  - Use Strudel.cc directly at https://strudel.cc"
    echo "  - OR use Claude Desktop (Mac/Windows) with local MCP"
    echo ""
    read -p "Press Enter to continue..." </dev/tty
else
    # Options 1 & 2: OpenAI is required for music generation
    echo -e "${CYAN}=== Step 2: OpenAI API Key (Required) ===${NC}"
    echo ""
    echo "Get your API key at: https://platform.openai.com/api-keys"
    echo ""
    read -p "Enter your OpenAI API key: " OPENAI_KEY </dev/tty
    if [ -z "$OPENAI_KEY" ]; then
        echo -e "${RED}OpenAI API key is required!${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${CYAN}=== Step 3: Password Protection (Optional) ===${NC}"
echo ""
echo "Protect your app with HTTP Basic Authentication."
echo -e "${YELLOW}Leave blank to skip (app will be publicly accessible)${NC}"
echo ""
read -p "Admin username: " AUTH_USER </dev/tty

if [ -n "$AUTH_USER" ]; then
    read -s -p "Admin password: " AUTH_PASS </dev/tty
    echo ""
    if [ -z "$AUTH_PASS" ]; then
        echo -e "${RED}Password cannot be empty if username is set!${NC}"
        exit 1
    fi
    read -s -p "Confirm password: " AUTH_PASS_CONFIRM </dev/tty
    echo ""
    if [ "$AUTH_PASS" != "$AUTH_PASS_CONFIRM" ]; then
        echo -e "${RED}Passwords do not match!${NC}"
        exit 1
    fi
    echo -e "${GREEN}Password protection: ENABLED${NC}"
else
    echo -e "${YELLOW}Password protection: DISABLED (public access)${NC}"
fi

echo ""
echo -e "${CYAN}=== Step 4: Application Port ===${NC}"
echo ""
echo "Default port is 5000 (recommended)"
read -p "Application port [5000]: " APP_PORT </dev/tty
APP_PORT=${APP_PORT:-5000}

echo ""
echo -e "${CYAN}=== Step 5: Installation Method ===${NC}"
echo ""
echo "Choose how to install:"
echo -e "  ${CYAN}1)${NC} Quick Install (git clone from GitHub) - Recommended"
echo -e "  ${CYAN}2)${NC} Full Install (embedded code, no git required)"
echo ""
read -p "Enter choice (1 or 2) [1]: " INSTALL_METHOD </dev/tty
INSTALL_METHOD=${INSTALL_METHOD:-1}

echo ""
echo -e "${CYAN}=== Configuration Summary ===${NC}"
echo ""
if [ "$INSTALL_GUACAMOLE" = true ]; then
    echo -e "  Install:      ${GREEN}Remote Desktop + AI (Guacamole + Claude)${NC}"
else
    echo -e "  Version:      ${GREEN}$([ "$GIT_BRANCH" == "main" ] && echo "Classic Mode" || echo "Pro Mode")${NC}"
fi
echo -e "  Branch:       ${GREEN}$GIT_BRANCH${NC}"
echo -e "  OS Type:      ${GREEN}$DETECTED_OS${NC}"
if [ -n "$OPENAI_KEY" ]; then
    echo -e "  OpenAI Key:   ${GREEN}sk-****${OPENAI_KEY: -4}${NC}"
else
    echo -e "  OpenAI Key:   ${YELLOW}Not set${NC}"
fi
if [ -n "$AUTH_USER" ]; then
    echo -e "  Auth User:    ${GREEN}$AUTH_USER${NC}"
    echo -e "  Auth Pass:    ${GREEN}********${NC}"
else
    echo -e "  Auth:         ${YELLOW}Disabled (public)${NC}"
fi
echo -e "  Port:         ${GREEN}$APP_PORT${NC}"
echo -e "  Method:       ${GREEN}$([ "$INSTALL_METHOD" == "1" ] && echo "Git Clone" || echo "Embedded")${NC}"
echo ""
read -p "Proceed with installation? (Y/n): " CONFIRM </dev/tty
if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

APP_DIR="/opt/SAIC"

# =============================================
# INSTALLATION FUNCTIONS
# =============================================

install_debian_deps() {
    echo -e "${BLUE}[1/8] Updating system...${NC}"
    apt update && apt upgrade -y
    
    echo -e "${BLUE}[2/8] Installing dependencies...${NC}"
    apt install -y curl git nginx ufw fail2ban build-essential chromium xvfb htop
    
    echo -e "${BLUE}[3/8] Installing Node.js 20...${NC}"
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt install -y nodejs
    fi
}

install_rocky_deps() {
    echo -e "${BLUE}[1/8] Updating system...${NC}"
    dnf update -y
    
    echo -e "${BLUE}[2/8] Installing dependencies...${NC}"
    dnf install -y curl git nginx firewalld fail2ban epel-release chromium xorg-x11-server-Xvfb htop
    
    echo -e "${BLUE}[3/8] Installing Node.js 20...${NC}"
    if ! command -v node &> /dev/null; then
        curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
        dnf install -y nodejs
    fi
}

install_pm2() {
    echo -e "${BLUE}[4/8] Installing PM2...${NC}"
    npm install -g pm2
}

configure_fail2ban() {
    echo -e "${BLUE}Configuring fail2ban for SSH and Nginx protection...${NC}"
    
    # Check which filters are available
    FILTER_DIR="/etc/fail2ban/filter.d"
    HAS_NGINX_HTTP_AUTH=false
    HAS_NGINX_LIMIT_REQ=false
    HAS_NGINX_BOTSEARCH=false
    
    [ -f "$FILTER_DIR/nginx-http-auth.conf" ] && HAS_NGINX_HTTP_AUTH=true
    [ -f "$FILTER_DIR/nginx-limit-req.conf" ] && HAS_NGINX_LIMIT_REQ=true
    [ -f "$FILTER_DIR/nginx-botsearch.conf" ] && HAS_NGINX_BOTSEARCH=true
    
    # Determine auth log path
    AUTH_LOG="/var/log/auth.log"
    [ -f /etc/redhat-release ] && AUTH_LOG="/var/log/secure"
    
    # Create base jail configuration (SSH always works)
    cat > /etc/fail2ban/jail.local << JAILEOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = $AUTH_LOG
maxretry = 3
bantime = 86400
JAILEOF

    # Add nginx jails only if their filters exist
    if [ "$HAS_NGINX_HTTP_AUTH" = true ]; then
        cat >> /etc/fail2ban/jail.local << 'JAILEOF'

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 5
bantime = 3600
JAILEOF
        echo -e "  ${GREEN}[OK]${NC} nginx-http-auth jail enabled"
    fi
    
    if [ "$HAS_NGINX_LIMIT_REQ" = true ]; then
        cat >> /etc/fail2ban/jail.local << 'JAILEOF'

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 10
bantime = 7200
JAILEOF
        echo -e "  ${GREEN}[OK]${NC} nginx-limit-req jail enabled"
    fi
    
    if [ "$HAS_NGINX_BOTSEARCH" = true ]; then
        cat >> /etc/fail2ban/jail.local << 'JAILEOF'

[nginx-botsearch]
enabled = true
filter = nginx-botsearch
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 86400
JAILEOF
        echo -e "  ${GREEN}[OK]${NC} nginx-botsearch jail enabled"
    fi
    
    # Enable and start fail2ban (with error handling)
    systemctl enable fail2ban 2>/dev/null || true
    if systemctl restart fail2ban 2>/dev/null; then
        echo -e "  ${GREEN}[OK]${NC} fail2ban started successfully"
    else
        echo -e "  ${YELLOW}[WARN]${NC} fail2ban restart had issues, checking status..."
        systemctl status fail2ban --no-pager 2>/dev/null || true
    fi
}

# =============================================
# GUACAMOLE + STRUDEL MCP SERVER INSTALLATION
# =============================================

install_guacamole_debian() {
    echo -e "${BLUE}[GUAC] Installing Guacamole dependencies...${NC}"
    apt install -y \
        libcairo2-dev libjpeg62-turbo-dev libpng-dev libtool-bin uuid-dev \
        libavcodec-dev libavformat-dev libavutil-dev libswscale-dev \
        freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev \
        libvncserver-dev libwebsockets-dev libpulse-dev libssl-dev \
        libvorbis-dev libwebp-dev tomcat10 tomcat10-admin tomcat10-user \
        default-jdk mariadb-server chromium xvfb dbus-x11 \
        xfce4 xfce4-goodies tigervnc-standalone-server

    # Start MariaDB
    systemctl enable mariadb
    systemctl start mariadb
    
    # Download and build guacd
    GUAC_VERSION="1.5.5"
    cd /tmp
    wget -q "https://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VERSION}/source/guacamole-server-${GUAC_VERSION}.tar.gz" -O guacamole-server.tar.gz || \
    wget -q "https://dlcdn.apache.org/guacamole/${GUAC_VERSION}/source/guacamole-server-${GUAC_VERSION}.tar.gz" -O guacamole-server.tar.gz
    
    tar -xzf guacamole-server.tar.gz
    cd guacamole-server-${GUAC_VERSION}
    ./configure --with-init-dir=/etc/init.d
    make
    make install
    ldconfig
    
    # Create guacd service
    cat > /etc/systemd/system/guacd.service << 'GUACDEOF'
[Unit]
Description=Guacamole Server
After=network.target

[Service]
ExecStart=/usr/local/sbin/guacd -f
Restart=on-failure

[Install]
WantedBy=multi-user.target
GUACDEOF

    systemctl daemon-reload
    systemctl enable guacd
    systemctl start guacd
    
    # Download Guacamole client
    wget -q "https://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VERSION}/binary/guacamole-${GUAC_VERSION}.war" -O /var/lib/tomcat10/webapps/guacamole.war || \
    wget -q "https://dlcdn.apache.org/guacamole/${GUAC_VERSION}/binary/guacamole-${GUAC_VERSION}.war" -O /var/lib/tomcat10/webapps/guacamole.war
    
    # Setup Guacamole directories
    mkdir -p /etc/guacamole/{extensions,lib}
    
    # Download JDBC auth extension for MariaDB
    wget -q "https://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VERSION}/binary/guacamole-auth-jdbc-${GUAC_VERSION}.tar.gz" -O /tmp/guacamole-auth-jdbc.tar.gz || \
    wget -q "https://dlcdn.apache.org/guacamole/${GUAC_VERSION}/binary/guacamole-auth-jdbc-${GUAC_VERSION}.tar.gz" -O /tmp/guacamole-auth-jdbc.tar.gz
    
    cd /tmp
    tar -xzf guacamole-auth-jdbc.tar.gz
    cp guacamole-auth-jdbc-${GUAC_VERSION}/mysql/guacamole-auth-jdbc-mysql-${GUAC_VERSION}.jar /etc/guacamole/extensions/
    
    # Download MySQL connector
    wget -q "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-8.0.33.tar.gz" -O /tmp/mysql-connector.tar.gz
    cd /tmp && tar -xzf mysql-connector.tar.gz
    cp mysql-connector-j-8.0.33/mysql-connector-j-8.0.33.jar /etc/guacamole/lib/
    
    # Create Guacamole database
    GUAC_DB_PASS=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
    mysql -u root << SQLEOF
CREATE DATABASE IF NOT EXISTS guacamole_db;
CREATE USER IF NOT EXISTS 'guacamole_user'@'localhost' IDENTIFIED BY '${GUAC_DB_PASS}';
GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';
FLUSH PRIVILEGES;
SQLEOF
    
    # Import schema
    cat guacamole-auth-jdbc-${GUAC_VERSION}/mysql/schema/*.sql | mysql -u root guacamole_db
    
    # Note: Guacamole default password is 'guacadmin' - user must change via web UI after first login
    # Guacamole uses its own password hashing that isn't easily replicated via CLI
    # Store reminder about default password
    mkdir -p /opt/SAIC
    echo "guacadmin" > /opt/SAIC/.guacadmin_password
    chmod 600 /opt/SAIC/.guacadmin_password
    
    # Create guacamole.properties
    cat > /etc/guacamole/guacamole.properties << PROPEOF
guacd-hostname: localhost
guacd-port: 4822
mysql-hostname: localhost
mysql-port: 3306
mysql-database: guacamole_db
mysql-username: guacamole_user
mysql-password: ${GUAC_DB_PASS}
mysql-auto-create-accounts: true
PROPEOF
    
    # Link for Tomcat
    ln -sf /etc/guacamole /var/lib/tomcat10/.guacamole
    
    # Start Tomcat
    systemctl enable tomcat10
    systemctl restart tomcat10
    
    echo -e "${GREEN}[GUAC] Guacamole installed successfully${NC}"
}

install_guacamole_rocky() {
    echo -e "${BLUE}[GUAC] Installing Guacamole dependencies (Rocky)...${NC}"
    dnf install -y epel-release
    dnf config-manager --set-enabled crb 2>/dev/null || dnf config-manager --set-enabled powertools
    
    dnf install -y \
        cairo-devel libjpeg-turbo-devel libpng-devel libtool uuid-devel \
        ffmpeg-devel freerdp-devel pango-devel libssh2-devel libtelnet-devel \
        libvncserver-devel libwebsockets-devel pulseaudio-libs-devel openssl-devel \
        libvorbis-devel libwebp-devel tomcat java-11-openjdk-devel mariadb-server \
        chromium xorg-x11-server-Xvfb dbus-x11 \
        xfce4-session xfce4-panel xfwm4 tigervnc-server

    # Start MariaDB
    systemctl enable mariadb
    systemctl start mariadb
    
    # Build guacd from source (similar to Debian)
    GUAC_VERSION="1.5.5"
    cd /tmp
    wget -q "https://dlcdn.apache.org/guacamole/${GUAC_VERSION}/source/guacamole-server-${GUAC_VERSION}.tar.gz" -O guacamole-server.tar.gz
    
    tar -xzf guacamole-server.tar.gz
    cd guacamole-server-${GUAC_VERSION}
    ./configure --with-init-dir=/etc/init.d
    make
    make install
    ldconfig
    
    # Create guacd service (same as Debian)
    cat > /etc/systemd/system/guacd.service << 'GUACDEOF'
[Unit]
Description=Guacamole Server
After=network.target

[Service]
ExecStart=/usr/local/sbin/guacd -f
Restart=on-failure

[Install]
WantedBy=multi-user.target
GUACDEOF

    systemctl daemon-reload
    systemctl enable guacd
    systemctl start guacd
    
    # Download and deploy WAR
    wget -q "https://dlcdn.apache.org/guacamole/${GUAC_VERSION}/binary/guacamole-${GUAC_VERSION}.war" -O /var/lib/tomcat/webapps/guacamole.war
    
    mkdir -p /etc/guacamole/{extensions,lib}
    
    # Setup database (same as Debian)
    GUAC_DB_PASS=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
    mysql -u root << SQLEOF
CREATE DATABASE IF NOT EXISTS guacamole_db;
CREATE USER IF NOT EXISTS 'guacamole_user'@'localhost' IDENTIFIED BY '${GUAC_DB_PASS}';
GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';
FLUSH PRIVILEGES;
SQLEOF
    
    # Download JDBC extension
    wget -q "https://dlcdn.apache.org/guacamole/${GUAC_VERSION}/binary/guacamole-auth-jdbc-${GUAC_VERSION}.tar.gz" -O /tmp/guacamole-auth-jdbc.tar.gz
    cd /tmp && tar -xzf guacamole-auth-jdbc.tar.gz
    cp guacamole-auth-jdbc-${GUAC_VERSION}/mysql/guacamole-auth-jdbc-mysql-${GUAC_VERSION}.jar /etc/guacamole/extensions/
    cat guacamole-auth-jdbc-${GUAC_VERSION}/mysql/schema/*.sql | mysql -u root guacamole_db
    
    # MySQL connector
    wget -q "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-8.0.33.tar.gz" -O /tmp/mysql-connector.tar.gz
    cd /tmp && tar -xzf mysql-connector.tar.gz
    cp mysql-connector-j-8.0.33/mysql-connector-j-8.0.33.jar /etc/guacamole/lib/
    
    cat > /etc/guacamole/guacamole.properties << PROPEOF
guacd-hostname: localhost
guacd-port: 4822
mysql-hostname: localhost
mysql-port: 3306
mysql-database: guacamole_db
mysql-username: guacamole_user
mysql-password: ${GUAC_DB_PASS}
mysql-auto-create-accounts: true
PROPEOF
    
    ln -sf /etc/guacamole /var/lib/tomcat/.guacamole
    
    systemctl enable tomcat
    systemctl restart tomcat
    
    echo -e "${GREEN}[GUAC] Guacamole installed successfully${NC}"
}

install_strudel_mcp_server() {
    echo -e "${BLUE}[MCP] Installing Strudel MCP Server...${NC}"
    
    # Ensure /opt/SAIC directory exists before storing credentials
    mkdir -p /opt/SAIC
    
    # Generate random VNC password (8 chars alphanumeric)
    VNC_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 8)
    
    # Store VNC password immediately after generation
    echo "${VNC_PASSWORD}" > /opt/SAIC/.vnc_password
    chmod 600 /opt/SAIC/.vnc_password
    
    # Create saic user for running VNC and MCP server
    if ! id "saic" &>/dev/null; then
        useradd -m -s /bin/bash saic
        echo "saic:${VNC_PASSWORD}" | chpasswd
    fi
    
    # Install Strudel MCP Server globally
    npm install -g @williamzujkowski/strudel-mcp-server
    
    # Install Playwright and Chromium for the saic user
    su - saic -c "npm install -g @williamzujkowski/strudel-mcp-server"
    su - saic -c "npx playwright install chromium"
    
    # Create Claude Desktop config directory and config file
    CLAUDE_CONFIG_DIR="/home/saic/.config/Claude"
    mkdir -p "$CLAUDE_CONFIG_DIR"
    
    cat > "$CLAUDE_CONFIG_DIR/claude_desktop_config.json" << 'CLAUDEEOF'
{
  "mcpServers": {
    "strudel": {
      "command": "npx",
      "args": ["-y", "@williamzujkowski/strudel-mcp-server"]
    }
  }
}
CLAUDEEOF
    
    chown -R saic:saic "$CLAUDE_CONFIG_DIR"
    
    # Create VNC password file with random password
    mkdir -p /home/saic/.vnc
    echo "${VNC_PASSWORD}" | vncpasswd -f > /home/saic/.vnc/passwd
    chmod 600 /home/saic/.vnc/passwd
    chown -R saic:saic /home/saic/.vnc
    
    # Create xstartup for VNC
    cat > /home/saic/.vnc/xstartup << 'VNCEOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
exec startxfce4
VNCEOF
    chmod +x /home/saic/.vnc/xstartup
    chown saic:saic /home/saic/.vnc/xstartup
    
    # Create VNC service
    cat > /etc/systemd/system/vncserver@.service << 'VNCSERVEOF'
[Unit]
Description=VNC Server for display %i
After=syslog.target network.target

[Service]
Type=simple
User=saic
Group=saic
WorkingDirectory=/home/saic
ExecStartPre=/bin/sh -c '/usr/bin/vncserver -kill :%i > /dev/null 2>&1 || :'
ExecStart=/usr/bin/vncserver :%i -geometry 1920x1080 -depth 24 -localhost no
ExecStop=/usr/bin/vncserver -kill :%i
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
VNCSERVEOF
    
    systemctl daemon-reload
    systemctl enable vncserver@1.service
    systemctl start vncserver@1.service
    
    echo -e "${GREEN}[MCP] Strudel MCP Server installed successfully${NC}"
    echo -e "${CYAN}[MCP] VNC running on display :1 (port 5901)${NC}"
}

configure_guacamole_connection() {
    echo -e "${BLUE}[GUAC] Configuring VNC connection...${NC}"
    
    # Wait for Tomcat to fully start
    sleep 5
    
    # Add VNC connection via database using valid MySQL syntax
    # Step 1: Insert connection (use INSERT IGNORE to avoid duplicates)
    mysql -u root guacamole_db -e "
        INSERT IGNORE INTO guacamole_connection (connection_name, protocol) 
        VALUES ('Strudel Desktop', 'vnc');
    "
    
    # Step 2: Get the connection ID
    CONN_ID=$(mysql -u root guacamole_db -N -s -e "
        SELECT connection_id FROM guacamole_connection 
        WHERE connection_name = 'Strudel Desktop' LIMIT 1;
    ")
    
    if [ -z "$CONN_ID" ]; then
        echo -e "${RED}[GUAC] Failed to create connection!${NC}"
        return 1
    fi
    
    echo -e "  Connection ID: ${GREEN}$CONN_ID${NC}"
    
    # Get the VNC password from file
    VNC_PASS=$(cat /opt/SAIC/.vnc_password 2>/dev/null || echo "changeme")
    
    # Step 3: Add connection parameters
    mysql -u root guacamole_db -e "
        INSERT IGNORE INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
        VALUES ($CONN_ID, 'hostname', 'localhost');
        INSERT IGNORE INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
        VALUES ($CONN_ID, 'port', '5901');
        INSERT IGNORE INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
        VALUES ($CONN_ID, 'password', '${VNC_PASS}');
    "
    
    # Step 4: Grant access to guacadmin user
    ENTITY_ID=$(mysql -u root guacamole_db -N -s -e "
        SELECT entity_id FROM guacamole_entity 
        WHERE name = 'guacadmin' AND type = 'USER' LIMIT 1;
    ")
    
    if [ -n "$ENTITY_ID" ]; then
        mysql -u root guacamole_db -e "
            INSERT IGNORE INTO guacamole_connection_permission (entity_id, connection_id, permission)
            VALUES ($ENTITY_ID, $CONN_ID, 'READ');
        "
        echo -e "  Granted access to guacadmin"
    fi
    
    # Verify the connection was created
    VERIFY=$(mysql -u root guacamole_db -N -s -e "
        SELECT COUNT(*) FROM guacamole_connection_parameter 
        WHERE connection_id = $CONN_ID;
    ")
    
    if [ "$VERIFY" -ge 3 ]; then
        echo -e "${GREEN}[GUAC] VNC connection 'Strudel Desktop' configured successfully${NC}"
    else
        echo -e "${YELLOW}[GUAC] Connection created but may be incomplete${NC}"
    fi
}

clone_repo() {
    echo -e "${BLUE}[5/8] Cloning repository (branch: $GIT_BRANCH)...${NC}"
    mkdir -p /opt
    cd /opt
    if [ -d "SAIC" ]; then
        rm -rf SAIC
    fi
    git clone -b "$GIT_BRANCH" https://github.com/mdario971/SAIC.git
    cd SAIC
    
    # Fix package.json to use tsx for production (more reliable)
    # The build script requires esbuild which may have issues
    sed -i 's|"start": "NODE_ENV=production node dist/index.cjs"|"start": "NODE_ENV=production tsx server/index.ts"|g' package.json
    sed -i 's|"build": "tsx script/build.ts"|"build": "vite build \&\& mkdir -p server/public \&\& cp -r dist/public/* server/public/"|g' package.json
}

create_embedded_app() {
    echo -e "${BLUE}[5/8] Creating application files...${NC}"
    mkdir -p $APP_DIR
    cd $APP_DIR
    
    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "saic",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "NODE_ENV=development tsx server/index.ts",
    "build": "vite build",
    "start": "NODE_ENV=production tsx server/index.ts"
  },
  "dependencies": {
    "@hookform/resolvers": "^3.9.1",
    "@radix-ui/react-dialog": "^1.1.4",
    "@radix-ui/react-label": "^2.1.1",
    "@radix-ui/react-select": "^2.1.4",
    "@radix-ui/react-slider": "^1.2.2",
    "@radix-ui/react-slot": "^1.1.1",
    "@radix-ui/react-tabs": "^1.1.2",
    "@radix-ui/react-toast": "^1.2.4",
    "@radix-ui/react-tooltip": "^1.1.6",
    "@tanstack/react-query": "^5.62.7",
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "express": "^4.21.2",
    "lucide-react": "^0.468.0",
    "openai": "^4.77.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-hook-form": "^7.54.2",
    "tailwind-merge": "^2.6.0",
    "wouter": "^3.5.0",
    "zod": "^3.24.1"
  },
  "devDependencies": {
    "@types/express": "^5.0.0",
    "@types/node": "^22.10.2",
    "@types/react": "^18.3.14",
    "@types/react-dom": "^18.3.4",
    "@vitejs/plugin-react": "^4.3.4",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.4.49",
    "tailwindcss": "^3.4.17",
    "tsx": "^4.19.2",
    "typescript": "^5.7.2",
    "vite": "^6.0.5"
  }
}
EOF

    mkdir -p client/src/pages server shared

    # Auth middleware
    cat > server/auth.ts << 'EOF'
import type { Request, Response, NextFunction } from "express";

export function basicAuth(req: Request, res: Response, next: NextFunction) {
  const authUser = process.env.AUTH_USER;
  const authPass = process.env.AUTH_PASS;
  if (!authUser || !authPass) return next();
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Basic ")) {
    res.setHeader("WWW-Authenticate", 'Basic realm="SAIC"');
    return res.status(401).send("Authentication required");
  }
  const base64Credentials = authHeader.split(" ")[1];
  const credentials = Buffer.from(base64Credentials, "base64").toString("utf-8");
  const [username, password] = credentials.split(":");
  if (username === authUser && password === authPass) return next();
  res.setHeader("WWW-Authenticate", 'Basic realm="SAIC"');
  return res.status(401).send("Invalid credentials");
}
EOF

    # Server index
    cat > server/index.ts << 'EOF'
import express from "express";
import { createServer } from "http";
import path from "path";
import { fileURLToPath } from "url";
import { registerRoutes } from "./routes.js";
import { basicAuth } from "./auth.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
app.use(basicAuth);
app.use(express.json());
const httpServer = createServer(app);
await registerRoutes(httpServer, app);
if (process.env.NODE_ENV === "production") {
  app.use(express.static(path.join(__dirname, "../dist/client")));
  app.get("*", (req, res) => res.sendFile(path.join(__dirname, "../dist/client/index.html")));
}
const port = parseInt(process.env.PORT || "5000");
httpServer.listen(port, "0.0.0.0", () => console.log(`Server running on port ${port}`));
EOF

    # Routes
    cat > server/routes.ts << 'EOF'
import type { Express } from "express";
import type { Server } from "http";
import { generateStrudelCode } from "./openai.js";

const snippets = new Map();

export async function registerRoutes(httpServer: Server, app: Express): Promise<Server> {
  app.post("/api/generate", async (req, res) => {
    try {
      const { prompt } = req.body;
      if (!prompt || prompt.length > 500) return res.status(400).json({ error: "Invalid prompt", success: false });
      const code = await generateStrudelCode(prompt);
      res.json({ code, success: true });
    } catch (error) {
      res.status(500).json({ error: "Failed to generate code", success: false });
    }
  });
  app.get("/api/snippets", (req, res) => res.json({ snippets: Array.from(snippets.values()), success: true }));
  app.post("/api/snippets", (req, res) => {
    const { name, code, category } = req.body;
    if (!name || !code) return res.status(400).json({ error: "Name and code required", success: false });
    const id = Math.random().toString(36).substr(2, 9);
    const snippet = { id, name, code, category };
    snippets.set(id, snippet);
    res.json({ snippet, success: true });
  });
  return httpServer;
}
EOF

    # OpenAI
    cat > server/openai.ts << 'OPENAIEOF'
import OpenAI from "openai";

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

const SYSTEM_PROMPT = `You are a Strudel live coding expert. Convert natural language to valid Strudel code.
Strudel basics: s("bd sd") - drums, note("c4 e4 g4") - notes, sound("sawtooth") - synth
.gain(0.5) - volume, .lpf(500) - filter, .room(0.5) - reverb, stack(p1, p2) - layer
.fast(2) / .slow(2) - tempo. Output ONLY valid Strudel code with brief comments.`;

export async function generateStrudelCode(prompt: string): Promise<string> {
  const response = await openai.chat.completions.create({
    model: "gpt-4o",
    messages: [
      { role: "system", content: SYSTEM_PROMPT },
      { role: "user", content: `Generate Strudel code for: ${prompt}` }
    ],
    max_tokens: 1024,
  });
  const content = response.choices[0]?.message?.content || "";
  const match = content.match(/```(?:javascript|js)?\n?([\s\S]*?)```/);
  return match ? match[1].trim() : content.trim();
}
OPENAIEOF

    # Schema
    cat > shared/schema.ts << 'EOF'
import { z } from "zod";
export interface Snippet { id: string; name: string; code: string; category?: string; }
export const insertSnippetSchema = z.object({
  name: z.string().min(1).max(100),
  code: z.string().min(1).max(10000),
  category: z.string().max(50).optional(),
});
EOF

    # HTML
    cat > client/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SAIC - Strudel AI Music Generator</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
</head>
<body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body>
</html>
EOF

    # Main
    cat > client/src/main.tsx << 'EOF'
import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";
createRoot(document.getElementById("root")!).render(<App />);
EOF

    # CSS
    cat > client/src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
:root {
  --background: 240 10% 3.9%;
  --foreground: 0 0% 98%;
  --card: 240 10% 3.9%;
  --card-foreground: 0 0% 98%;
  --primary: 263 70% 50%;
  --primary-foreground: 0 0% 98%;
  --secondary: 160 84% 39%;
  --secondary-foreground: 0 0% 98%;
  --muted: 240 3.7% 15.9%;
  --muted-foreground: 240 5% 64.9%;
  --border: 240 3.7% 15.9%;
  --input: 240 3.7% 15.9%;
  --ring: 263 70% 50%;
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: 'Inter', sans-serif; background: hsl(var(--background)); color: hsl(var(--foreground)); min-height: 100vh; }
.font-mono { font-family: 'JetBrains Mono', monospace; }
EOF

    # App
    cat > client/src/App.tsx << 'EOF'
import { Switch, Route, Link, useLocation } from "wouter";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import SimplePage from "./pages/SimplePage";
import DJPage from "./pages/DJPage";

const queryClient = new QueryClient();

function Header() {
  const [location] = useLocation();
  return (
    <header className="bg-[hsl(var(--card))] border-b border-[hsl(var(--border))] p-4">
      <div className="flex items-center justify-between max-w-6xl mx-auto gap-4">
        <h1 className="text-xl font-bold text-[hsl(var(--primary))]">SAIC</h1>
        <nav className="flex gap-2">
          <Link href="/"><button className={`px-4 py-2 rounded-md text-sm font-medium ${location === "/" ? "bg-[hsl(var(--primary))] text-white" : "bg-[hsl(var(--muted))]"}`}>Simple</button></Link>
          <Link href="/dj"><button className={`px-4 py-2 rounded-md text-sm font-medium ${location === "/dj" ? "bg-[hsl(var(--primary))] text-white" : "bg-[hsl(var(--muted))]"}`}>DJ Mode</button></Link>
        </nav>
      </div>
    </header>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <div className="min-h-screen flex flex-col">
        <Header />
        <main className="flex-1">
          <Switch>
            <Route path="/" component={SimplePage} />
            <Route path="/dj" component={DJPage} />
          </Switch>
        </main>
      </div>
    </QueryClientProvider>
  );
}
EOF

    # SimplePage
    cat > client/src/pages/SimplePage.tsx << 'EOF'
import { useState } from "react";

const PATTERNS = {
  beats: [{ name: "4/4 Kick", code: 's("bd bd bd bd")' }, { name: "Basic Beat", code: 's("bd sd bd sd")' }, { name: "Hi-hat", code: 's("hh*8").gain(0.4)' }],
  bass: [{ name: "Sub Bass", code: 'note("c1 c1 g1 c1").sound("sawtooth").lpf(200)' }],
  synth: [{ name: "Pad", code: 'note("c4 e4 g4 b4").sound("sine").gain(0.3)' }],
};

export default function SimplePage() {
  const [code, setCode] = useState('s("bd sd bd sd")');
  const [prompt, setPrompt] = useState("");
  const [isPlaying, setIsPlaying] = useState(false);
  const [isGenerating, setIsGenerating] = useState(false);

  const generateCode = async () => {
    if (!prompt.trim()) return;
    setIsGenerating(true);
    try {
      const res = await fetch("/api/generate", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ prompt }) });
      const data = await res.json();
      if (data.success) setCode(data.code);
    } catch (e) { console.error(e); }
    setIsGenerating(false);
  };

  return (
    <div className="max-w-4xl mx-auto p-4 space-y-4">
      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))]">
        <div className="flex gap-2">
          <input type="text" value={prompt} onChange={(e) => setPrompt(e.target.value)} placeholder="Describe the music you want..." className="flex-1 bg-[hsl(var(--input))] border border-[hsl(var(--border))] rounded-md px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[hsl(var(--primary))]" onKeyDown={(e) => e.key === "Enter" && generateCode()} />
          <button onClick={generateCode} disabled={isGenerating} className="bg-[hsl(var(--primary))] text-white px-6 py-3 rounded-md font-medium disabled:opacity-50">{isGenerating ? "..." : "Generate"}</button>
        </div>
      </div>
      <div className="bg-[hsl(var(--card))] rounded-lg border border-[hsl(var(--border))] overflow-hidden">
        <div className="bg-[hsl(var(--muted))] px-4 py-2 text-sm text-[hsl(var(--muted-foreground))]">Code Editor</div>
        <textarea value={code} onChange={(e) => setCode(e.target.value)} className="w-full h-64 bg-transparent p-4 font-mono text-sm resize-none focus:outline-none" spellCheck={false} />
      </div>
      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))]">
        <button onClick={() => setIsPlaying(!isPlaying)} className={`p-4 rounded-full ${isPlaying ? "bg-red-500" : "bg-[hsl(var(--secondary))]"} text-white`}>{isPlaying ? "Stop" : "Play"}</button>
      </div>
      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))]">
        <h3 className="text-sm font-medium mb-3">Quick Insert</h3>
        <div className="space-y-3">
          {Object.entries(PATTERNS).map(([category, patterns]) => (
            <div key={category}>
              <div className="text-xs uppercase text-[hsl(var(--muted-foreground))] mb-2">{category}</div>
              <div className="flex flex-wrap gap-2">
                {patterns.map((p) => (<button key={p.name} onClick={() => setCode(prev => prev + "\n" + p.code)} className="px-3 py-1.5 bg-[hsl(var(--muted))] rounded text-sm">{p.name}</button>))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
EOF

    # DJPage
    cat > client/src/pages/DJPage.tsx << 'EOF'
import { useState } from "react";

export default function DJPage() {
  const [previewCode, setPreviewCode] = useState('s("bd sd bd sd")');
  const [masterCode, setMasterCode] = useState('s("hh*8").gain(0.3)');
  const [crossfader, setCrossfader] = useState(50);
  const [prompt, setPrompt] = useState("");
  const [isGenerating, setIsGenerating] = useState(false);
  const [targetChannel, setTargetChannel] = useState<"preview" | "master">("preview");

  const generateCode = async () => {
    if (!prompt.trim()) return;
    setIsGenerating(true);
    try {
      const res = await fetch("/api/generate", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ prompt }) });
      const data = await res.json();
      if (data.success) { if (targetChannel === "preview") setPreviewCode(data.code); else setMasterCode(data.code); }
    } catch (e) { console.error(e); }
    setIsGenerating(false);
  };

  return (
    <div className="max-w-6xl mx-auto p-4 space-y-4">
      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))]">
        <div className="flex gap-2 mb-3">
          <input type="text" value={prompt} onChange={(e) => setPrompt(e.target.value)} placeholder="Describe the music..." className="flex-1 bg-[hsl(var(--input))] border border-[hsl(var(--border))] rounded-md px-4 py-3 text-sm" onKeyDown={(e) => e.key === "Enter" && generateCode()} />
          <button onClick={generateCode} disabled={isGenerating} className="bg-[hsl(var(--primary))] text-white px-6 py-3 rounded-md font-medium disabled:opacity-50">{isGenerating ? "..." : "Generate"}</button>
        </div>
        <div className="flex gap-2">
          <button onClick={() => setTargetChannel("preview")} className={`px-3 py-1.5 rounded text-sm ${targetChannel === "preview" ? "bg-amber-500 text-white" : "bg-[hsl(var(--muted))]"}`}>Preview</button>
          <button onClick={() => setTargetChannel("master")} className={`px-3 py-1.5 rounded text-sm ${targetChannel === "master" ? "bg-[hsl(var(--secondary))] text-white" : "bg-[hsl(var(--muted))]"}`}>Master</button>
        </div>
      </div>
      <div className="grid md:grid-cols-2 gap-4">
        <div className="bg-[hsl(var(--card))] rounded-lg border border-amber-500/50 overflow-hidden">
          <div className="bg-amber-500/20 px-4 py-2 text-sm font-medium text-amber-500">Preview</div>
          <textarea value={previewCode} onChange={(e) => setPreviewCode(e.target.value)} className="w-full h-48 bg-transparent p-4 font-mono text-sm resize-none focus:outline-none" />
        </div>
        <div className="bg-[hsl(var(--card))] rounded-lg border border-[hsl(var(--secondary))]/50 overflow-hidden">
          <div className="bg-[hsl(var(--secondary))]/20 px-4 py-2 text-sm font-medium text-[hsl(var(--secondary))]">Master</div>
          <textarea value={masterCode} onChange={(e) => setMasterCode(e.target.value)} className="w-full h-48 bg-transparent p-4 font-mono text-sm resize-none focus:outline-none" />
        </div>
      </div>
      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))]">
        <button onClick={() => setMasterCode(previewCode)} className="bg-[hsl(var(--primary))] text-white px-4 py-2 rounded-md text-sm font-medium mb-4">Send Preview to Master</button>
        <div className="flex items-center gap-4">
          <span className="text-sm text-amber-500 font-medium">A</span>
          <input type="range" min="0" max="100" value={crossfader} onChange={(e) => setCrossfader(Number(e.target.value))} className="flex-1 h-3 bg-gradient-to-r from-amber-500 to-emerald-500 rounded-lg" />
          <span className="text-sm text-[hsl(var(--secondary))] font-medium">B</span>
        </div>
        <div className="text-center text-xs text-[hsl(var(--muted-foreground))] mt-2">Crossfader</div>
      </div>
    </div>
  );
}
EOF

    # Config files
    cat > tailwind.config.js << 'EOF'
export default { content: ["./client/index.html", "./client/src/**/*.{js,ts,jsx,tsx}"], theme: { extend: {} }, plugins: [] };
EOF

    cat > postcss.config.js << 'EOF'
export default { plugins: { tailwindcss: {}, autoprefixer: {} } };
EOF

    cat > vite.config.ts << 'EOF'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";
export default defineConfig({ plugins: [react()], root: "client", build: { outDir: "../dist/client", emptyOutDir: true }, resolve: { alias: { "@": path.resolve(__dirname, "client/src") } }, server: { proxy: { "/api": "http://localhost:5000" } } });
EOF

    cat > tsconfig.json << 'EOF'
{ "compilerOptions": { "target": "ES2020", "module": "ESNext", "moduleResolution": "bundler", "strict": true, "jsx": "react-jsx", "esModuleInterop": true, "skipLibCheck": true }, "include": ["client/src", "server", "shared"] }
EOF
}

build_app() {
    echo -e "${BLUE}[6/8] Installing npm packages...${NC}"
    npm install
    
    echo -e "${BLUE}[7/8] Building application...${NC}"
    npm run build
}

create_env() {
    cat > .env << EOF
OPENAI_API_KEY=$OPENAI_KEY
PORT=$APP_PORT
EOF

    if [ -n "$AUTH_USER" ]; then
        cat >> .env << EOF
AUTH_USER=$AUTH_USER
AUTH_PASS=$AUTH_PASS
EOF
    fi
    
    chmod 600 .env
}

configure_debian_nginx() {
    cat > /etc/nginx/sites-available/saic << EOF
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
    ln -sf /etc/nginx/sites-available/saic /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    nginx -t && systemctl reload nginx
    
    ufw allow ssh
    ufw allow 'Nginx Full'
    
    # Open port 8080 for Guacamole if installing Remote+MCP mode
    if [ "$INSTALL_GUACAMOLE" = true ]; then
        ufw allow 8080/tcp
        echo -e "${GREEN}  Opened port 8080 for Guacamole${NC}"
    fi
    
    ufw --force enable
}

configure_rocky_nginx() {
    setsebool -P httpd_can_network_connect 1
    
    cat > /etc/nginx/conf.d/saic.conf << EOF
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
    systemctl enable nginx
    systemctl start nginx
    nginx -t && systemctl reload nginx
    
    systemctl enable firewalld
    systemctl start firewalld
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --permanent --add-service=ssh
    
    # Open port 8080 for Guacamole if installing Remote+MCP mode
    if [ "$INSTALL_GUACAMOLE" = true ]; then
        firewall-cmd --permanent --add-port=8080/tcp
        echo -e "${GREEN}  Opened port 8080 for Guacamole${NC}"
    fi
    
    firewall-cmd --reload
}

start_pm2() {
    echo -e "${BLUE}[8/8] Starting application with PM2...${NC}"
    
    # Create PM2 ecosystem file to load environment variables
    cat > ecosystem.config.cjs << PMEOF
module.exports = {
  apps: [{
    name: 'saic',
    script: 'npm',
    args: 'start',
    cwd: '/opt/SAIC',
    env: {
      NODE_ENV: 'production',
      OPENAI_API_KEY: '${OPENAI_KEY}',
      PORT: '${APP_PORT}',
      AUTH_USER: '${AUTH_USER:-}',
      AUTH_PASS: '${AUTH_PASS:-}'
    }
  }]
};
PMEOF
    
    pm2 start ecosystem.config.cjs
    pm2 save
    pm2 startup
}

# =============================================
# MAIN INSTALLATION
# =============================================

echo ""
echo -e "${GREEN}Starting installation...${NC}"
echo ""

# Install OS-specific dependencies
if [ "$DETECTED_OS" == "debian" ]; then
    install_debian_deps
else
    install_rocky_deps
fi

install_pm2

# Clone or create embedded
if [ "$INSTALL_METHOD" == "1" ]; then
    clone_repo
else
    create_embedded_app
fi

create_env
build_app

# Configure nginx
if [ "$DETECTED_OS" == "debian" ]; then
    configure_debian_nginx
else
    configure_rocky_nginx
fi

# Configure fail2ban security
configure_fail2ban

start_pm2

# =============================================
# GUACAMOLE + MCP SERVER (Option 3 only)
# =============================================
if [ "$INSTALL_GUACAMOLE" = true ]; then
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          INSTALLING REMOTE DESKTOP + MCP SERVER            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Install Guacamole
    if [ "$DETECTED_OS" == "debian" ]; then
        install_guacamole_debian
    else
        install_guacamole_rocky
    fi
    
    # Install Strudel MCP Server and VNC desktop
    install_strudel_mcp_server
    
    # Configure Guacamole connection to VNC
    configure_guacamole_connection
    
    echo ""
    echo -e "${GREEN}Remote Desktop + MCP Server installation complete!${NC}"
fi

# Get IP and domain
SERVER_IP=$(hostname -I | awk '{print $1}')
SERVER_HOSTNAME=$(hostname -f 2>/dev/null || hostname)
SERVER_DOMAIN=""

# Try to detect domain from reverse DNS
if command -v dig &> /dev/null; then
    SERVER_DOMAIN=$(dig +short -x "$SERVER_IP" 2>/dev/null | sed 's/\.$//')
fi

# Fallback to hostname if it looks like a domain
if [ -z "$SERVER_DOMAIN" ] && [[ "$SERVER_HOSTNAME" == *.* ]]; then
    SERVER_DOMAIN="$SERVER_HOSTNAME"
fi

echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              INSTALLATION COMPLETE!                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${CYAN}=== Server Info ===${NC}"
echo -e "  IP Address:   ${GREEN}$SERVER_IP${NC}"
echo -e "  Hostname:     ${GREEN}$SERVER_HOSTNAME${NC}"
if [ -n "$SERVER_DOMAIN" ]; then
    echo -e "  Domain:       ${GREEN}$SERVER_DOMAIN${NC}"
fi
echo -e "  App URL:      ${GREEN}http://$SERVER_IP${NC}"
echo ""

# Guacamole-specific info for Option 3
if [ "$INSTALL_GUACAMOLE" = true ]; then
    VNC_PASS=$(cat /opt/SAIC/.vnc_password 2>/dev/null || echo "unknown")
    echo -e "${CYAN}=== Remote Desktop (Guacamole) ===${NC}"
    echo -e "  Guacamole URL:     ${GREEN}http://$SERVER_IP:8080/guacamole${NC}"
    echo -e "  Admin Login:       ${GREEN}guacadmin / guacadmin${NC}"
    echo -e "  ${RED}SECURITY: Change this password immediately after first login!${NC}"
    echo ""
    echo -e "${CYAN}=== Strudel MCP Server ===${NC}"
    echo -e "  Desktop User:      ${GREEN}saic${NC}"
    echo -e "  Desktop Password:  ${GREEN}${VNC_PASS}${NC}"
    echo -e "  VNC Display:       ${GREEN}:1 (port 5901)${NC}"
    echo ""
    echo -e "${CYAN}=== How to Use (FREE - No API Keys!) ===${NC}"
    echo -e "  1. Open ${GREEN}http://$SERVER_IP:8080/guacamole${NC}"
    echo -e "  2. Login with ${GREEN}guacadmin / guacadmin${NC}"
    echo -e "  3. Click on ${GREEN}'Strudel Desktop'${NC} connection"
    echo -e "  4. Open browser in desktop, go to ${GREEN}strudel.cc${NC}"
    echo -e "  5. Install ${GREEN}Claude Desktop${NC} and use MCP to generate music!"
    echo ""
    echo -e "${YELLOW}=== Claude Desktop Setup ===${NC}"
    echo -e "  MCP config is pre-installed at:"
    echo -e "  ${GREEN}/home/saic/.config/Claude/claude_desktop_config.json${NC}"
    echo -e "  Just install Claude Desktop and it will auto-detect Strudel MCP!"
    echo ""
fi

if [ -n "$AUTH_USER" ]; then
    echo -e "${CYAN}=== App Login Credentials ===${NC}"
    echo -e "  Username:     ${GREEN}$AUTH_USER${NC}"
    echo -e "  Password:     ${GREEN}********${NC}"
    echo ""
fi

echo -e "${CYAN}=== Useful Commands ===${NC}"
echo -e "  ${YELLOW}saic-status${NC}         - Check app, nginx, services status"
echo -e "  ${YELLOW}saic-logs${NC}           - View live application logs"
echo -e "  ${YELLOW}saic-stats${NC}          - CPU, memory, disk usage overview"
echo -e "  ${YELLOW}saic-security${NC}       - Firewall status, banned IPs, failed logins"
echo -e "  ${YELLOW}saic-passwd${NC}         - Change/reset password protection"
echo -e "  ${YELLOW}saic-ssl${NC}            - Setup SSL certificate"
echo -e "  ${YELLOW}saic-users${NC}          - List web access users"
echo -e "  ${YELLOW}saic-adduser${NC}        - Add a new web access user"
echo -e "  ${YELLOW}saic-deluser${NC}        - Remove a web access user"
echo ""
echo -e "${CYAN}=== PM2 Commands ===${NC}"
echo -e "  ${YELLOW}pm2 logs saic${NC}       - View raw application logs"
echo -e "  ${YELLOW}pm2 restart saic${NC}    - Restart application"
echo -e "  ${YELLOW}pm2 monit${NC}           - Real-time monitoring dashboard"
echo ""

# Create SSL setup script for later use
cat > /usr/local/bin/saic-ssl << 'SSLEOF'
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== SAIC SSL Certificate Setup ===${NC}"
echo ""

# Detect OS
if [ -f /etc/debian_version ]; then
    OS_TYPE="debian"
elif [ -f /etc/redhat-release ]; then
    OS_TYPE="rocky"
else
    echo -e "${RED}Unsupported OS${NC}"
    exit 1
fi

# Get domain
SERVER_IP=$(hostname -I | awk '{print $1}')
DETECTED_DOMAIN=$(dig +short -x "$SERVER_IP" 2>/dev/null | sed 's/\.$//')
if [ -z "$DETECTED_DOMAIN" ]; then
    DETECTED_DOMAIN=$(hostname -f 2>/dev/null)
fi

echo -e "Detected domain: ${GREEN}${DETECTED_DOMAIN:-'none'}${NC}"
echo ""
read -p "Enter domain for SSL certificate [$DETECTED_DOMAIN]: " USER_DOMAIN </dev/tty
DOMAIN=${USER_DOMAIN:-$DETECTED_DOMAIN}

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Domain is required for SSL!${NC}"
    exit 1
fi

echo ""
echo -e "Installing certbot..."
if [ "$OS_TYPE" == "debian" ]; then
    apt install -y certbot python3-certbot-nginx
else
    dnf install -y certbot python3-certbot-nginx
fi

echo ""
echo -e "Requesting SSL certificate for: ${GREEN}$DOMAIN${NC}"
certbot --nginx -d "$DOMAIN"

echo ""
echo -e "${GREEN}SSL setup complete!${NC}"
echo -e "Your app is now available at: ${CYAN}https://$DOMAIN${NC}"
SSLEOF
chmod +x /usr/local/bin/saic-ssl

# Create password management script
cat > /usr/local/bin/saic-passwd << 'PWEOF'
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ENV_FILE="/opt/SAIC/.env"

echo -e "${CYAN}=== SAIC Password Management ===${NC}"
echo ""

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: SAIC not found at /opt/SAIC${NC}"
    exit 1
fi

# Check current status
if grep -q "AUTH_USER" "$ENV_FILE" 2>/dev/null; then
    CURRENT_USER=$(grep "AUTH_USER=" "$ENV_FILE" | cut -d'=' -f2)
    echo -e "Status: ${GREEN}Password protection ENABLED${NC}"
    echo -e "Current username: ${CYAN}$CURRENT_USER${NC}"
else
    echo -e "Status: ${YELLOW}Password protection DISABLED${NC}"
fi

echo ""
echo "Options:"
echo "  1) Set/Change password"
echo "  2) Remove password protection"
echo "  3) Cancel"
echo ""
read -p "Choose option [1-3]: " CHOICE </dev/tty

case $CHOICE in
    1)
        echo ""
        read -p "Enter username: " NEW_USER </dev/tty
        read -s -p "Enter password: " NEW_PASS </dev/tty
        echo ""
        read -s -p "Confirm password: " CONFIRM_PASS </dev/tty
        echo ""
        
        if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
            echo -e "${RED}Passwords do not match!${NC}"
            exit 1
        fi
        
        if [ -z "$NEW_USER" ] || [ -z "$NEW_PASS" ]; then
            echo -e "${RED}Username and password cannot be empty!${NC}"
            exit 1
        fi
        
        # Remove existing auth lines
        sed -i '/AUTH_USER/d' "$ENV_FILE"
        sed -i '/AUTH_PASS/d' "$ENV_FILE"
        
        # Add new credentials
        echo "AUTH_USER=$NEW_USER" >> "$ENV_FILE"
        echo "AUTH_PASS=$NEW_PASS" >> "$ENV_FILE"
        
        echo ""
        echo -e "${GREEN}Password updated! Restarting app...${NC}"
        pm2 restart saic
        echo -e "${GREEN}Done!${NC}"
        ;;
    2)
        echo ""
        read -p "Are you sure you want to remove password protection? (y/N): " CONFIRM </dev/tty
        if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
            sed -i '/AUTH_USER/d' "$ENV_FILE"
            sed -i '/AUTH_PASS/d' "$ENV_FILE"
            echo ""
            echo -e "${GREEN}Password protection removed! Restarting app...${NC}"
            pm2 restart saic
            echo -e "${GREEN}Done!${NC}"
        else
            echo "Cancelled."
        fi
        ;;
    *)
        echo "Cancelled."
        ;;
esac
PWEOF
chmod +x /usr/local/bin/saic-passwd

# Create saic-status helper script
cat > /usr/local/bin/saic-status << 'STATUSEOF'
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    SAIC STATUS CHECK                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}=== System Info ===${NC}"
echo -e "  Hostname:     $(hostname)"
echo -e "  IP Address:   $(hostname -I | awk '{print $1}')"
echo -e "  Uptime:       $(uptime -p 2>/dev/null || uptime)"
echo ""

echo -e "${CYAN}=== Services Status ===${NC}"
check_service() {
    local name=$1
    local service=$2
    if systemctl is-active --quiet $service 2>/dev/null; then
        echo -e "  $name: ${GREEN}[RUNNING]${NC}"
    else
        echo -e "  $name: ${RED}[STOPPED]${NC}"
    fi
}

check_service "Nginx" "nginx"
check_service "fail2ban" "fail2ban"
echo ""

echo -e "${CYAN}=== PM2 Application ===${NC}"
if command -v pm2 &> /dev/null; then
    pm2 list 2>/dev/null | grep -E "Name|saic" || echo -e "  ${YELLOW}No PM2 processes found${NC}"
else
    echo -e "  ${YELLOW}PM2 not installed${NC}"
fi
echo ""

echo -e "${CYAN}=== Open Ports ===${NC}"
ss -tlnp 2>/dev/null | grep -E "LISTEN.*:(80|443|5000|8080)" | while read line; do
    port=$(echo $line | grep -oP ':\K\d+(?=\s)')
    echo -e "  Port $port: ${GREEN}[LISTENING]${NC}"
done
echo ""
STATUSEOF
chmod +x /usr/local/bin/saic-status

# Create saic-logs helper script
cat > /usr/local/bin/saic-logs << 'LOGSEOF'
#!/bin/bash
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}=== SAIC Log Viewer ===${NC}"
echo ""
echo "Select log to view:"
echo "  1) PM2 Application Logs (live)"
echo "  2) Nginx Access Log (last 50 lines)"
echo "  3) Nginx Error Log (last 50 lines)"
echo "  4) fail2ban Log (last 50 lines)"
echo "  5) System Auth Log (last 50 lines)"
echo ""
read -p "Enter choice [1-5]: " CHOICE

case $CHOICE in
    1) echo -e "${GREEN}Showing PM2 logs (Ctrl+C to exit)...${NC}"; pm2 logs saic ;;
    2) echo -e "${GREEN}Nginx Access Log:${NC}"; tail -50 /var/log/nginx/access.log 2>/dev/null || echo "Log not found" ;;
    3) echo -e "${GREEN}Nginx Error Log:${NC}"; tail -50 /var/log/nginx/error.log 2>/dev/null || echo "Log not found" ;;
    4) echo -e "${GREEN}fail2ban Log:${NC}"; tail -50 /var/log/fail2ban.log 2>/dev/null || echo "Log not found" ;;
    5) if [ -f /var/log/auth.log ]; then tail -50 /var/log/auth.log; elif [ -f /var/log/secure ]; then tail -50 /var/log/secure; else echo "Log not found"; fi ;;
    *) echo "Invalid choice" ;;
esac
LOGSEOF
chmod +x /usr/local/bin/saic-logs

# Create saic-stats helper script
cat > /usr/local/bin/saic-stats << 'STATSEOF'
#!/bin/bash
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    SAIC SERVER STATS                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}=== CPU Usage ===${NC}"
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
echo -e "  Usage:       ${GREEN}${cpu_usage}%${NC}"
echo -e "  Load Avg:    $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo ""

echo -e "${CYAN}=== Memory Usage ===${NC}"
mem_info=$(free -h | grep Mem)
echo -e "  Total:       $(echo $mem_info | awk '{print $2}')"
echo -e "  Used:        ${GREEN}$(echo $mem_info | awk '{print $3}')${NC}"
echo -e "  Free:        $(echo $mem_info | awk '{print $4}')"
echo ""

echo -e "${CYAN}=== Disk Usage ===${NC}"
df -h / | tail -1 | awk '{printf "  Total:       %s\n  Used:        \033[0;32m%s (%s)\033[0m\n  Free:        %s\n", $2, $3, $5, $4}'
echo ""

echo -e "${CYAN}=== Network Connections ===${NC}"
active_conn=$(ss -tun | grep ESTAB | wc -l)
echo -e "  Active:      ${GREEN}${active_conn}${NC} established connections"
echo ""

echo -e "${YELLOW}Tip: Run 'htop' for interactive monitoring${NC}"
echo ""
STATSEOF
chmod +x /usr/local/bin/saic-stats

# Create saic-security helper script
cat > /usr/local/bin/saic-security << 'SECEOF'
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                 SAIC SECURITY STATUS                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}=== Firewall Status ===${NC}"
if command -v ufw &> /dev/null; then
    ufw_status=$(ufw status 2>/dev/null | head -1)
    if echo "$ufw_status" | grep -q "active"; then
        echo -e "  UFW:         ${GREEN}[ACTIVE]${NC}"
        ufw status | grep -E "ALLOW" | while read line; do echo "    $line"; done
    else
        echo -e "  UFW:         ${RED}[INACTIVE]${NC}"
    fi
elif command -v firewall-cmd &> /dev/null; then
    if systemctl is-active --quiet firewalld; then
        echo -e "  firewalld:   ${GREEN}[ACTIVE]${NC}"
    else
        echo -e "  firewalld:   ${RED}[INACTIVE]${NC}"
    fi
fi
echo ""

echo -e "${CYAN}=== fail2ban Status ===${NC}"
if systemctl is-active --quiet fail2ban 2>/dev/null; then
    echo -e "  Status:      ${GREEN}[ACTIVE]${NC}"
    jails=$(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2 | tr ',' '\n')
    for jail in $jails; do
        jail=$(echo $jail | xargs)
        if [ -n "$jail" ]; then
            banned=$(fail2ban-client status $jail 2>/dev/null | grep "Currently banned" | awk '{print $NF}')
            echo -e "    $jail: ${GREEN}${banned}${NC} banned"
        fi
    done
else
    echo -e "  Status:      ${RED}[INACTIVE]${NC}"
fi
echo ""

echo -e "${CYAN}=== Recent Failed Logins (last 5) ===${NC}"
if [ -f /var/log/auth.log ]; then
    grep -i "failed" /var/log/auth.log 2>/dev/null | tail -5 | while read line; do echo "  $line"; done
elif [ -f /var/log/secure ]; then
    grep -i "failed" /var/log/secure 2>/dev/null | tail -5 | while read line; do echo "  $line"; done
fi
echo ""

echo -e "${YELLOW}=== Security Tips ===${NC}"
echo "  - Run 'saic-ssl' to enable HTTPS"
echo "  - Run 'saic-passwd' to set password protection"
echo ""
SECEOF
chmod +x /usr/local/bin/saic-security

# Create saic-users helper script
cat > /usr/local/bin/saic-users << 'USERSEOF'
#!/bin/bash
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

ENV_FILE="/opt/SAIC/.env"

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                 SAIC WEB ACCESS USERS                      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}No configuration found at $ENV_FILE${NC}"
    exit 1
fi

if grep -q "AUTH_USER" "$ENV_FILE" 2>/dev/null; then
    CURRENT_USER=$(grep "AUTH_USER=" "$ENV_FILE" | cut -d'=' -f2)
    echo -e "${CYAN}=== Configured Users ===${NC}"
    echo -e "  ${GREEN}$CURRENT_USER${NC} (web access)"
else
    echo -e "${YELLOW}No web access users configured.${NC}"
    echo -e "Run ${CYAN}saic-adduser${NC} to add a user."
fi
echo ""
USERSEOF
chmod +x /usr/local/bin/saic-users

# Create saic-adduser helper script
cat > /usr/local/bin/saic-adduser << 'ADDUSEREOF'
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

ENV_FILE="/opt/SAIC/.env"

echo -e "${CYAN}=== Add SAIC Web Access User ===${NC}"
echo ""

if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
    chmod 600 "$ENV_FILE"
fi

read -p "Enter username: " NEW_USER </dev/tty
read -s -p "Enter password: " NEW_PASS </dev/tty
echo ""
read -s -p "Confirm password: " CONFIRM_PASS </dev/tty
echo ""

if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
    echo -e "${RED}Passwords do not match!${NC}"
    exit 1
fi

if [ -z "$NEW_USER" ] || [ -z "$NEW_PASS" ]; then
    echo -e "${RED}Username and password cannot be empty!${NC}"
    exit 1
fi

# Remove existing auth lines
sed -i '/AUTH_USER/d' "$ENV_FILE"
sed -i '/AUTH_PASS/d' "$ENV_FILE"

# Add new credentials
echo "AUTH_USER=$NEW_USER" >> "$ENV_FILE"
echo "AUTH_PASS=$NEW_PASS" >> "$ENV_FILE"

echo ""
echo -e "${GREEN}User '$NEW_USER' added! Restarting app...${NC}"
pm2 restart saic
echo -e "${GREEN}Done!${NC}"
ADDUSEREOF
chmod +x /usr/local/bin/saic-adduser

# Create saic-deluser helper script
cat > /usr/local/bin/saic-deluser << 'DELUSEREOF'
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ENV_FILE="/opt/SAIC/.env"

echo -e "${CYAN}=== Remove SAIC Web Access User ===${NC}"
echo ""

if ! grep -q "AUTH_USER" "$ENV_FILE" 2>/dev/null; then
    echo -e "${YELLOW}No web access user configured.${NC}"
    exit 0
fi

CURRENT_USER=$(grep "AUTH_USER=" "$ENV_FILE" | cut -d'=' -f2)
echo -e "Current user: ${GREEN}$CURRENT_USER${NC}"
echo ""
read -p "Remove this user and disable password protection? (y/N): " CONFIRM </dev/tty

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    sed -i '/AUTH_USER/d' "$ENV_FILE"
    sed -i '/AUTH_PASS/d' "$ENV_FILE"
    echo ""
    echo -e "${GREEN}User removed! Restarting app...${NC}"
    pm2 restart saic
    echo -e "${GREEN}Done! Password protection is now disabled.${NC}"
else
    echo "Cancelled."
fi
DELUSEREOF
chmod +x /usr/local/bin/saic-deluser

# Create MOTD login banner with security info
cat > /usr/local/bin/saic-motd << 'MOTDEOF'
#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Detect auth log path
if [ -f /var/log/auth.log ]; then
    AUTH_LOG="/var/log/auth.log"
elif [ -f /var/log/secure ]; then
    AUTH_LOG="/var/log/secure"
else
    AUTH_LOG=""
fi

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            SAIC - Strudel AI Music Generator               ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# System info
echo -e "${CYAN}=== System ===${NC}"
echo -e "  Hostname:     $(hostname)"
echo -e "  IP:           $(hostname -I | awk '{print $1}')"
echo -e "  Uptime:       $(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
echo ""

# Last 10 successful SSH logins (portable parsing without grep -P)
echo -e "${CYAN}=== Last 10 Successful SSH Logins ===${NC}"
if [ -n "$AUTH_LOG" ]; then
    grep -E "Accepted (password|publickey)" "$AUTH_LOG" 2>/dev/null | tail -10 | while read line; do
        timestamp=$(echo "$line" | awk '{print $1, $2, $3}')
        user=$(echo "$line" | sed -n 's/.*for \([^ ]*\).*/\1/p')
        ip=$(echo "$line" | sed -n 's/.*from \([0-9.]*\).*/\1/p')
        method=$(echo "$line" | sed -n 's/.*Accepted \([^ ]*\).*/\1/p')
        if [ -n "$user" ] && [ -n "$ip" ]; then
            printf "  ${GREEN}%-12s${NC} | %-15s | %-12s | %s\n" "$timestamp" "$user" "$ip" "$method"
        fi
    done
else
    echo -e "  ${YELLOW}Auth log not found${NC}"
fi
echo ""

# Last 10 successful web logins (from nginx access log)
if [ -f /var/log/nginx/access.log ]; then
    echo -e "${CYAN}=== Last 10 Web Access (200 OK) ===${NC}"
    grep " 200 " /var/log/nginx/access.log 2>/dev/null | tail -10 | while read line; do
        ip=$(echo "$line" | awk '{print $1}')
        timestamp=$(echo "$line" | sed -n 's/.*\[\([^]]*\)\].*/\1/p' | cut -c1-20)
        path=$(echo "$line" | awk '{print $7}' | cut -c1-30)
        if [ -n "$ip" ]; then
            printf "  %-15s | %-20s | %s\n" "$ip" "$timestamp" "$path"
        fi
    done
    echo ""
fi

# Top 5 IPs with failed logins (portable parsing)
echo -e "${CYAN}=== Top 5 IPs with Failed Logins ===${NC}"
if [ -n "$AUTH_LOG" ]; then
    grep -E "Failed|Invalid|authentication failure" "$AUTH_LOG" 2>/dev/null | \
        sed -n 's/.*from \([0-9.]*\).*/\1/p' | \
        sort | uniq -c | sort -rn | head -5 | while read count ip; do
            if [ -n "$ip" ]; then
                last_attempt=$(grep "$ip" "$AUTH_LOG" 2>/dev/null | grep -E "Failed|Invalid" | tail -1 | awk '{print $1, $2, $3}')
                printf "  ${RED}%-15s${NC} | %4d failed | Last: %s\n" "$ip" "$count" "$last_attempt"
            fi
        done
else
    echo -e "  ${YELLOW}Auth log not found${NC}"
fi
echo ""

# fail2ban status
if systemctl is-active --quiet fail2ban 2>/dev/null; then
    banned_total=0
    jails=$(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2 | tr ',' ' ')
    for jail in $jails; do
        jail=$(echo $jail | xargs)
        if [ -n "$jail" ]; then
            banned=$(fail2ban-client status $jail 2>/dev/null | grep "Currently banned" | awk '{print $NF}')
            banned_total=$((banned_total + banned))
        fi
    done
    echo -e "${CYAN}=== fail2ban ===${NC}"
    echo -e "  Currently banned IPs: ${RED}${banned_total}${NC}"
    echo ""
fi

echo -e "${YELLOW}Run 'saic-security' for detailed security info${NC}"
echo ""
MOTDEOF
chmod +x /usr/local/bin/saic-motd

# Add MOTD to shell profile
if ! grep -q "saic-motd" /etc/profile.d/saic.sh 2>/dev/null; then
    cat > /etc/profile.d/saic.sh << 'PROFILEEOF'
# SAIC Login Banner
if [ -x /usr/local/bin/saic-motd ] && [ -t 0 ]; then
    /usr/local/bin/saic-motd
fi
PROFILEEOF
    chmod +x /etc/profile.d/saic.sh
fi

# Ask about SSL setup
echo -e "${CYAN}=== SSL Certificate Setup ===${NC}"
echo ""
echo -e "${YELLOW}HTTPS is recommended for security.${NC}"
echo ""

if [ -n "$SERVER_DOMAIN" ]; then
    echo -e "Detected domain: ${GREEN}$SERVER_DOMAIN${NC}"
    read -p "Setup SSL certificate now for $SERVER_DOMAIN? (y/N): " SETUP_SSL </dev/tty
else
    echo -e "${YELLOW}No domain detected. You'll need a domain name for SSL.${NC}"
    read -p "Setup SSL certificate now? (y/N): " SETUP_SSL </dev/tty
fi

if [[ "$SETUP_SSL" =~ ^[Yy]$ ]]; then
    echo ""
    
    if [ -n "$SERVER_DOMAIN" ]; then
        read -p "Use detected domain '$SERVER_DOMAIN'? (Y/n): " USE_DETECTED_DOMAIN </dev/tty
        if [[ "$USE_DETECTED_DOMAIN" =~ ^[Nn]$ ]]; then
            read -p "Enter your domain: " SSL_DOMAIN </dev/tty
        else
            SSL_DOMAIN="$SERVER_DOMAIN"
        fi
    else
        read -p "Enter your domain: " SSL_DOMAIN </dev/tty
    fi
    
    if [ -n "$SSL_DOMAIN" ]; then
        echo ""
        echo -e "${BLUE}Installing certbot...${NC}"
        if [ "$DETECTED_OS" == "debian" ]; then
            apt install -y certbot python3-certbot-nginx
        else
            dnf install -y certbot python3-certbot-nginx
        fi
        
        echo ""
        echo -e "${BLUE}Requesting SSL certificate...${NC}"
        certbot --nginx -d "$SSL_DOMAIN"
        
        echo ""
        echo -e "${GREEN}SSL setup complete!${NC}"
        echo -e "Your app is now available at: ${CYAN}https://$SSL_DOMAIN${NC}"
    else
        echo -e "${YELLOW}Skipped - no domain provided.${NC}"
        echo -e "Run ${CYAN}saic-ssl${NC} later to setup SSL."
    fi
else
    echo ""
    echo -e "${YELLOW}Skipped SSL setup.${NC}"
    echo -e "Run ${CYAN}saic-ssl${NC} anytime to setup SSL certificate."
fi

echo ""
echo -e "${GREEN}Installation finished!${NC}"
echo ""
