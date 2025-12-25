// Music Theory Utilities for Strudel Code Generation

export const NOTES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'] as const;
export const FLAT_NOTES = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'] as const;

export type NoteName = typeof NOTES[number] | typeof FLAT_NOTES[number];

// Scale patterns (intervals from root)
export const SCALES: Record<string, number[]> = {
  major: [0, 2, 4, 5, 7, 9, 11],
  minor: [0, 2, 3, 5, 7, 8, 10],
  dorian: [0, 2, 3, 5, 7, 9, 10],
  phrygian: [0, 1, 3, 5, 7, 8, 10],
  lydian: [0, 2, 4, 6, 7, 9, 11],
  mixolydian: [0, 2, 4, 5, 7, 9, 10],
  locrian: [0, 1, 3, 5, 6, 8, 10],
  pentatonic: [0, 2, 4, 7, 9],
  blues: [0, 3, 5, 6, 7, 10],
  chromatic: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
  wholeTone: [0, 2, 4, 6, 8, 10],
  diminished: [0, 2, 3, 5, 6, 8, 9, 11],
};

// Chord patterns (intervals from root)
export const CHORDS: Record<string, number[]> = {
  major: [0, 4, 7],
  minor: [0, 3, 7],
  dim: [0, 3, 6],
  aug: [0, 4, 8],
  sus2: [0, 2, 7],
  sus4: [0, 5, 7],
  dom7: [0, 4, 7, 10],
  maj7: [0, 4, 7, 11],
  min7: [0, 3, 7, 10],
  dim7: [0, 3, 6, 9],
  m7b5: [0, 3, 6, 10],
  add9: [0, 4, 7, 14],
};

// Common chord progressions by genre
export const PROGRESSIONS: Record<string, { name: string; numerals: string[]; description: string }[]> = {
  pop: [
    { name: "I-V-vi-IV", numerals: ["I", "V", "vi", "IV"], description: "The most popular progression in modern pop" },
    { name: "I-IV-V-I", numerals: ["I", "IV", "V", "I"], description: "Classic rock/pop progression" },
    { name: "vi-IV-I-V", numerals: ["vi", "IV", "I", "V"], description: "Sad pop progression" },
  ],
  jazz: [
    { name: "ii-V-I", numerals: ["ii", "V", "I"], description: "Most common jazz progression" },
    { name: "I-vi-ii-V", numerals: ["I", "vi", "ii", "V"], description: "Rhythm changes" },
    { name: "iii-vi-ii-V", numerals: ["iii", "vi", "ii", "V"], description: "Extended turnaround" },
  ],
  blues: [
    { name: "12-bar", numerals: ["I", "I", "I", "I", "IV", "IV", "I", "I", "V", "IV", "I", "V"], description: "Standard 12-bar blues" },
  ],
  ambient: [
    { name: "I-bVII-IV", numerals: ["I", "bVII", "IV"], description: "Dreamy modal progression" },
    { name: "i-VI-III-VII", numerals: ["i", "VI", "III", "VII"], description: "Epic ambient progression" },
  ],
  edm: [
    { name: "i-VI-III-VII", numerals: ["i", "VI", "III", "VII"], description: "EDM anthem progression" },
    { name: "i-iv-VI-V", numerals: ["i", "iv", "VI", "V"], description: "Dark EDM progression" },
  ],
};

// Genre-specific patterns for Strudel
export const GENRE_PATTERNS: Record<string, { drums: string; bass: string; synth: string; effects: string }> = {
  techno: {
    drums: 's("bd*4, ~ cp ~ cp, hh*8")',
    bass: 'note("c2 c2 c2 c3").s("sawtooth").lpf(800)',
    synth: 'note("c4 eb4 g4 bb4").s("square").lpf(2000).room(0.2)',
    effects: '.room(0.1).delay(0.125)',
  },
  house: {
    drums: 's("bd*4, ~ cp ~ cp, [~ hh]*8")',
    bass: 'note("c2 ~ eb2 ~").s("triangle").lpf(600)',
    synth: 'note("<c4 eb4 g4> <eb4 g4 bb4>").s("sawtooth").lpf(1500)',
    effects: '.room(0.2).delay(0.25)',
  },
  dnb: {
    drums: 's("bd ~ [~ bd] ~, ~ ~ cp ~, hh*16")',
    bass: 'note("c1 ~ c1 c2").s("sawtooth").lpf(400)',
    synth: 'note("c5 eb5 ~ g5").s("square").lpf(3000)',
    effects: '.room(0.15).delay(0.0625)',
  },
  ambient: {
    drums: 's("~ ~ ~ ~, ~ [hh ~] ~ ~")',
    bass: 'note("c2 ~ ~ eb2").s("sine").lpf(200).room(0.8)',
    synth: 'note("<c4 eb4 g4 bb4>").s("triangle").lpf(800).room(0.9)',
    effects: '.room(0.9).delay(0.5)',
  },
  trap: {
    drums: 's("bd ~ ~ bd, ~ ~ cp ~, [hh hh hh]*4")',
    bass: 'note("c1 ~ ~ c1").s("sine").lpf(100)',
    synth: 'note("c4 ~ eb4 ~").s("square").lpf(2500)',
    effects: '.room(0.2).delay(0.125)',
  },
};

