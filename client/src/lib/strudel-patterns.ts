export interface StrudelPattern {
  id: string;
  name: string;
  code: string;
  category: 'beats' | 'bass' | 'synth' | 'effects' | 'melody';
  description: string;
}

export const strudelPatterns: StrudelPattern[] = [
  {
    id: 'basic-beat',
    name: 'Basic Beat',
    code: 's("bd sd bd sd")',
    category: 'beats',
    description: 'Simple 4/4 kick-snare pattern'
  },
  {
    id: 'four-floor',
    name: 'Four on Floor',
    code: 's("bd*4")',
    category: 'beats',
    description: 'Classic house kick pattern'
  },
  {
    id: 'hihats',
    name: 'Hi-Hats',
    code: 's("hh*8").gain(0.4)',
    category: 'beats',
    description: 'Eighth note hi-hats'
  },
  {
    id: 'drum-pattern',
    name: 'Full Drums',
    code: `stack(
  s("bd sd bd sd"),
  s("hh*8").gain(0.3),
  s("~ cp ~ cp").gain(0.5)
)`,
    category: 'beats',
    description: 'Complete drum loop with kick, snare, hats, and clap'
  },
  {
    id: 'euclidean',
    name: 'Euclidean',
    code: 's("bd(3,8) sd(2,8,1)")',
    category: 'beats',
    description: 'Euclidean rhythm pattern'
  },
  {
    id: 'simple-bass',
    name: 'Simple Bass',
    code: 'note("c2 ~ c2 ~ e2 ~ g1 ~").sound("sawtooth").lpf(400)',
    category: 'bass',
    description: 'Basic bass line'
  },
  {
    id: 'acid-bass',
    name: 'Acid Bass',
    code: `note("c2 c2 c3 c2 eb2 c2 g2 c2")
  .sound("sawtooth")
  .lpf(sine.range(200, 2000).slow(4))
  .lpq(8)`,
    category: 'bass',
    description: 'Classic acid bass with filter sweep'
  },
  {
    id: 'sub-bass',
    name: 'Sub Bass',
    code: 'note("c1 ~ ~ c1 ~ ~ c1 ~").sound("sine").gain(0.8)',
    category: 'bass',
    description: 'Deep sub bass'
  },
  {
    id: 'pad',
    name: 'Synth Pad',
    code: `note("<c3 e3 g3> <e3 g3 b3>")
  .sound("sawtooth")
  .lpf(800)
  .room(0.5)
  .slow(2)`,
    category: 'synth',
    description: 'Ambient pad sound'
  },
  {
    id: 'arp',
    name: 'Arpeggio',
    code: 'note("c4 e4 g4 b4").sound("triangle").fast(2)',
    category: 'synth',
    description: 'Simple arpeggio pattern'
  },
  {
    id: 'pluck',
    name: 'Pluck Synth',
    code: `note("c4 ~ e4 ~ g4 ~ a4 ~")
  .sound("sawtooth")
  .decay(0.1)
  .sustain(0)`,
    category: 'synth',
    description: 'Plucky synth melody'
  },
  {
    id: 'melody-1',
    name: 'Simple Melody',
    code: 'note("c4 d4 e4 g4 e4 d4 c4 ~")',
    category: 'melody',
    description: 'Basic melodic phrase'
  },
  {
    id: 'melody-2',
    name: 'Jazz Melody',
    code: `note("c4 eb4 g4 bb4 ab4 g4 eb4 c4")
  .sound("piano")
  .slow(2)`,
    category: 'melody',
    description: 'Jazz-influenced melody'
  },
  {
    id: 'delay',
    name: 'Add Delay',
    code: '.delay(0.5).delaytime(0.25).delayfeedback(0.5)',
    category: 'effects',
    description: 'Delay effect chain'
  },
  {
    id: 'reverb',
    name: 'Add Reverb',
    code: '.room(0.8).size(0.9)',
    category: 'effects',
    description: 'Spacious reverb'
  },
  {
    id: 'filter',
    name: 'Filter Sweep',
    code: '.lpf(sine.range(200, 4000).slow(8))',
    category: 'effects',
    description: 'Low-pass filter modulation'
  },
  {
    id: 'pan',
    name: 'Auto Pan',
    code: '.pan(sine.range(0, 1).slow(2))',
    category: 'effects',
    description: 'Automatic panning'
  }
];

export const strudelBasics = [
  {
    title: 'Getting Started',
    content: `Strudel uses a special pattern notation to create music. The basic structure is:
    
\`sound("sample")\` - Play a sample
\`note("c4 e4 g4")\` - Play notes
\`s("bd sd")\` - Shorthand for sound()`,
    examples: ['s("bd sd")', 'note("c4 e4 g4")']
  },
  {
    title: 'Mini-Notation',
    content: `Special characters in patterns:
    
\`~\` = Rest/silence
\`*\` = Multiply (speed up)
\`/\` = Divide (slow down)
\`[]\` = Group events
\`<>\` = Alternate each cycle`,
    examples: ['s("bd ~ sd ~")', 's("hh*8")', 's("<bd sd> hh")']
  },
  {
    title: 'Common Samples',
    content: `Built-in drum samples:
    
\`bd\` = Bass drum
\`sd\` = Snare drum
\`hh\` = Hi-hat
\`cp\` = Clap
\`oh\` = Open hi-hat`,
    examples: ['s("bd sd hh cp")', 's("bd*4 oh")']
  },
  {
    title: 'Synth Sounds',
    content: `Built-in synthesizers:
    
\`sawtooth\` = Saw wave
\`sine\` = Sine wave
\`triangle\` = Triangle wave
\`square\` = Square wave`,
    examples: ['note("c3").sound("sawtooth")', 'note("e4").sound("sine")']
  },
  {
    title: 'Effects',
    content: `Common effects:
    
\`.gain(0.5)\` = Volume (0-1)
\`.lpf(500)\` = Low-pass filter
\`.room(0.5)\` = Reverb
\`.delay(0.5)\` = Delay
\`.pan(0.5)\` = Stereo position`,
    examples: ['s("bd sd").gain(0.8)', 'note("c4").lpf(400).room(0.5)']
  },
  {
    title: 'Stacking Patterns',
    content: `Combine multiple patterns:
    
\`stack()\` = Layer patterns together
\`cat()\` = Play patterns in sequence`,
    examples: [
      `stack(
  s("bd sd"),
  s("hh*4")
)`,
      `cat(
  s("bd*4"),
  s("sd*4")
)`
    ]
  }
];

export const categoryColors: Record<string, string> = {
  beats: 'bg-primary/20 text-primary-foreground border-primary/30',
  bass: 'bg-success/20 text-success-foreground border-success/30',
  synth: 'bg-warning/20 text-warning-foreground border-warning/30',
  effects: 'bg-accent text-accent-foreground border-accent',
  melody: 'bg-chart-4/20 text-foreground border-chart-4/30'
};
