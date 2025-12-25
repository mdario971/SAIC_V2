# SAIC - Deployment Scripts

Deployment scripts for **Debian 13** and **Rocky Linux 9**.

## Hardware Requirements

| Spec | Minimum | Recommended |
|------|---------|-------------|
| **RAM** | 512 MB | 1 GB |
| **CPU** | 1 vCPU | 1-2 vCPU |
| **Storage** | 10 GB SSD | 20 GB SSD |
| **Bandwidth** | 500 GB/mo | 1 TB/mo |

**Estimated Cost**: $4-6/month on Hetzner, Vultr, DigitalOcean, or Linode.

---

## Debian 13 Installation

### Option 1: Quick Install (requires GitHub repo)

```bash
curl -o install.sh https://raw.githubusercontent.com/mdario971/SAIC/main/deploy/install-debian.sh
chmod +x install.sh
sudo bash install.sh
```

### Option 2: Full Install (embedded code, no GitHub needed)

```bash
curl -o install.sh https://raw.githubusercontent.com/mdario971/SAIC/main/deploy/full-install-debian.sh
chmod +x install.sh
sudo bash install.sh
```

### Files

| File | Description |
|------|-------------|
| `install-debian.sh` | Quick install using git clone |
| `full-install-debian.sh` | Complete install with embedded code |
| `nginx-debian.conf` | Nginx configuration |

---

## Rocky Linux 9 Installation

### Option 1: Quick Install (requires GitHub repo)

```bash
curl -o install.sh https://raw.githubusercontent.com/mdario971/SAIC/main/deploy/install-rocky.sh
chmod +x install.sh
sudo bash install.sh
```

### Option 2: Full Install (embedded code, no GitHub needed)

```bash
curl -o install.sh https://raw.githubusercontent.com/mdario971/SAIC/main/deploy/full-install-rocky.sh
chmod +x install.sh
sudo bash install.sh
```

### Files

| File | Description |
|------|-------------|
| `install-rocky.sh` | Quick install using git clone |
| `full-install-rocky.sh` | Complete install with embedded code |
| `nginx-rocky.conf` | Nginx configuration |

---

## Key Differences Between Distros

| Feature | Debian 13 | Rocky Linux 9 |
|---------|-----------|---------------|
| Package Manager | `apt` | `dnf` |
| Firewall | `ufw` | `firewalld` |
| SELinux | Disabled | Enabled (requires setsebool) |
| Nginx Config | `/etc/nginx/sites-available/` | `/etc/nginx/conf.d/` |
| Node.js Repo | deb.nodesource.com | rpm.nodesource.com |

---

## Post-Installation

### Management Commands

```bash
# View logs
pm2 logs saic

# Restart application
pm2 restart saic

# Check status
pm2 status

# Stop application
pm2 stop saic

# Monitor resources
pm2 monit
```

### SSL Certificate (Both distros)

```bash
# Debian
apt install -y certbot python3-certbot-nginx

# Rocky Linux
dnf install -y certbot python3-certbot-nginx

# Get certificate (both)
certbot --nginx -d yourdomain.com
```

### Update Application

```bash
cd /opt/SAIC
git pull
npm install
npm run build
pm2 restart saic
```

---

## Troubleshooting

### Rocky Linux SELinux Issues

```bash
# Allow nginx to connect to network
setsebool -P httpd_can_network_connect 1

# Check SELinux status
getenforce

# Temporarily disable (not recommended for production)
setenforce 0
```

### Port Already in Use

```bash
# Find what's using port 5000
lsof -i :5000

# Kill the process
kill -9 <PID>
```

### Nginx Not Starting

```bash
# Test configuration
nginx -t

# Check logs - Debian
tail -f /var/log/nginx/error.log

# Check logs - Rocky
journalctl -u nginx -f
```

### Application Won't Start

```bash
# Check PM2 logs
pm2 logs saic --lines 50

# Check if .env file exists
cat /opt/SAIC/.env

# Verify Node.js version
node --version  # Should be v20.x
```

---

## Security: Password Protection

The app supports basic HTTP authentication. To enable it, add these to your `.env` file:

```bash
# /opt/SAIC/.env
OPENAI_API_KEY=sk-your-key-here
AUTH_USER=your-username
AUTH_PASS=your-secure-password
```

**Minimum Security Requirements:**
- Use a strong password (12+ characters, mix of letters/numbers/symbols)
- Always use HTTPS in production (install SSL certificate)
- Keep your `.env` file secure: `chmod 600 /opt/SAIC/.env`

If `AUTH_USER` and `AUTH_PASS` are not set, the app runs without password protection.

---

## OpenAI API Costs

Each AI generation request uses your OpenAI API key:

| Model | Input Cost | Output Cost |
|-------|------------|-------------|
| GPT-4o | $2.50/1M tokens | $10/1M tokens |

**Estimated costs:**
- Single generation: $0.001-0.005 (less than 1 cent)
- 100 generations/day: ~$0.10-0.50/day
- Heavy usage (500/day): ~$1-2/day

Monitor your usage at: https://platform.openai.com/usage

---

## Audio Streaming Setup (Optional)

For live audio streaming to online listeners:

### Debian

```bash
apt install -y icecast2
nano /etc/icecast2/icecast.xml
systemctl enable icecast2
systemctl start icecast2
ufw allow 8000/tcp
```

### Rocky Linux

```bash
dnf install -y icecast
nano /etc/icecast.xml
systemctl enable icecast
systemctl start icecast
firewall-cmd --permanent --add-port=8000/tcp
firewall-cmd --reload
```