// Get note index from name
export function getNoteIndex(note: string): number {
  const normalized = note.replace('b', '#').toUpperCase();
  let idx = NOTES.indexOf(normalized as typeof NOTES[number]);
  if (idx === -1) {
    // Handle flats
    const flatMap: Record<string, number> = { 'DB': 1, 'EB': 3, 'GB': 6, 'AB': 8, 'BB': 10 };
    idx = flatMap[note.toUpperCase()] ?? 0;
  }
  return idx;
}

// Generate scale notes from root
export function generateScale(root: string, scaleType: keyof typeof SCALES, octave = 4): string[] {
  const rootIdx = getNoteIndex(root);
  const pattern = SCALES[scaleType] || SCALES.major;
  
  return pattern.map(interval => {
    const noteIdx = (rootIdx + interval) % 12;
    return `${NOTES[noteIdx]}${octave}`;
  });
}

// Generate chord notes from root
export function generateChord(root: string, chordType: keyof typeof CHORDS, octave = 4): string[] {
  const rootIdx = getNoteIndex(root);
  const pattern = CHORDS[chordType] || CHORDS.major;
  
  return pattern.map(interval => {
    const noteIdx = (rootIdx + interval) % 12;
    const noteOctave = octave + Math.floor((rootIdx + interval) / 12);
    return `${NOTES[noteIdx]}${noteOctave}`;
  });
}

// Convert Roman numeral to scale degree
function romanToScaleDegree(numeral: string): { degree: number; quality: string } {
  const isMinor = numeral === numeral.toLowerCase();
  const cleanNumeral = numeral.replace('b', '').toUpperCase();
  
  const numeralMap: Record<string, number> = {
    'I': 0, 'II': 1, 'III': 2, 'IV': 3, 'V': 4, 'VI': 5, 'VII': 6,
  };
  
  let degree = numeralMap[cleanNumeral] ?? 0;
  if (numeral.startsWith('b')) degree -= 1;
  
  return { degree, quality: isMinor ? 'minor' : 'major' };
}

// Generate chord progression
export function generateProgression(
  key: string,
  progressionType: string,
  genre: keyof typeof PROGRESSIONS = 'pop'
): string[] {
  const progressions = PROGRESSIONS[genre] || PROGRESSIONS.pop;
  const progression = progressions.find(p => p.name === progressionType) || progressions[0];
  
  const keyIdx = getNoteIndex(key);
  const majorScale = SCALES.major;
  
  return progression.numerals.map(numeral => {
    const { degree, quality } = romanToScaleDegree(numeral);
    const noteIdx = (keyIdx + majorScale[Math.abs(degree) % 7]) % 12;
    const chord = generateChord(NOTES[noteIdx], quality === 'minor' ? 'min7' : 'maj7');
    return `<${chord.join(' ')}>`;
  });
}

// Generate Euclidean rhythm pattern
export function generateEuclidean(hits: number, steps: number, rotation = 0): string {
  const pattern: boolean[] = new Array(steps).fill(false);
  
  if (hits <= 0) return '~'.repeat(steps).split('').join(' ');
  if (hits >= steps) return 'x'.repeat(steps).split('').join(' ');
  
  // Bresenham's algorithm for Euclidean distribution
  let bucket = 0;
  for (let i = 0; i < steps; i++) {
    bucket += hits;
    if (bucket >= steps) {
      bucket -= steps;
      pattern[i] = true;
    }
  }
  
  // Apply rotation
  const rotated = [...pattern.slice(rotation), ...pattern.slice(0, rotation)];
  
  return rotated.map(hit => hit ? 'x' : '~').join(' ');
}

// Generate polyrhythm
export function generatePolyrhythm(rhythm1: number, rhythm2: number): string {
  return `[bd*${rhythm1}, cp*${rhythm2}]`;
}

// Generate Strudel code for a complete pattern
export function generateStrudelPattern(options: {
  genre?: keyof typeof GENRE_PATTERNS;
  bpm?: number;
  key?: string;
  scale?: keyof typeof SCALES;
  includeDrums?: boolean;
  includeBass?: boolean;
  includeSynth?: boolean;
}): string {
  const {
    genre = 'techno',
    bpm = 120,
    key = 'C',
    includeDrums = true,
    includeBass = true,
    includeSynth = true,
  } = options;
  
  const genrePattern = GENRE_PATTERNS[genre] || GENRE_PATTERNS.techno;
  const parts: string[] = [];
  
  parts.push(`setcpm(${bpm})`);
  
  const stackParts: string[] = [];
  if (includeDrums) stackParts.push(genrePattern.drums);
  if (includeBass) stackParts.push(genrePattern.bass);
  if (includeSynth) stackParts.push(genrePattern.synth);
  
  if (stackParts.length > 0) {
    parts.push(`stack(\n  ${stackParts.join(',\n  ')}\n)${genrePattern.effects}`);
  }
  
  return parts.join('\n');
}

// Get list of available genres
export function getAvailableGenres(): string[] {
  return Object.keys(GENRE_PATTERNS);
}

// Get list of available scales
export function getAvailableScales(): string[] {
  return Object.keys(SCALES);
}

// Get list of available chords
export function getAvailableChords(): string[] {
  return Object.keys(CHORDS);
}
