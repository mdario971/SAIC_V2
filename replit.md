# Strudel AI - Live Coding Music Generator

## Overview

A mobile-optimized web application that combines Strudel (a live coding music environment) with AI-powered natural language processing to generate music through text prompts. The system supports three deployment modes with different AI integration approaches.

## Current State

- **Frontend**: Complete with two pages (Simple Mode and DJ Mode)
- **Backend**: AI code generation endpoint using Claude/OpenAI
- **Audio**: Web Audio API integration for pattern playback
- **Deployment**: Universal installer supporting Debian/Ubuntu and Rocky/RHEL/AlmaLinux/CentOS

## Deployment Modes

### 1. SAIC Classic (API-based)
- Simple editor + DJ mode + quick patterns
- Uses Claude/OpenAI API for code generation
- Requires API key

### 2. SAIC Pro (API-based)
- Embedded strudel.cc REPL + music theory tools
- Uses Claude/OpenAI API for code generation
- Requires API key

### 3. Remote Desktop + MCP Server (FREE)
- Guacamole remote desktop via browser
- Strudel MCP Server (Model Context Protocol)
- Claude Desktop controls Strudel directly
- NO API keys required!

## MCP Architecture (Mode 3)

```
┌─────────────────────────────────────────┐
│     User Browser (Guacamole Client)     │
└──────────────┬──────────────────────────┘
               │ HTTP/WebSocket (port 8080)
┌──────────────▼──────────────────────────┐
│        Guacamole / Tomcat               │
│         (Web Gateway)                   │
└──────────────┬──────────────────────────┘
               │ VNC (port 5901, internal)
┌──────────────▼──────────────────────────┐
│         XFCE Desktop (VNC)              │
│  ┌────────────────────────────────┐     │
│  │      Claude Desktop            │     │
│  │        (MCP Host)              │     │
│  └──────────┬─────────────────────┘     │
│             │ MCP Protocol (stdio)      │
│  ┌──────────▼─────────────────────┐     │
│  │   Strudel MCP Server           │     │
│  │  (@williamzujkowski package)   │     │
│  │  ├─ Pattern Generation         │     │
│  │  ├─ Music Theory Engine        │     │
│  │  ├─ Playwright Browser Control │     │
│  │  └─ Session Management         │     │
│  └──────────┬─────────────────────┘     │
│             │ Browser Automation        │
│  ┌──────────▼─────────────────────┐     │
│  │     Chromium + strudel.cc      │     │
│  │      (Web Audio Playback)      │     │
│  └────────────────────────────────┘     │
└─────────────────────────────────────────┘
```

### MCP Workflow
1. User connects via Guacamole to remote XFCE desktop
2. User opens Claude Desktop and types: "Create a techno beat at 130 BPM"
3. Claude uses Strudel MCP tools to generate pattern code
4. MCP Server uses Playwright to control strudel.cc in browser
5. Music plays in real-time through desktop audio

### Key MCP Tools (40+ available)
- `strudel_initialize` - Start browser and load strudel.cc
- `strudel_generate_pattern` - AI-generate patterns by genre
- `strudel_play` / `strudel_stop` - Control playback
- `music_theory_scales` - Get scale notes
- `music_theory_chords` - Build chord progressions
- `pattern_save` / `pattern_load` - Session management

## Project Architecture

```
├── client/                    # Frontend React application
│   ├── src/
│   │   ├── components/        # Reusable UI components
│   │   │   ├── Header.tsx
│   │   │   ├── CodeEditor.tsx
│   │   │   ├── PromptInput.tsx
│   │   │   ├── QuickInsertToolbar.tsx
│   │   │   ├── PlaybackControls.tsx
│   │   │   ├── TutorialPanel.tsx
│   │   │   └── SpecialCharsToolbar.tsx
│   │   ├── hooks/
│   │   │   ├── useStrudelAudio.ts  # Web Audio API hook
│   │   │   └── useLocalStorage.ts  # Persistence hook
│   │   ├── lib/
│   │   │   ├── strudel-patterns.ts # Pattern definitions
│   │   │   └── queryClient.ts
│   │   ├── pages/
│   │   │   ├── SimplePage.tsx     # Main single-editor mode
│   │   │   └── DJPage.tsx         # Dual-output DJ mode
│   │   └── App.tsx
│   └── index.html
├── server/                    # Express backend
│   ├── anthropic.ts          # Claude AI integration
│   ├── openai.ts             # OpenAI integration
│   ├── routes.ts             # API endpoints
│   └── storage.ts            # In-memory storage
├── shared/
│   └── schema.ts             # TypeScript types & Zod schemas
├── deploy/                   # Universal deployment files
│   ├── install.sh           # One-command installer (all 3 modes)
│   └── README.md            # Deployment documentation
└── design_guidelines.md     # UI/UX design specifications
```

## API Endpoints

- `POST /api/generate` - Convert natural language to Strudel code (Claude preferred, OpenAI fallback)
- `GET /api/status` - Check which AI provider is active
- `GET /api/snippets` - List saved code snippets
- `POST /api/snippets` - Save a new code snippet

## Technology Stack

- **Frontend**: React 18, TypeScript, Tailwind CSS, Shadcn UI
- **Backend**: Express.js, Anthropic SDK, OpenAI SDK
- **Audio**: Web Audio API
- **State**: TanStack Query, Local Storage
- **Routing**: Wouter
- **MCP**: Strudel MCP Server (@williamzujkowski/strudel-mcp-server)
- **Remote Desktop**: Guacamole, TigerVNC, XFCE4

## Environment Variables

### Modes 1 & 2 (API-based)
- `ANTHROPIC_API_KEY` - Claude AI for code generation (preferred)
- `OPENAI_API_KEY` - OpenAI fallback for code generation
- At least one API key is required for AI features to work

### Mode 3 (MCP-based)
- No API keys required!
- Claude Desktop + MCP Server handles everything locally

## Security & Network Configuration

- **Production mode**: Express binds to `127.0.0.1` (localhost only) for security
- **Development mode**: Express binds to `0.0.0.0` for Replit compatibility
- **Lazy API client**: Claude/OpenAI clients only initialize when API endpoint is called
- **Firewall ports**:
  - External: 22 (SSH), 80 (HTTP), 443 (HTTPS)
  - External (Mode 3 only): 8080 (Guacamole)
  - Internal only: 5000 (Node.js), 4822 (guacd), 5901 (VNC)

## Development

The application runs on port 5000 with Vite dev server. The workflow `Start application` executes `npm run dev`.

## Deployment

Universal installer supports:
- Debian 12/13, Ubuntu 22.04+
- Rocky Linux 9, RHEL 9, AlmaLinux 9, CentOS Stream 9

```bash
# Download and run installer
curl -O https://raw.githubusercontent.com/mdario971/SAIC/main/deploy/install.sh
sudo bash install.sh
```

## Design Notes

- Dark theme optimized for extended coding sessions
- Purple (#7C3AED) primary, Emerald (#10B981) secondary colors
- JetBrains Mono for code, Inter for UI
- Touch targets minimum 44px for mobile accessibility
