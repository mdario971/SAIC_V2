#!/bin/bash
# SAIC - Complete Rocky Linux 9 Installation Script
# This script installs EVERYTHING including all application code
# Run as root: sudo bash full-install-rocky.sh

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         SAIC - Rocky Linux 9 Full Installation Script      ║"
echo "╚════════════════════════════════════════════════════════════╝"

# Configuration
APP_DIR="/opt/SAIC"
APP_PORT="5000"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo bash full-install-rocky.sh"
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

# Prompt for authentication
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

echo "[1/10] Updating system..."
dnf update -y

echo "[2/10] Installing dependencies..."
dnf install -y curl git nginx firewalld epel-release

echo "[3/10] Installing Node.js 20..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
    dnf install -y nodejs
fi

echo "[4/10] Installing PM2..."
npm install -g pm2

echo "[5/10] Creating application directory..."
mkdir -p $APP_DIR
cd $APP_DIR

echo "[6/10] Creating package.json..."
cat > package.json << 'PKGJSON'
{
  "name": "saic",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "NODE_ENV=development tsx server/index.ts",
    "build": "vite build",
    "start": "NODE_ENV=production node dist/server/index.js"
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
PKGJSON

echo "[7/10] Creating all source files..."

mkdir -p client/src/pages server shared

# === AUTH MIDDLEWARE ===
cat > server/auth.ts << 'AUTHFILE'
import type { Request, Response, NextFunction } from "express";

export function basicAuth(req: Request, res: Response, next: NextFunction) {
  const authUser = process.env.AUTH_USER;
  const authPass = process.env.AUTH_PASS;

  if (!authUser || !authPass) {
    return next();
  }

  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Basic ")) {
    res.setHeader("WWW-Authenticate", 'Basic realm="SAIC"');
    return res.status(401).send("Authentication required");
  }

  const base64Credentials = authHeader.split(" ")[1];
  const credentials = Buffer.from(base64Credentials, "base64").toString("utf-8");
  const [username, password] = credentials.split(":");

  if (username === authUser && password === authPass) {
    return next();
  }

  res.setHeader("WWW-Authenticate", 'Basic realm="SAIC"');
  return res.status(401).send("Invalid credentials");
}
AUTHFILE

# === SERVER INDEX ===
cat > server/index.ts << 'SERVERINDEX'
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
  app.use(express.static(path.join(__dirname, "../client")));
  app.get("*", (req, res) => {
    res.sendFile(path.join(__dirname, "../client/index.html"));
  });
}

const port = parseInt(process.env.PORT || "5000");
httpServer.listen(port, "0.0.0.0", () => {
  console.log(`Server running on port ${port}`);
});
SERVERINDEX

cat > server/routes.ts << 'ROUTESFILE'
import type { Express } from "express";
import type { Server } from "http";
import { generateStrudelCode } from "./openai.js";
import { z } from "zod";

const snippets = new Map();

export async function registerRoutes(httpServer: Server, app: Express): Promise<Server> {
  app.post("/api/generate", async (req, res) => {
    try {
      const { prompt } = req.body;
      if (!prompt || prompt.length > 500) {
        return res.status(400).json({ error: "Invalid prompt", success: false });
      }
      const code = await generateStrudelCode(prompt);
      res.json({ code, success: true });
    } catch (error) {
      res.status(500).json({ error: "Failed to generate code", success: false });
    }
  });

  app.get("/api/snippets", (req, res) => {
    res.json({ snippets: Array.from(snippets.values()), success: true });
  });

  app.post("/api/snippets", (req, res) => {
    const { name, code, category } = req.body;
    if (!name || !code) {
      return res.status(400).json({ error: "Name and code required", success: false });
    }
    const id = Math.random().toString(36).substr(2, 9);
    const snippet = { id, name, code, category };
    snippets.set(id, snippet);
    res.json({ snippet, success: true });
  });

  return httpServer;
}
ROUTESFILE

cat > server/openai.ts << 'OPENAIFILE'
import OpenAI from "openai";

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

const SYSTEM_PROMPT = `You are a Strudel live coding expert. Convert natural language to valid Strudel code.

Strudel basics:
- s("bd sd") - drums (bd=kick, sd=snare, hh=hihat)
- note("c4 e4 g4") - notes
- sound("sawtooth") - synth
- .gain(0.5) - volume
- .lpf(500) - filter
- .room(0.5) - reverb
- stack(p1, p2) - layer patterns
- .fast(2) / .slow(2) - tempo

Output ONLY valid Strudel code with brief comments.`;

