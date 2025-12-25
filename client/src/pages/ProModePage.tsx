import { useState, useRef, useCallback } from "react";
import { useMutation } from "@tanstack/react-query";
import { Header } from "@/components/Header";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Slider } from "@/components/ui/slider";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { 
  Send, 
  Copy, 
  Play, 
  Square, 
  Trash2, 
  Music, 
  Sparkles, 
  Settings2,
  ExternalLink,
  Loader2
} from "lucide-react";
import {
  getAvailableGenres,
  getAvailableScales,
  generateStrudelPattern,
  GENRE_PATTERNS,
} from "@/lib/music-theory";

interface Message {
  id: string;
  role: "user" | "assistant";
  content: string;
  code?: string;
}

export default function ProModePage() {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: "welcome",
      role: "assistant",
      content: "Welcome to Pro Mode! I can help you create music with Strudel. Try asking for a specific genre, tempo, or describe the mood you want. I'll generate the code and you can run it in the Strudel REPL on the right.",
    },
  ]);
  const [input, setInput] = useState("");
  const [generatedCode, setGeneratedCode] = useState("");
  const [isStrudelOpen, setIsStrudelOpen] = useState(true);
  
  // Generation options
  const [genre, setGenre] = useState("techno");
  const [bpm, setBpm] = useState(120);
  const [key, setKey] = useState("C");
  const [includeDrums, setIncludeDrums] = useState(true);
  const [includeBass, setIncludeBass] = useState(true);
  const [includeSynth, setIncludeSynth] = useState(true);
  
  const { toast } = useToast();
  const scrollAreaRef = useRef<HTMLDivElement>(null);
  const iframeRef = useRef<HTMLIFrameElement>(null);

  const generateMutation = useMutation({
    mutationFn: async (prompt: string) => {
      const response = await apiRequest("POST", "/api/generate", { 
        prompt,
        context: {
          genre,
          bpm,
          key,
          includeDrums,
          includeBass,
          includeSynth,
        }
      });
      return response.json();
    },
    onSuccess: (data) => {
      if (data.code) {
        setGeneratedCode(data.code);
        const assistantMessage: Message = {
          id: Date.now().toString(),
          role: "assistant",
          content: "Here's your generated code! Click 'Copy to Strudel' to paste it into the REPL, or use the 'Open in Strudel' button to open it directly.",
          code: data.code,
        };
        setMessages(prev => [...prev, assistantMessage]);
      }
    },
    onError: (error: Error) => {
      const errorMessage: Message = {
        id: Date.now().toString(),
        role: "assistant",
        content: `Sorry, I encountered an error: ${error.message}. Please try again.`,
      };
      setMessages(prev => [...prev, errorMessage]);
    },
  });

  const handleSubmit = useCallback((e?: React.FormEvent) => {
    e?.preventDefault();
    if (!input.trim() || generateMutation.isPending) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: "user",
      content: input,
    };
    setMessages(prev => [...prev, userMessage]);
    generateMutation.mutate(input);
    setInput("");
  }, [input, generateMutation]);

  const handleQuickGenerate = useCallback(() => {
    const code = generateStrudelPattern({
      genre: genre as keyof typeof GENRE_PATTERNS,
      bpm,
      key,
      includeDrums,
      includeBass,
      includeSynth,
    });
    setGeneratedCode(code);
    toast({
      title: "Pattern Generated",
      description: `Created a ${genre} pattern at ${bpm} BPM in ${key}`,
    });
  }, [genre, bpm, key, includeDrums, includeBass, includeSynth, toast]);

  const copyToClipboard = useCallback(async (code: string) => {
    try {
      await navigator.clipboard.writeText(code);
      toast({
        title: "Copied",
        description: "Code copied to clipboard. Paste it into the Strudel REPL.",
      });
    } catch {
      toast({
        title: "Copy Failed",
        description: "Could not copy to clipboard.",
        variant: "destructive",
      });
    }
  }, [toast]);

  const openInStrudel = useCallback((code: string) => {
    const encoded = encodeURIComponent(code);
    window.open(`https://strudel.cc/#${btoa(code)}`, '_blank');
  }, []);

  const clearChat = useCallback(() => {
    setMessages([{
      id: "welcome",
      role: "assistant",
      content: "Chat cleared. Ready for new music creation!",
    }]);
    setGeneratedCode("");
  }, []);

  return (
    <div className="h-screen flex flex-col bg-background">
      <Header />
      
      <main className="flex-1 flex flex-col lg:flex-row overflow-hidden">
        {/* Left Panel - Chat & Controls */}
        <div className="w-full lg:w-1/2 flex flex-col border-b lg:border-b-0 lg:border-r max-h-[50vh] lg:max-h-full overflow-hidden">
          {/* Quick Controls */}
          <div className="p-4 border-b bg-muted/30">
            <div className="flex items-center gap-2 mb-3">
              <Settings2 className="w-4 h-4 text-muted-foreground" />
              <span className="text-sm font-medium">Quick Generate</span>
            </div>
            
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1">
                <Label className="text-xs">Genre</Label>
                <Select value={genre} onValueChange={setGenre}>
                  <SelectTrigger data-testid="select-genre">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {getAvailableGenres().map(g => (
                      <SelectItem key={g} value={g}>{g.charAt(0).toUpperCase() + g.slice(1)}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              
              <div className="space-y-1">
                <Label className="text-xs">Key</Label>
                <Select value={key} onValueChange={setKey}>
                  <SelectTrigger data-testid="select-key">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'].map(k => (
                      <SelectItem key={k} value={k}>{k}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              
              <div className="col-span-2 space-y-1">
                <div className="flex justify-between">
                  <Label className="text-xs">BPM: {bpm}</Label>
                </div>
                <Slider
                  value={[bpm]}
                  onValueChange={([v]) => setBpm(v)}
                  min={60}
                  max={200}
                  step={1}
                  data-testid="slider-bpm"
                />
              </div>
              
              <div className="col-span-2 flex gap-4">
                <div className="flex items-center gap-2">
                  <Switch checked={includeDrums} onCheckedChange={setIncludeDrums} id="drums" data-testid="switch-drums" />
                  <Label htmlFor="drums" className="text-xs">Drums</Label>
                </div>
                <div className="flex items-center gap-2">
                  <Switch checked={includeBass} onCheckedChange={setIncludeBass} id="bass" data-testid="switch-bass" />
                  <Label htmlFor="bass" className="text-xs">Bass</Label>
                </div>
                <div className="flex items-center gap-2">
                  <Switch checked={includeSynth} onCheckedChange={setIncludeSynth} id="synth" data-testid="switch-synth" />
                  <Label htmlFor="synth" className="text-xs">Synth</Label>
                </div>
              </div>
            </div>
            
            <Button 
              onClick={handleQuickGenerate} 
              className="w-full mt-3"
              variant="secondary"
              data-testid="button-quick-generate"
            >
              <Sparkles className="w-4 h-4 mr-2" />
              Quick Generate
            </Button>
          </div>

          {/* Chat Messages */}
          <ScrollArea className="flex-1 p-4" ref={scrollAreaRef}>
            <div className="space-y-4">
              {messages.map(message => (
                <div 
                  key={message.id} 
                  className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  <div className={`max-w-[85%] rounded-lg p-3 ${
                    message.role === 'user' 
                      ? 'bg-primary text-primary-foreground' 
                      : 'bg-muted'
                  }`}>
                    <p className="text-sm">{message.content}</p>
                    {message.code && (
                      <div className="mt-2">
                        <pre className="bg-background/50 p-2 rounded text-xs overflow-x-auto">
                          <code>{message.code}</code>
                        </pre>
                        <div className="flex gap-2 mt-2">
                          <Button 
                            size="sm" 
                            variant="outline" 
                            onClick={() => copyToClipboard(message.code!)}
                            data-testid="button-copy-code"
                          >
                            <Copy className="w-3 h-3 mr-1" />
                            Copy
                          </Button>
                          <Button 
                            size="sm" 
                            variant="outline" 
                            onClick={() => openInStrudel(message.code!)}
                            data-testid="button-open-strudel"
                          >
                            <ExternalLink className="w-3 h-3 mr-1" />
                            Open in Strudel
                          </Button>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              ))}
              {generateMutation.isPending && (
                <div className="flex justify-start">
                  <div className="bg-muted rounded-lg p-3">
                    <Loader2 className="w-4 h-4 animate-spin" />
                  </div>
                </div>
              )}
            </div>
          </ScrollArea>

          {/* Chat Input */}
          <form onSubmit={handleSubmit} className="p-4 border-t">
            <div className="flex gap-2">
              <Textarea
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="Describe the music you want to create..."
                className="min-h-[60px] resize-none"
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    handleSubmit();
                  }
                }}
                data-testid="input-prompt"
              />
              <div className="flex flex-col gap-2">
                <Button 
                  type="submit" 
                  disabled={generateMutation.isPending || !input.trim()}
                  data-testid="button-send"
                >
                  <Send className="w-4 h-4" />
                </Button>
                <Button 
                  type="button" 
                  variant="outline" 
                  onClick={clearChat}
                  data-testid="button-clear-chat"
                >
                  <Trash2 className="w-4 h-4" />
                </Button>
              </div>
            </div>
          </form>
        </div>

        {/* Right Panel - Strudel Embed & Code Preview */}
        <div className="w-full lg:w-1/2 flex flex-col flex-1 min-h-0">
          {/* Generated Code Preview */}
          {generatedCode && (
            <Card className="m-4 mb-0">
              <CardHeader className="py-2 px-4">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-sm flex items-center gap-2">
                    <Music className="w-4 h-4" />
                    Generated Code
                  </CardTitle>
                  <div className="flex gap-2">
                    <Button 
                      size="sm" 
                      variant="ghost" 
                      onClick={() => copyToClipboard(generatedCode)}
                      data-testid="button-copy-generated"
                    >
                      <Copy className="w-3 h-3" />
                    </Button>
                    <Button 
                      size="sm" 
                      variant="ghost" 
                      onClick={() => openInStrudel(generatedCode)}
                      data-testid="button-open-generated"
                    >
                      <ExternalLink className="w-3 h-3" />
                    </Button>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="py-2 px-4">
                <pre className="bg-muted p-2 rounded text-xs overflow-x-auto max-h-32">
                  <code>{generatedCode}</code>
                </pre>
              </CardContent>
            </Card>
          )}

          {/* Strudel Embed */}
          <div className="flex-1 p-4">
            <Card className="h-full flex flex-col">
              <CardHeader className="py-2 px-4 border-b">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-sm flex items-center gap-2">
                    <Sparkles className="w-4 h-4 text-primary" />
                    Strudel REPL
                  </CardTitle>
                  <div className="flex items-center gap-2">
                    <Badge variant="outline" className="text-xs">Live</Badge>
                    <Button 
                      size="sm" 
                      variant="ghost"
                      onClick={() => window.open('https://strudel.cc', '_blank')}
                      data-testid="button-fullscreen-strudel"
                    >
                      <ExternalLink className="w-3 h-3" />
                    </Button>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="flex-1 p-0 overflow-hidden">
                <iframe
                  ref={iframeRef}
                  src="https://strudel.cc/"
                  className="w-full h-full border-0"
                  title="Strudel REPL"
                  allow="autoplay; microphone"
                  sandbox="allow-scripts allow-same-origin allow-popups allow-forms"
                  data-testid="iframe-strudel"
                />
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
    </div>
  );
}
