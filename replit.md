# Strudel AI - Live Coding Music Generator

## Overview

A mobile-optimized web application that combines Strudel (a live coding music environment) with AI-powered natural language processing to generate music through text prompts. The system converts text descriptions into executable Strudel code, which plays music in real-time using the Web Audio API.

## Current State

- **Frontend**: Complete with two pages (Simple Mode and DJ Mode)
- **Backend**: AI code generation endpoint using OpenAI
- **Audio**: Web Audio API integration for pattern playback
- **Deployment**: Debian 13 VPS deployment scripts included

## Key Features

1. **Simple Mode** (`/`): Single code editor with prompt input, quick-insert toolbar, and tutorial panel
2. **DJ Mode** (`/dj`): Dual editors for preview/master channels with crossfader control
3. **AI Code Generation**: Natural language to Strudel code using OpenAI GPT-5
4. **Quick Insert Patterns**: Pre-built common Strudel patterns (beats, bass, synth, effects)
5. **Interactive Tutorial**: Built-in Strudel basics guide with playable examples
6. **Mobile-First Design**: Optimized for Android browsers with touch-friendly controls

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
│   ├── openai.ts             # OpenAI integration
│   ├── routes.ts             # API endpoints
│   └── storage.ts            # In-memory storage
├── shared/
│   └── schema.ts             # TypeScript types & Zod schemas
├── deploy/                   # Debian 13 deployment files
│   ├── install.sh           # One-command installer
│   ├── nginx.conf           # Nginx configuration
│   ├── pm2.config.js        # PM2 process manager config
│   └── systemd/             # Systemd service files
└── design_guidelines.md     # UI/UX design specifications
```

## API Endpoints

- `POST /api/generate` - Convert natural language to Strudel code
- `GET /api/snippets` - List saved code snippets
- `POST /api/snippets` - Save a new code snippet

## Technology Stack

- **Frontend**: React 18, TypeScript, Tailwind CSS, Shadcn UI
- **Backend**: Express.js, OpenAI SDK
- **Audio**: Web Audio API
- **State**: TanStack Query, Local Storage
- **Routing**: Wouter

## Environment Variables

- `ANTHROPIC_API_KEY` - Claude AI for code generation (preferred)
- `OPENAI_API_KEY` - OpenAI fallback for code generation
- At least one API key is required for AI features to work

## Security & Network Configuration

- **Production mode**: Express binds to `127.0.0.1` (localhost only) for security
- **Development mode**: Express binds to `0.0.0.0` for Replit compatibility
- **Lazy API client**: OpenAI client only initializes when API endpoint is called
- **Firewall ports**:
  - External: 22 (SSH), 80 (HTTP), 443 (HTTPS)
  - External (Guacamole mode only): 8080
  - Internal only: 5000 (Node.js), 4822 (guacd)

## Development

The application runs on port 5000 with Vite dev server. The workflow `Start application` executes `npm run dev`.

## Deployment to Debian 13 VPS

See `deploy/README.md` for full instructions. Quick start:

```bash
# On your VPS
chmod +x deploy/install.sh
sudo ./deploy/install.sh
```

## Design Notes

- Dark theme optimized for extended coding sessions
- Purple (#7C3AED) primary, Emerald (#10B981) secondary colors
- JetBrains Mono for code, Inter for UI
- Touch targets minimum 44px for mobile accessibility