export async function generateStrudelCode(prompt: string): Promise<string> {
  const response = await openai.chat.completions.create({
    model: "gpt-4o",
    messages: [
      { role: "system", content: SYSTEM_PROMPT },
      { role: "user", content: \`Generate Strudel code for: \${prompt}\` }
    ],
    max_tokens: 1024,
  });

  const content = response.choices[0]?.message?.content || "";
  const match = content.match(/\\\`\\\`\\\`(?:javascript|js)?\\n?([\\s\\S]*?)\\\`\\\`\\\`/);
  return match ? match[1].trim() : content.trim();
}
OPENAIFILE

cat > shared/schema.ts << 'SCHEMAFILE'
import { z } from "zod";

export interface Snippet {
  id: string;
  name: string;
  code: string;
  category?: string;
}

export const insertSnippetSchema = z.object({
  name: z.string().min(1).max(100),
  code: z.string().min(1).max(10000),
  category: z.string().max(50).optional(),
});
SCHEMAFILE

cat > client/index.html << 'HTMLFILE'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SAIC - Strudel AI Music Generator</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
</head>
<body>
  <div id="root"></div>
  <script type="module" src="/src/main.tsx"></script>
</body>
</html>
HTMLFILE

cat > client/src/main.tsx << 'MAINFILE'
import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";

createRoot(document.getElementById("root")!).render(<App />);
MAINFILE

cat > client/src/index.css << 'CSSFILE'
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

body {
  font-family: 'Inter', sans-serif;
  background: hsl(var(--background));
  color: hsl(var(--foreground));
  min-height: 100vh;
}

.font-mono { font-family: 'JetBrains Mono', monospace; }
CSSFILE

cat > client/src/App.tsx << 'APPFILE'
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
          <Link href="/">
            <button className={`px-4 py-2 rounded-md text-sm font-medium ${
              location === "/" ? "bg-[hsl(var(--primary))] text-white" : "bg-[hsl(var(--muted))]"
            }`}>Simple</button>
          </Link>
          <Link href="/dj">
            <button className={`px-4 py-2 rounded-md text-sm font-medium ${
              location === "/dj" ? "bg-[hsl(var(--primary))] text-white" : "bg-[hsl(var(--muted))]"
            }`}>DJ Mode</button>
          </Link>
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
APPFILE

cat > client/src/pages/SimplePage.tsx << 'SIMPLEFILE'
import { useState } from "react";

const PATTERNS = {
  beats: [
    { name: "4/4 Kick", code: 's("bd bd bd bd")' },
    { name: "Basic Beat", code: 's("bd sd bd sd")' },
    { name: "Hi-hat", code: 's("hh*8").gain(0.4)' },
  ],
  bass: [
    { name: "Sub Bass", code: 'note("c1 c1 g1 c1").sound("sawtooth").lpf(200)' },
  ],
  synth: [
    { name: "Pad", code: 'note("c4 e4 g4 b4").sound("sine").gain(0.3)' },
  ],
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
      const res = await fetch("/api/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ prompt }),
      });
      const data = await res.json();
      if (data.success) setCode(data.code);
    } catch (e) {
      console.error(e);
    }
    setIsGenerating(false);
  };

  return (
    <div className="max-w-4xl mx-auto p-4 space-y-4">
      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))]">
        <div className="flex gap-2">
          <input
            type="text"
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="Describe the music you want..."
            className="flex-1 bg-[hsl(var(--input))] border border-[hsl(var(--border))] rounded-md px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[hsl(var(--primary))]"
            onKeyDown={(e) => e.key === "Enter" && generateCode()}
          />
          <button
            onClick={generateCode}
            disabled={isGenerating}
            className="bg-[hsl(var(--primary))] text-white px-6 py-3 rounded-md font-medium disabled:opacity-50"
          >
            {isGenerating ? "..." : "Generate"}
          </button>
        </div>
      </div>

      <div className="bg-[hsl(var(--card))] rounded-lg border border-[hsl(var(--border))] overflow-hidden">
        <div className="bg-[hsl(var(--muted))] px-4 py-2 text-sm text-[hsl(var(--muted-foreground))]">
          Code Editor
        </div>
        <textarea
          value={code}
          onChange={(e) => setCode(e.target.value)}
          className="w-full h-64 bg-transparent p-4 font-mono text-sm resize-none focus:outline-none"
          spellCheck={false}
        />
      </div>

      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))]">
        <button
          onClick={() => setIsPlaying(!isPlaying)}
          className={`p-4 rounded-full ${isPlaying ? "bg-red-500" : "bg-[hsl(var(--secondary))]"} text-white`}
        >
          {isPlaying ? "Stop" : "Play"}
        </button>
      </div>

      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))]">
        <h3 className="text-sm font-medium mb-3">Quick Insert</h3>
        <div className="space-y-3">
          {Object.entries(PATTERNS).map(([category, patterns]) => (
            <div key={category}>
              <div className="text-xs uppercase text-[hsl(var(--muted-foreground))] mb-2">{category}</div>
              <div className="flex flex-wrap gap-2">
                {patterns.map((p) => (
                  <button
                    key={p.name}
                    onClick={() => setCode(prev => prev + "\n" + p.code)}
                    className="px-3 py-1.5 bg-[hsl(var(--muted))] rounded text-sm"
                  >
                    {p.name}
                  </button>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
SIMPLEFILE

cat > client/src/pages/DJPage.tsx << 'DJFILE'
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
      const res = await fetch("/api/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ prompt }),
      });
      const data = await res.json();
      if (data.success) {
        if (targetChannel === "preview") setPreviewCode(data.code);
        else setMasterCode(data.code);
      }
    } catch (e) {
      console.error(e);
    }
    setIsGenerating(false);
  };

  return (
    <div className="max-w-6xl mx-auto p-4 space-y-4">
      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))]">
        <div className="flex gap-2 mb-3">
          <input
            type="text"
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="Describe the music..."
            className="flex-1 bg-[hsl(var(--input))] border border-[hsl(var(--border))] rounded-md px-4 py-3 text-sm"
            onKeyDown={(e) => e.key === "Enter" && generateCode()}
          />
          <button
            onClick={generateCode}
            disabled={isGenerating}
            className="bg-[hsl(var(--primary))] text-white px-6 py-3 rounded-md font-medium disabled:opacity-50"
          >
            {isGenerating ? "..." : "Generate"}
          </button>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setTargetChannel("preview")}
            className={`px-3 py-1.5 rounded text-sm ${targetChannel === "preview" ? "bg-amber-500 text-white" : "bg-[hsl(var(--muted))]"}`}
          >
            Preview
          </button>
          <button
            onClick={() => setTargetChannel("master")}
            className={`px-3 py-1.5 rounded text-sm ${targetChannel === "master" ? "bg-[hsl(var(--secondary))] text-white" : "bg-[hsl(var(--muted))]"}`}
          >
            Master
          </button>
        </div>
      </div>

      <div className="grid md:grid-cols-2 gap-4">
        <div className="bg-[hsl(var(--card))] rounded-lg border border-amber-500/50 overflow-hidden">
          <div className="bg-amber-500/20 px-4 py-2 text-sm font-medium text-amber-500">Preview</div>
          <textarea
            value={previewCode}
            onChange={(e) => setPreviewCode(e.target.value)}
            className="w-full h-48 bg-transparent p-4 font-mono text-sm resize-none focus:outline-none"
          />
        </div>

        <div className="bg-[hsl(var(--card))] rounded-lg border border-[hsl(var(--secondary))]/50 overflow-hidden">
          <div className="bg-[hsl(var(--secondary))]/20 px-4 py-2 text-sm font-medium text-[hsl(var(--secondary))]">Master</div>
          <textarea
            value={masterCode}
            onChange={(e) => setMasterCode(e.target.value)}
            className="w-full h-48 bg-transparent p-4 font-mono text-sm resize-none focus:outline-none"
          />
        </div>
      </div>

      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))]">
        <button
          onClick={() => setMasterCode(previewCode)}
          className="bg-[hsl(var(--primary))] text-white px-4 py-2 rounded-md text-sm font-medium mb-4"
        >
          Send Preview to Master
        </button>
        <div className="flex items-center gap-4">
          <span className="text-sm text-amber-500 font-medium">A</span>
          <input
            type="range"
            min="0"
            max="100"
            value={crossfader}
            onChange={(e) => setCrossfader(Number(e.target.value))}
            className="flex-1 h-3 bg-gradient-to-r from-amber-500 to-emerald-500 rounded-lg"
          />
          <span className="text-sm text-[hsl(var(--secondary))] font-medium">B</span>
        </div>
        <div className="text-center text-xs text-[hsl(var(--muted-foreground))] mt-2">Crossfader</div>
      </div>
    </div>
  );
}
DJFILE

cat > tailwind.config.js << 'TAILWINDCFG'
export default {
  content: ["./client/index.html", "./client/src/**/*.{js,ts,jsx,tsx}"],
  theme: { extend: {} },
  plugins: [],
};
TAILWINDCFG

cat > postcss.config.js << 'POSTCSSCFG'
export default { plugins: { tailwindcss: {}, autoprefixer: {} } };
POSTCSSCFG

cat > vite.config.ts << 'VITECFG'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  root: "client",
  build: { outDir: "../dist/client", emptyOutDir: true },
  resolve: { alias: { "@": path.resolve(__dirname, "client/src") } },
  server: { proxy: { "/api": "http://localhost:5000" } },
});
VITECFG

cat > tsconfig.json << 'TSCFG'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "jsx": "react-jsx",
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["client/src", "server", "shared"]
}
TSCFG

# Create .env file with all credentials
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

echo "[8/10] Installing npm packages..."
npm install

echo "[9/10] Building application..."
npm run build

echo "[10/10] Configuring Nginx and starting..."

# SELinux - allow nginx to connect to network
setsebool -P httpd_can_network_connect 1

cat > /etc/nginx/conf.d/saic.conf << 'NGINXCFG'
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
NGINXCFG

systemctl enable nginx
systemctl start nginx
nginx -t && systemctl reload nginx

systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

pm2 start npm --name "saic" -- start
pm2 save
pm2 startup

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              INSTALLATION COMPLETE!                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Your SAIC app is running at: http://$(hostname -I | awk '{print $1}')"
echo ""
if [ -n "$AUTH_USER" ]; then
    echo "Login: $AUTH_USER / (your password)"
fi
echo ""
echo "Commands: pm2 logs saic | pm2 restart saic | pm2 status"
echo ""
echo "For SSL: dnf install certbot python3-certbot-nginx && certbot --nginx"
