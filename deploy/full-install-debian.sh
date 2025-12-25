#!/bin/bash
# Strudel AI - Complete Debian 13 Installation Script
# This script installs EVERYTHING including all application code
# Run as root: sudo bash full-install.sh

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║    Strudel AI - Complete Debian 13 Installation Script     ║"
echo "╚════════════════════════════════════════════════════════════╝"

# Configuration
APP_DIR="/opt/strudel-ai"
APP_PORT="5000"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo bash full-install.sh"
    exit 1
fi

# Prompt for OpenAI API key
read -p "Enter your OpenAI API key: " OPENAI_KEY
if [ -z "$OPENAI_KEY" ]; then
    echo "OpenAI API key is required!"
    exit 1
fi

echo "[1/10] Updating system..."
apt update && apt upgrade -y

echo "[2/10] Installing dependencies..."
apt install -y curl git nginx ufw build-essential

echo "[3/10] Installing Node.js 20..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
fi

echo "[4/10] Installing PM2..."
npm install -g pm2

echo "[5/10] Creating application directory..."
mkdir -p $APP_DIR
cd $APP_DIR

echo "[6/10] Creating package.json..."
cat > package.json << 'PKGJSON'
{
  "name": "strudel-ai",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "NODE_ENV=development tsx server/index.ts",
    "build": "vite build",
    "start": "NODE_ENV=production node dist/server/index.js"
  },
  "dependencies": {
    "@hookform/resolvers": "^3.9.1",
    "@radix-ui/react-accordion": "^1.2.2",
    "@radix-ui/react-dialog": "^1.1.4",
    "@radix-ui/react-label": "^2.1.1",
    "@radix-ui/react-scroll-area": "^1.2.2",
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
    "framer-motion": "^11.15.0",
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

# Create directory structure
mkdir -p client/src/components client/src/pages client/src/hooks client/src/lib
mkdir -p server shared dist

# === SHARED SCHEMA ===
cat > shared/schema.ts << 'SCHEMAFILE'
import { z } from "zod";

export interface Snippet {
  id: string;
  name: string;
  code: string;
  category?: string;
}

export interface InsertSnippet {
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

# === SERVER FILES ===
cat > server/index.ts << 'SERVERINDEX'
import express from "express";
import { createServer } from "http";
import path from "path";
import { fileURLToPath } from "url";
import { registerRoutes } from "./routes.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
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
      { role: "user", content: `Generate Strudel code for: ${prompt}` }
    ],
    max_tokens: 1024,
  });

  const content = response.choices[0]?.message?.content || "";
  const match = content.match(/\`\`\`(?:javascript|js)?\n?([\s\S]*?)\`\`\`/);
  return match ? match[1].trim() : content.trim();
}
OPENAIFILE

# === CLIENT FILES ===
cat > client/index.html << 'HTMLFILE'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Strudel AI - Live Coding Music Generator</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
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
  --accent: 263 70% 50%;
  --accent-foreground: 0 0% 98%;
  --border: 240 3.7% 15.9%;
  --input: 240 3.7% 15.9%;
  --ring: 263 70% 50%;
  --radius: 0.5rem;
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
import { useState } from "react";
import SimplePage from "./pages/SimplePage";
import DJPage from "./pages/DJPage";

const queryClient = new QueryClient();

function Header() {
  const [location] = useLocation();
  return (
    <header className="bg-[hsl(var(--card))] border-b border-[hsl(var(--border))] p-4">
      <div className="flex items-center justify-between max-w-6xl mx-auto">
        <h1 className="text-xl font-bold text-[hsl(var(--primary))]">Strudel AI</h1>
        <nav className="flex gap-2">
          <Link href="/">
            <button className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              location === "/" ? "bg-[hsl(var(--primary))] text-white" : "bg-[hsl(var(--muted))] hover:bg-[hsl(var(--muted))]/80"
            }`}>Simple</button>
          </Link>
          <Link href="/dj">
            <button className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              location === "/dj" ? "bg-[hsl(var(--primary))] text-white" : "bg-[hsl(var(--muted))] hover:bg-[hsl(var(--muted))]/80"
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
import { Play, Square, Sparkles, ChevronDown, ChevronUp, Volume2 } from "lucide-react";

