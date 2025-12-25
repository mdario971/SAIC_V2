# Design Guidelines: Strudel AI Live Coding Application

## Design Approach

**Reference-Based Design** drawing from:
- **Primary**: Strudel's official interface (strudel.cc) - clean, code-focused layout
- **Secondary**: CodePen/Replit - split-screen editor paradigms
- **Tertiary**: Professional DJ software (Serato, Traktor) for dual-output page

**Design Principles:**
1. Code-first visibility - editor is the hero element
2. Zero visual noise - every element serves live coding workflow
3. Touch-optimized for mobile without sacrificing desktop power
4. Instant feedback - all actions provide immediate visual confirmation

---

## Typography System

**Font Stack:**
- **Code/Monospace**: JetBrains Mono at 14px (mobile), 16px (desktop) with line-height 1.6 for code blocks
- **UI Text**: Inter or system-ui at 14px (body), 16px (headings), 12px (labels)
- **Weights**: Regular (400) for body, Medium (500) for labels, Semibold (600) for headings

**Hierarchy:**
- Page titles: 24px semibold
- Section headers: 18px semibold  
- Button labels: 14px medium
- Help text: 12px regular
- Code: 14-16px regular monospace

---

## Layout System

**Spacing Primitives:** Use Tailwind units of **2, 4, 8, 12, 16** (e.g., p-4, gap-8, m-2)

**Grid Structure:**

*Simple Interface (Mobile):*
```
[Prompt Input - h-32]
[Quick Insert Toolbar - h-12]  
[Code Editor - flex-1]
[Playback Controls - h-16]
[Tutorial Panel - collapsible]
```

*Simple Interface (Desktop):*
```
┌────────────────┬────────────────┐
│ Prompt + Quick │ Tutorial Panel │
│ Insert (w-1/2) │ (w-1/2)       │
├────────────────┴────────────────┤
│ Code Editor (h-2/3)             │
├─────────────────────────────────┤
│ Playback Controls (h-16)        │
└─────────────────────────────────┘
```

*DJ/Producer Page (Desktop):*
```
┌─────────────────┬─────────────────┐
│ Preview Editor  │ Master Editor   │
│ (w-1/2, h-full) │ (w-1/2, h-full) │
│                 │                 │
│ [Cue Controls]  │ [Main Controls] │
└─────────────────┴─────────────────┘
        [Crossfader - fixed bottom]
```

**Container Constraints:**
- Max-width: none (full viewport utilization)
- Editor padding: p-4 (mobile), p-6 (desktop)
- Section gaps: gap-4 (mobile), gap-6 (desktop)

---

## Component Library

### Navigation
**Top Bar** (h-14, sticky):
- Logo/title left
- Mode toggle (Simple ↔ DJ) center
- Settings icon right
- Mobile: hamburger menu for tutorial collapse

### Code Editor
**Monaco/CodeMirror Configuration:**
- Line numbers: visible
- Minimap: hidden on mobile, optional on desktop
- Scrollbar: thin overlay style
- Border: 1px solid with subtle glow on focus
- Corner radius: rounded-lg (8px)
- Padding: p-4 inside editor

### Prompt Input
**Textarea** (mobile: h-32, desktop: h-24):
- Placeholder: "Describe the music you want to create..."
- Auto-resize on desktop
- Send button: icon-only (paper airplane) fixed right
- Character counter bottom-right

### Quick Insert Toolbar
**Horizontal Scroll (mobile), Grid (desktop):**
- Chips with pattern names: "Basic Beat", "Bass Line", "Synth Pad"
- Each chip: px-3 py-1.5, rounded-full
- Tap to insert code at cursor
- Icons from Heroicons (musical note, waveform variants)

### Playback Controls
**Control Bar:**
- Play/Pause: large circular button (56px diameter) center
- Stop: square button (40px) left of play
- BPM display: right side with +/- steppers
- Volume slider: 120px width with percentage
- Status indicator: pulsing dot when playing

### Tutorial Panel
**Collapsible Accordion:**
- Sections: "Basics", "Syntax", "Samples", "Effects"
- Each card: p-4, rounded-lg
- Sound example buttons: small play icons (24px)
- Code snippets: inline monospace with copy button

### DJ Dual-Output Controls
**Crossfader** (fixed bottom, h-20):
- Horizontal slider spanning 60% viewport width
- Labels: "CUE" left, "MASTER" right
- Position indicator: large draggable thumb (48px)
- Swap button: centered above fader

**Channel Strips** (within each editor):
- VU meters: vertical bars showing levels
- Solo/Mute toggles: icon buttons
- Volume faders: vertical sliders (100px height)

---

## Animations

**Minimal, Purposeful Only:**
- Button press: scale(0.95) on active
- Panel expand/collapse: 200ms ease
- Playback indicator pulse: 1.5s infinite
- Crossfader: smooth 100ms drag response
- **No** page transitions, **no** scroll effects

---

## Mobile Optimizations

**Touch Targets:**
- Minimum 44px height for all interactive elements
- Button spacing: minimum gap-3 (12px)
- Slider thumbs: 48px touch area

**Keyboard Handling:**
- Special character quick-access bar above keyboard
- Common Strudel symbols: `() [] {} ~ * / <>`
- Auto-capitalization: disabled
- Auto-correct: disabled

**Viewport:**
- Meta viewport: `width=device-width, initial-scale=1, maximum-scale=1`
- Prevent zoom on input focus
- Use `100dvh` for dynamic viewport height

---

## Accessibility

**Keyboard Navigation:**
- Tab order: Prompt → Quick Insert → Editor → Controls
- Ctrl+Enter: Execute code
- Ctrl+Space: AI generate
- Escape: Stop playback

**Screen Reader:**
- ARIA labels on all icon-only buttons
- Live region announcements for playback state
- Editor role="textbox" with aria-label

**Focus States:**
- 2px outline with 4px offset
- Visible on all interactive elements

---

## Images

**No hero images required** - this is a utility application where the code editor IS the hero element.

**Icon Usage:**
- Heroicons throughout (outline style for toolbar, solid for active states)
- Sizes: 20px (buttons), 24px (playback), 16px (inline)

**Optional Branding:**
- Small Strudel logo (32px) in top-left if desired
- Waveform visualizations can be added as decorative elements in playback area (future enhancement)

---

## Critical Mobile Constraints

**Split-Screen on Mobile:**
- Stack vertically, never side-by-side
- Editor takes 60% viewport height minimum
- Swipe gestures to toggle tutorial panel
- Fixed playback controls at bottom (sticky)

**DJ Page on Mobile:**
- Single editor view with toggle between Preview/Master
- Floating action button to switch modes
- Crossfader: horizontal swipe gesture alternative to slider