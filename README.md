# Strudel AI - Live Coding Music Generator

A mobile-optimized web application that combines Strudel live coding with AI-powered natural language processing to generate music through text prompts.

## Features

- **Simple Mode**: Single code editor with AI prompt input, quick-insert patterns, and tutorial
- **DJ Mode**: Dual editors (Preview/Master) with crossfader for live mixing
- **AI Code Generation**: Natural language to Strudel code using OpenAI GPT-4o
- **Quick Insert Patterns**: Pre-built beats, bass, and synth patterns
- **Mobile-First Design**: Optimized for touch devices with 44px+ touch targets

## Quick Start

### Development (Replit)

The app runs automatically on port 5000. Just click "Run" or use:

```bash
npm run dev
```

### Production Deployment (Debian 13 VPS)

SSH into your server and run:

```bash
curl -o install.sh https://raw.githubusercontent.com/YOUR_USERNAME/strudel-ai/main/deploy/full-install.sh
chmod +x install.sh
sudo bash install.sh
```

The installer will:
1. Install Node.js 20, PM2, and Nginx
2. Create all application files
3. Configure reverse proxy and firewall
4. Start the application

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENAI_API_KEY` | Yes | Your OpenAI API key for code generation |
| `PORT` | No | Server port (default: 5000) |

## Project Structure

```
strudel-ai/
├── client/                    # React frontend
│   ├── src/
│   │   ├── pages/
│   │   │   ├── SimplePage.tsx    # Single editor mode
│   │   │   └── DJPage.tsx        # Dual editor DJ mode
│   │   ├── App.tsx
│   │   └── index.css
│   └── index.html
├── server/                    # Express backend
│   ├── index.ts              # Server entry point
│   ├── routes.ts             # API endpoints
│   └── openai.ts             # OpenAI integration
├── shared/
│   └── schema.ts             # TypeScript types
├── deploy/
│   └── full-install.sh       # VPS deployment script
└── docs/
    └── USER_GUIDE.md         # Detailed user guide
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/generate` | Convert natural language to Strudel code |
| GET | `/api/snippets` | List saved code snippets |
| POST | `/api/snippets` | Save a new snippet |

## Tech Stack

- **Frontend**: React 18, TypeScript, Tailwind CSS, Wouter
- **Backend**: Express.js, OpenAI SDK
- **Build**: Vite
- **State**: TanStack Query

## Strudel Basics

```javascript
// Play drums
s("bd sd bd sd")

// Play notes
note("c4 e4 g4").sound("sawtooth")

// Layer patterns
stack(
  s("bd sd"),
  s("hh*8").gain(0.3)
)

// Add effects
s("bd sd").room(0.5).lpf(800)
```

## License

MIT

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request
