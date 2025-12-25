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
echo -e "${CYAN}=== Step 2: OpenAI API Key (Required) ===${NC}"
echo ""
echo "Get your API key at: https://platform.openai.com/api-keys"
echo ""
read -p "Enter your OpenAI API key: " OPENAI_KEY </dev/tty
if [ -z "$OPENAI_KEY" ]; then
    echo -e "${RED}OpenAI API key is required!${NC}"
    exit 1
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
echo -e "  OS Type:      ${GREEN}$DETECTED_OS${NC}"
echo -e "  OpenAI Key:   ${GREEN}sk-****${OPENAI_KEY: -4}${NC}"
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
    apt install -y curl git nginx ufw build-essential
    
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
    dnf install -y curl git nginx firewalld epel-release
    
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

clone_repo() {
    echo -e "${BLUE}[5/8] Cloning repository...${NC}"
    mkdir -p /opt
    cd /opt
    if [ -d "SAIC" ]; then
        rm -rf SAIC
    fi
    git clone https://github.com/mdario971/SAIC.git
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

start_pm2

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

if [ -n "$AUTH_USER" ]; then
    echo -e "${CYAN}=== Login Credentials ===${NC}"
    echo -e "  Username:     ${GREEN}$AUTH_USER${NC}"
    echo -e "  Password:     ${GREEN}********${NC}"
    echo ""
fi

echo -e "${CYAN}=== Useful Commands ===${NC}"
echo -e "  ${YELLOW}pm2 logs saic${NC}       - View application logs"
echo -e "  ${YELLOW}pm2 restart saic${NC}    - Restart application"
echo -e "  ${YELLOW}pm2 stop saic${NC}       - Stop application"
echo -e "  ${YELLOW}pm2 status${NC}          - Check all processes"
echo -e "  ${YELLOW}pm2 monit${NC}           - Real-time monitoring"
echo -e "  ${YELLOW}saic-passwd${NC}         - Change/reset password protection"
echo -e "  ${YELLOW}saic-ssl${NC}            - Setup SSL certificate"
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