const PATTERNS = {
  beats: [
    { name: "4/4 Kick", code: 's("bd bd bd bd")' },
    { name: "Basic Beat", code: 's("bd sd bd sd")' },
    { name: "Hi-hat", code: 's("hh*8").gain(0.4)' },
  ],
  bass: [
    { name: "Sub Bass", code: 'note("c1 c1 g1 c1").sound("sawtooth").lpf(200)' },
    { name: "Acid", code: 'note("c2 c2 eb2 c2").sound("sawtooth").lpf(sine.range(200,2000))' },
  ],
  synth: [
    { name: "Pad", code: 'note("c4 e4 g4 b4").sound("sine").gain(0.3)' },
    { name: "Arp", code: 'note("c4 e4 g4 c5").fast(2).sound("triangle")' },
  ],
};

export default function SimplePage() {
  const [code, setCode] = useState('// Type your Strudel code here\ns("bd sd bd sd")');
  const [prompt, setPrompt] = useState("");
  const [isPlaying, setIsPlaying] = useState(false);
  const [isGenerating, setIsGenerating] = useState(false);
  const [showTutorial, setShowTutorial] = useState(false);
  const [volume, setVolume] = useState(70);

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

  const insertPattern = (patternCode: string) => {
    setCode(prev => prev + "\n" + patternCode);
  };

  return (
    <div className="max-w-4xl mx-auto p-4 space-y-4">
      {/* Prompt Input */}
      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))]">
        <div className="flex gap-2">
          <input
            type="text"
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="Describe the music you want... (e.g., 'chill lofi beat')"
            className="flex-1 bg-[hsl(var(--input))] border border-[hsl(var(--border))] rounded-md px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[hsl(var(--primary))]"
            onKeyDown={(e) => e.key === "Enter" && generateCode()}
          />
          <button
            onClick={generateCode}
            disabled={isGenerating}
            className="bg-[hsl(var(--primary))] hover:bg-[hsl(var(--primary))]/90 text-white px-6 py-3 rounded-md font-medium flex items-center gap-2 disabled:opacity-50"
          >
            <Sparkles className="w-4 h-4" />
            {isGenerating ? "Generating..." : "Generate"}
          </button>
        </div>
      </div>

      {/* Code Editor */}
      <div className="bg-[hsl(var(--card))] rounded-lg border border-[hsl(var(--border))] overflow-hidden">
        <div className="bg-[hsl(var(--muted))] px-4 py-2 text-sm text-[hsl(var(--muted-foreground))] border-b border-[hsl(var(--border))]">
          Code Editor
        </div>
        <textarea
          value={code}
          onChange={(e) => setCode(e.target.value)}
          className="w-full h-64 bg-transparent p-4 font-mono text-sm resize-none focus:outline-none"
          spellCheck={false}
        />
      </div>

      {/* Playback Controls */}
      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))] flex items-center gap-4">
        <button
          onClick={() => setIsPlaying(!isPlaying)}
          className={`p-4 rounded-full ${isPlaying ? "bg-red-500" : "bg-[hsl(var(--secondary))]"} text-white`}
        >
          {isPlaying ? <Square className="w-6 h-6" /> : <Play className="w-6 h-6" />}
        </button>
        <div className="flex items-center gap-2 flex-1">
          <Volume2 className="w-5 h-5 text-[hsl(var(--muted-foreground))]" />
          <input
            type="range"
            min="0"
            max="100"
            value={volume}
            onChange={(e) => setVolume(Number(e.target.value))}
            className="flex-1 h-2 bg-[hsl(var(--muted))] rounded-lg appearance-none cursor-pointer"
          />
          <span className="text-sm w-12 text-right">{volume}%</span>
        </div>
      </div>

      {/* Quick Insert Patterns */}
      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))]">
        <h3 className="text-sm font-medium mb-3 text-[hsl(var(--muted-foreground))]">Quick Insert</h3>
        <div className="space-y-3">
          {Object.entries(PATTERNS).map(([category, patterns]) => (
            <div key={category}>
              <div className="text-xs uppercase text-[hsl(var(--muted-foreground))] mb-2">{category}</div>
              <div className="flex flex-wrap gap-2">
                {patterns.map((p) => (
                  <button
                    key={p.name}
                    onClick={() => insertPattern(p.code)}
                    className="px-3 py-1.5 bg-[hsl(var(--muted))] hover:bg-[hsl(var(--muted))]/80 rounded text-sm"
                  >
                    {p.name}
                  </button>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Tutorial Panel */}
      <div className="bg-[hsl(var(--card))] rounded-lg border border-[hsl(var(--border))]">
        <button
          onClick={() => setShowTutorial(!showTutorial)}
          className="w-full px-4 py-3 flex items-center justify-between text-left"
        >
          <span className="font-medium">Strudel Basics Tutorial</span>
          {showTutorial ? <ChevronUp className="w-5 h-5" /> : <ChevronDown className="w-5 h-5" />}
        </button>
        {showTutorial && (
          <div className="px-4 pb-4 space-y-4 text-sm text-[hsl(var(--muted-foreground))]">
            <div>
              <h4 className="font-medium text-[hsl(var(--foreground))] mb-1">Playing Sounds</h4>
              <code className="block bg-[hsl(var(--muted))] p-2 rounded font-mono text-xs">s("bd sd hh cp")</code>
              <p className="mt-1">bd=kick, sd=snare, hh=hihat, cp=clap</p>
            </div>
            <div>
              <h4 className="font-medium text-[hsl(var(--foreground))] mb-1">Playing Notes</h4>
              <code className="block bg-[hsl(var(--muted))] p-2 rounded font-mono text-xs">note("c4 e4 g4").sound("sawtooth")</code>
            </div>
            <div>
              <h4 className="font-medium text-[hsl(var(--foreground))] mb-1">Speed & Repetition</h4>
              <code className="block bg-[hsl(var(--muted))] p-2 rounded font-mono text-xs">s("hh*8") // 8 hihats per cycle</code>
            </div>
            <div>
              <h4 className="font-medium text-[hsl(var(--foreground))] mb-1">Layering</h4>
              <code className="block bg-[hsl(var(--muted))] p-2 rounded font-mono text-xs">stack(s("bd sd"), s("hh*4"))</code>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
SIMPLEFILE

cat > client/src/pages/DJPage.tsx << 'DJFILE'
import { useState } from "react";
import { Play, Square, Headphones, Radio, Sparkles, Volume2 } from "lucide-react";

export default function DJPage() {
  const [previewCode, setPreviewCode] = useState('// Preview channel\ns("bd sd bd sd")');
  const [masterCode, setMasterCode] = useState('// Master output\ns("hh*8").gain(0.3)');
  const [crossfader, setCrossfader] = useState(50);
  const [previewVolume, setPreviewVolume] = useState(70);
  const [masterVolume, setMasterVolume] = useState(80);
  const [previewPlaying, setPreviewPlaying] = useState(false);
  const [masterPlaying, setMasterPlaying] = useState(false);
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
        if (targetChannel === "preview") {
          setPreviewCode(data.code);
        } else {
          setMasterCode(data.code);
        }
      }
    } catch (e) {
      console.error(e);
    }
    setIsGenerating(false);
  };

  const sendToMaster = () => {
    setMasterCode(previewCode);
  };

  return (
    <div className="max-w-6xl mx-auto p-4 space-y-4">
      {/* AI Prompt */}
      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))]">
        <div className="flex gap-2 mb-3">
          <input
            type="text"
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="Describe the music..."
            className="flex-1 bg-[hsl(var(--input))] border border-[hsl(var(--border))] rounded-md px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[hsl(var(--primary))]"
            onKeyDown={(e) => e.key === "Enter" && generateCode()}
          />
          <button
            onClick={generateCode}
            disabled={isGenerating}
            className="bg-[hsl(var(--primary))] hover:bg-[hsl(var(--primary))]/90 text-white px-6 py-3 rounded-md font-medium flex items-center gap-2 disabled:opacity-50"
          >
            <Sparkles className="w-4 h-4" />
            {isGenerating ? "..." : "Generate"}
          </button>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setTargetChannel("preview")}
            className={`px-3 py-1.5 rounded text-sm flex items-center gap-1 ${
              targetChannel === "preview" ? "bg-amber-500 text-white" : "bg-[hsl(var(--muted))]"
            }`}
          >
            <Headphones className="w-4 h-4" /> Preview
          </button>
          <button
            onClick={() => setTargetChannel("master")}
            className={`px-3 py-1.5 rounded text-sm flex items-center gap-1 ${
              targetChannel === "master" ? "bg-[hsl(var(--secondary))] text-white" : "bg-[hsl(var(--muted))]"
            }`}
          >
            <Radio className="w-4 h-4" /> Master
          </button>
        </div>
      </div>

      {/* Dual Editors */}
      <div className="grid md:grid-cols-2 gap-4">
        {/* Preview Channel */}
        <div className="bg-[hsl(var(--card))] rounded-lg border border-amber-500/50 overflow-hidden">
          <div className="bg-amber-500/20 px-4 py-2 flex items-center justify-between border-b border-amber-500/30">
            <div className="flex items-center gap-2">
              <Headphones className="w-4 h-4 text-amber-500" />
              <span className="text-sm font-medium text-amber-500">Preview</span>
            </div>
            <button
              onClick={() => setPreviewPlaying(!previewPlaying)}
              className={`p-2 rounded ${previewPlaying ? "bg-red-500" : "bg-amber-500"} text-white`}
            >
              {previewPlaying ? <Square className="w-4 h-4" /> : <Play className="w-4 h-4" />}
            </button>
          </div>
          <textarea
            value={previewCode}
            onChange={(e) => setPreviewCode(e.target.value)}
            className="w-full h-48 bg-transparent p-4 font-mono text-sm resize-none focus:outline-none"
            spellCheck={false}
          />
          <div className="px-4 py-2 border-t border-[hsl(var(--border))] flex items-center gap-2">
            <Volume2 className="w-4 h-4 text-[hsl(var(--muted-foreground))]" />
            <input
              type="range"
              min="0"
              max="100"
              value={previewVolume}
              onChange={(e) => setPreviewVolume(Number(e.target.value))}
              className="flex-1 h-1.5 bg-[hsl(var(--muted))] rounded-lg appearance-none cursor-pointer"
            />
            <span className="text-xs w-8">{previewVolume}%</span>
          </div>
        </div>

        {/* Master Channel */}
        <div className="bg-[hsl(var(--card))] rounded-lg border border-[hsl(var(--secondary))]/50 overflow-hidden">
          <div className="bg-[hsl(var(--secondary))]/20 px-4 py-2 flex items-center justify-between border-b border-[hsl(var(--secondary))]/30">
            <div className="flex items-center gap-2">
              <Radio className="w-4 h-4 text-[hsl(var(--secondary))]" />
              <span className="text-sm font-medium text-[hsl(var(--secondary))]">Master</span>
            </div>
            <button
              onClick={() => setMasterPlaying(!masterPlaying)}
              className={`p-2 rounded ${masterPlaying ? "bg-red-500" : "bg-[hsl(var(--secondary))]"} text-white`}
            >
              {masterPlaying ? <Square className="w-4 h-4" /> : <Play className="w-4 h-4" />}
            </button>
          </div>
          <textarea
            value={masterCode}
            onChange={(e) => setMasterCode(e.target.value)}
            className="w-full h-48 bg-transparent p-4 font-mono text-sm resize-none focus:outline-none"
            spellCheck={false}
          />
          <div className="px-4 py-2 border-t border-[hsl(var(--border))] flex items-center gap-2">
            <Volume2 className="w-4 h-4 text-[hsl(var(--muted-foreground))]" />
            <input
              type="range"
              min="0"
              max="100"
              value={masterVolume}
              onChange={(e) => setMasterVolume(Number(e.target.value))}
              className="flex-1 h-1.5 bg-[hsl(var(--muted))] rounded-lg appearance-none cursor-pointer"
            />
            <span className="text-xs w-8">{masterVolume}%</span>
          </div>
        </div>
      </div>

      {/* Crossfader & Send to Master */}
      <div className="bg-[hsl(var(--card))] rounded-lg p-4 border border-[hsl(var(--border))]">
        <div className="flex items-center justify-between mb-4">
          <button
            onClick={sendToMaster}
            className="bg-[hsl(var(--primary))] hover:bg-[hsl(var(--primary))]/90 text-white px-4 py-2 rounded-md text-sm font-medium"
          >
            Send Preview to Master
          </button>
        </div>
        <div className="flex items-center gap-4">
          <span className="text-sm text-amber-500 font-medium">A</span>
          <input
            type="range"
            min="0"
            max="100"
            value={crossfader}
            onChange={(e) => setCrossfader(Number(e.target.value))}
            className="flex-1 h-3 bg-gradient-to-r from-amber-500 to-emerald-500 rounded-lg appearance-none cursor-pointer"
          />
          <span className="text-sm text-[hsl(var(--secondary))] font-medium">B</span>
        </div>
        <div className="text-center text-xs text-[hsl(var(--muted-foreground))] mt-2">Crossfader</div>
      </div>
    </div>
  );
}
DJFILE

