import { useState, useCallback, useRef, useEffect } from 'react';

interface UseStrudelAudioOptions {
  initialVolume?: number;
  initialBpm?: number;
}

interface UseStrudelAudioReturn {
  isPlaying: boolean;
  volume: number;
  bpm: number;
  error: string | null;
  isInitialized: boolean;
  play: (code: string) => Promise<void>;
  stop: () => void;
  pause: () => void;
  setVolume: (volume: number) => void;
  setBpm: (bpm: number) => void;
  initialize: () => Promise<void>;
}

export function useStrudelAudio(options: UseStrudelAudioOptions = {}): UseStrudelAudioReturn {
  const { initialVolume = 0.7, initialBpm = 120 } = options;
  
  const [isPlaying, setIsPlaying] = useState(false);
  const [volume, setVolumeState] = useState(initialVolume);
  const [bpm, setBpmState] = useState(initialBpm);
  const [error, setError] = useState<string | null>(null);
  const [isInitialized, setIsInitialized] = useState(false);
  
  const audioContextRef = useRef<AudioContext | null>(null);
  const gainNodeRef = useRef<GainNode | null>(null);
  const currentCodeRef = useRef<string>('');
  const oscillatorsRef = useRef<OscillatorNode[]>([]);

  const initialize = useCallback(async () => {
    if (isInitialized) return;
    
    try {
      const AudioContextClass = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      audioContextRef.current = new AudioContextClass();
      
      gainNodeRef.current = audioContextRef.current.createGain();
      gainNodeRef.current.gain.value = volume;
      gainNodeRef.current.connect(audioContextRef.current.destination);
      
      if (audioContextRef.current.state === 'suspended') {
        await audioContextRef.current.resume();
      }
      
      setIsInitialized(true);
      setError(null);
    } catch (err) {
      setError('Failed to initialize audio. Please check browser permissions.');
      console.error('Audio initialization error:', err);
    }
  }, [isInitialized, volume]);

  const stopAllOscillators = useCallback(() => {
    oscillatorsRef.current.forEach(osc => {
      try {
        osc.stop();
        osc.disconnect();
      } catch {
        // Oscillator may already be stopped
      }
    });
    oscillatorsRef.current = [];
  }, []);

  const parseNote = (note: string): number => {
    const noteMap: Record<string, number> = {
      'c': 0, 'd': 2, 'e': 4, 'f': 5, 'g': 7, 'a': 9, 'b': 11
    };
    
    const match = note.toLowerCase().match(/([a-g])([#b]?)(\d+)?/);
    if (!match) return 440;
    
    const [, noteName, modifier, octaveStr] = match;
    let semitone = noteMap[noteName] || 0;
    if (modifier === '#') semitone += 1;
    if (modifier === 'b') semitone -= 1;
    
    const octave = parseInt(octaveStr || '4');
    return 440 * Math.pow(2, (semitone - 9 + (octave - 4) * 12) / 12);
  };

  const playSimplePattern = useCallback((code: string) => {
    if (!audioContextRef.current || !gainNodeRef.current) return;
    
    stopAllOscillators();
    
    const noteMatch = code.match(/note\s*\(\s*["']([^"']+)["']\s*\)/);
    const soundMatch = code.match(/s\s*\(\s*["']([^"']+)["']\s*\)|sound\s*\(\s*["']([^"']+)["']\s*\)/);
    
    if (noteMatch) {
      const notes = noteMatch[1].split(/\s+/).filter(n => n && n !== '~');
      const beatDuration = 60 / bpm;
      
      notes.forEach((note, index) => {
        const freq = parseNote(note);
        const osc = audioContextRef.current!.createOscillator();
        const noteGain = audioContextRef.current!.createGain();
        
        osc.type = 'sawtooth';
        osc.frequency.value = freq;
        
        noteGain.gain.value = 0;
        noteGain.gain.setValueAtTime(0, audioContextRef.current!.currentTime + index * beatDuration);
        noteGain.gain.linearRampToValueAtTime(0.3, audioContextRef.current!.currentTime + index * beatDuration + 0.01);
        noteGain.gain.exponentialRampToValueAtTime(0.01, audioContextRef.current!.currentTime + (index + 0.9) * beatDuration);
        
        osc.connect(noteGain);
        noteGain.connect(gainNodeRef.current!);
        
        osc.start(audioContextRef.current!.currentTime + index * beatDuration);
        osc.stop(audioContextRef.current!.currentTime + (index + 1) * beatDuration);
        
        oscillatorsRef.current.push(osc);
      });
    } else if (soundMatch) {
      const sounds = (soundMatch[1] || soundMatch[2]).split(/\s+/).filter(s => s && s !== '~');
      const beatDuration = 60 / bpm;
      
      sounds.forEach((sound, index) => {
        const osc = audioContextRef.current!.createOscillator();
        const noteGain = audioContextRef.current!.createGain();
        
        if (sound === 'bd') {
          osc.type = 'sine';
          osc.frequency.setValueAtTime(150, audioContextRef.current!.currentTime + index * beatDuration);
          osc.frequency.exponentialRampToValueAtTime(40, audioContextRef.current!.currentTime + index * beatDuration + 0.1);
        } else if (sound === 'sd' || sound === 'cp') {
          osc.type = 'triangle';
          osc.frequency.value = 200;
        } else if (sound === 'hh' || sound === 'oh') {
          osc.type = 'square';
          osc.frequency.value = 800;
        } else {
          osc.type = 'sine';
          osc.frequency.value = 440;
        }
        
        noteGain.gain.value = 0;
        noteGain.gain.setValueAtTime(0, audioContextRef.current!.currentTime + index * beatDuration);
        noteGain.gain.linearRampToValueAtTime(0.4, audioContextRef.current!.currentTime + index * beatDuration + 0.01);
        noteGain.gain.exponentialRampToValueAtTime(0.01, audioContextRef.current!.currentTime + index * beatDuration + 0.15);
        
        osc.connect(noteGain);
        noteGain.connect(gainNodeRef.current!);
        
        osc.start(audioContextRef.current!.currentTime + index * beatDuration);
        osc.stop(audioContextRef.current!.currentTime + index * beatDuration + 0.2);
        
        oscillatorsRef.current.push(osc);
      });
    }
  }, [bpm, stopAllOscillators]);

  const play = useCallback(async (code: string): Promise<void> => {
    setError(null);
    currentCodeRef.current = code;
    
    try {
      if (!isInitialized) {
        await initialize();
      }
      
      if (!code.trim()) {
        setError('No code to play');
        return Promise.resolve();
      }
      
      if (audioContextRef.current?.state === 'suspended') {
        await audioContextRef.current.resume();
      }
      
      playSimplePattern(code);
      setIsPlaying(true);
      return Promise.resolve();
    } catch (err) {
      setError('Error playing audio. Check your code syntax.');
      console.error('Playback error:', err);
      return Promise.reject(err);
    }
  }, [isInitialized, initialize, playSimplePattern]);

  const stop = useCallback(() => {
    stopAllOscillators();
    setIsPlaying(false);
  }, [stopAllOscillators]);

  const pause = useCallback(() => {
    if (audioContextRef.current?.state === 'running') {
      audioContextRef.current.suspend();
    }
    setIsPlaying(false);
  }, []);

  const setVolume = useCallback((newVolume: number) => {
    const clampedVolume = Math.max(0, Math.min(1, newVolume));
    setVolumeState(clampedVolume);
    
    if (gainNodeRef.current) {
      gainNodeRef.current.gain.value = clampedVolume;
    }
  }, []);

  const setBpm = useCallback((newBpm: number) => {
    const clampedBpm = Math.max(60, Math.min(200, newBpm));
    setBpmState(clampedBpm);
  }, []);

  useEffect(() => {
    return () => {
      stopAllOscillators();
      if (audioContextRef.current) {
        audioContextRef.current.close();
      }
    };
  }, [stopAllOscillators]);

  return {
    isPlaying,
    volume,
    bpm,
    error,
    isInitialized,
    play,
    stop,
    pause,
    setVolume,
    setBpm,
    initialize,
  };
}
