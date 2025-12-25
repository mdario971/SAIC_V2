# Strudel AI User Guide

A complete guide to creating music with Strudel AI.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Simple Mode](#simple-mode)
3. [DJ Mode](#dj-mode)
4. [AI Prompts](#ai-prompts)
5. [Strudel Code Reference](#strudel-code-reference)
6. [Tips and Tricks](#tips-and-tricks)

---

## Getting Started

### Opening the App

Navigate to your Strudel AI URL in any modern browser. The app works best on:
- Chrome/Chromium (recommended)
- Firefox
- Safari
- Mobile browsers (Android Chrome, iOS Safari)

### Choosing a Mode

- **Simple Mode** (`/`): Best for beginners and focused creation
- **DJ Mode** (`/dj`): For live performance and mixing

---

## Simple Mode

Simple Mode provides a single code editor with all the tools you need.

### The Interface

1. **AI Prompt Box** - Type what you want to create in plain English
2. **Code Editor** - Write and edit Strudel code directly
3. **Playback Controls** - Play/stop button and volume slider
4. **Quick Insert** - Pre-made patterns you can add with one tap
5. **Tutorial Panel** - Expandable guide to Strudel basics

### Creating Your First Beat

1. Type a description in the prompt box, like "funky drum beat"
2. Click the **Generate** button (sparkle icon)
3. The AI will write Strudel code for you
4. Press the **Play** button to hear it

### Using Quick Insert

The Quick Insert toolbar has ready-made patterns:

**Beats**
- 4/4 Kick - Basic four-on-the-floor kick drum
- Basic Beat - Kick and snare pattern
- Hi-hat - Fast hi-hat rhythm

**Bass**
- Sub Bass - Deep low frequency bass
- Acid - Classic acid bass with filter sweep

**Synth**
- Pad - Smooth chord progression
- Arp - Fast arpeggiated notes

Click any button to add that pattern to your code.

---

## DJ Mode

DJ Mode gives you two separate channels for mixing.

### The Interface

1. **AI Prompt Box** - Same as Simple Mode, with channel selector
2. **Preview Channel (Orange)** - Prepare your next pattern here
3. **Master Channel (Green)** - What the audience hears
4. **Crossfader** - Blend between channels
5. **Send to Master** - Copy preview code to master

### DJ Workflow

1. **Prepare in Preview**: Write or generate code in the Preview channel
2. **Test It**: Play the Preview channel (only you hear it)
3. **Send to Master**: When ready, click "Send Preview to Master"
4. **Mix**: Use the crossfader to blend between channels

### Channel Selector

Before generating with AI, choose where the code goes:
- **Preview** (Orange) - For preparing patterns
- **Master** (Green) - Direct to live output

---

## AI Prompts

The AI understands natural language descriptions of music. Here are effective prompts:

### Genre-Based Prompts

| Prompt | Result |
|--------|--------|
| "lofi hip hop beat" | Relaxed drums with jazzy chords |
| "techno kick pattern" | Four-on-the-floor with industrial sounds |
| "ambient drone" | Slow-evolving pads and textures |
| "trap beat with 808s" | Hard-hitting bass and hi-hats |

### Specific Requests

| Prompt | Result |
|--------|--------|
| "fast arpeggio in C minor" | Quick note sequence in Cm scale |
| "drum and bass rhythm" | Fast breakbeat pattern |
| "chord progression Am F C G" | Classic pop progression |
| "acid bassline with filter" | 303-style bass with LPF modulation |

### Modifiers

Add these words to adjust the output:
- **slow** / **fast** - Tempo adjustment
- **simple** / **complex** - Pattern complexity
- **minimal** / **layered** - Number of elements
- **dark** / **bright** - Tonal quality
- **with reverb** / **dry** - Effects

---

## Strudel Code Reference

### Playing Samples

```javascript
// Single sound
s("bd")

// Pattern of sounds
s("bd sd bd sd")

// Common drum sounds
// bd = kick, sd = snare, hh = hihat
// cp = clap, oh = open hat, lt/mt/ht = toms
```

### Playing Notes

```javascript
// Single note
note("c4")

// Melody
note("c4 e4 g4 c5")

// With a synth sound
note("c4 e4 g4").sound("sawtooth")

// Available synths: sine, triangle, sawtooth, square
```

### Rhythm and Timing

```javascript
// Repeat a sound
s("hh*8")        // 8 times per cycle

// Slow down
s("bd sd").slow(2)

// Speed up  
s("bd sd").fast(2)

// Rest (silence)
s("bd ~ sd ~")
```

### Effects

```javascript
// Volume (0-1)
s("bd sd").gain(0.5)

// Low-pass filter (frequency in Hz)
note("c2").sound("sawtooth").lpf(400)

// Reverb (0-1)
s("bd sd").room(0.5)

// Delay
s("hh*4").delay(0.5)

// Pan left/right (-1 to 1)
s("bd").pan(-1)   // left
s("sd").pan(1)    // right
```

### Layering

```javascript
// Stack multiple patterns
stack(
  s("bd sd bd sd"),
  s("hh*8").gain(0.3),
  note("c2 c2 g2 c2").sound("sawtooth").lpf(300)
)
```

### Modulation

```javascript
// Sine wave modulation
note("c4").sound("sawtooth").lpf(sine.range(200, 2000))

// Random values
s("hh*8").gain(rand.range(0.2, 0.8))
```

---

## Tips and Tricks

### For Better AI Results

1. **Be specific**: "mellow jazz piano chords" works better than just "piano"
2. **Mention tempo**: "slow ambient pad" vs "fast techno synth"
3. **Name effects**: "with heavy reverb" or "dry punchy drums"
4. **Reference genres**: The AI knows many music styles

### For Live Performance

1. Keep your Preview channel one step ahead
2. Use the crossfader for smooth transitions
3. Layer simple patterns rather than one complex one
4. Save working patterns using snippets

### Common Issues

**No sound?**
- Check your browser allows audio
- Click somewhere on the page first (browsers require interaction)
- Check the volume slider

**Code errors?**
- Check for matching parentheses and quotes
- Make sure function names are lowercase
- Use the Tutorial panel for correct syntax

**AI not generating?**
- Check your internet connection
- Try a simpler prompt
- Wait a moment and try again

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Enter | Generate code (when in prompt field) |
| Ctrl/Cmd + Enter | Play/Stop |

---

## Getting Help

- Expand the **Tutorial Panel** in Simple Mode for quick reference
- Visit [strudel.cc](https://strudel.cc) for full Strudel documentation
- Check the pattern examples in Quick Insert for working code