# === CONFIG FILES ===
cat > tailwind.config.js << 'TAILWINDCFG'
/** @type {import('tailwindcss').Config} */
export default {
  content: ["./client/index.html", "./client/src/**/*.{js,ts,jsx,tsx}"],
  theme: { extend: {} },
  plugins: [],
};
TAILWINDCFG

cat > postcss.config.js << 'POSTCSSCFG'
export default {
  plugins: { tailwindcss: {}, autoprefixer: {} },
};
POSTCSSCFG

cat > vite.config.ts << 'VITECFG'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  root: "client",
  build: { outDir: "../dist/client", emptyOutDir: true },
  resolve: {
    alias: { "@": path.resolve(__dirname, "client/src") },
  },
  server: {
    proxy: { "/api": "http://localhost:5000" },
  },
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
    "skipLibCheck": true,
    "paths": { "@/*": ["./client/src/*"], "@shared/*": ["./shared/*"] }
  },
  "include": ["client/src", "server", "shared"]
}
TSCFG

# Create .env file
echo "OPENAI_API_KEY=$OPENAI_KEY" > .env

echo "[8/10] Installing npm packages..."
npm install

echo "[9/10] Building application..."
npm run build

echo "[10/10] Configuring Nginx and starting..."

cat > /etc/nginx/sites-available/strudel-ai << 'NGINXCFG'
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
NGINXCFG

ln -sf /etc/nginx/sites-available/strudel-ai /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Firewall
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable

# Start with PM2
pm2 start npm --name "strudel-ai" -- start
pm2 save
pm2 startup

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              INSTALLATION COMPLETE!                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Your Strudel AI app is now running at: http://$(hostname -I | awk '{print $1}')"
echo ""
echo "Useful commands:"
echo "  pm2 logs strudel-ai    - View logs"
echo "  pm2 restart strudel-ai - Restart app"
echo "  pm2 status             - Check status"
