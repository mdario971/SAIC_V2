import { useState, useCallback } from "react";
import { useMutation } from "@tanstack/react-query";
import { Header } from "@/components/Header";
import { PromptInput } from "@/components/PromptInput";
import { CodeEditor } from "@/components/CodeEditor";
import { QuickInsertToolbar } from "@/components/QuickInsertToolbar";
import { SpecialCharsToolbar } from "@/components/SpecialCharsToolbar";
import { useStrudelAudio } from "@/hooks/useStrudelAudio";
import { useLocalStorage } from "@/hooks/useLocalStorage";
import { apiRequest } from "@/lib/queryClient";
import { Button } from "@/components/ui/button";
import { Slider } from "@/components/ui/slider";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { 
  Play, 
  Pause, 
  Square, 
  ArrowRight,
  Headphones, 
  Volume2, 
  VolumeX,
  Radio,
  Shuffle
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";

const DEFAULT_PREVIEW_CODE = `// Preview Channel (Headphones)
// Test your patterns here before going live

s("bd sd bd sd")`;

const DEFAULT_MASTER_CODE = `// Master Channel (Main Output)
// This is what your audience hears

s("hh*8").gain(0.3)`;

export default function DJPage() {
  const [previewCode, setPreviewCode] = useLocalStorage("strudel-preview", DEFAULT_PREVIEW_CODE);
  const [masterCode, setMasterCode] = useLocalStorage("strudel-master", DEFAULT_MASTER_CODE);
  const [activeEditor, setActiveEditor] = useState<'preview' | 'master'>('preview');
  const [crossfader, setCrossfader] = useState(50);
  const [selectedCategory, setSelectedCategory] = useState<string | undefined>();
  const { toast } = useToast();

  const previewAudio = useStrudelAudio({ initialVolume: 0.7 });
  const masterAudio = useStrudelAudio({ initialVolume: 0.7 });

  const generateMutation = useMutation({
    mutationFn: async (prompt: string) => {
      const response = await apiRequest("POST", "/api/generate", { prompt });
      return response.json();
    },
    onSuccess: (data) => {
      if (data.code) {
        if (activeEditor === 'preview') {
          setPreviewCode(data.code);
        } else {
          setMasterCode(data.code);
        }
        toast({
          title: "Code Generated",
          description: `Code added to ${activeEditor === 'preview' ? 'Preview' : 'Master'} channel.`,
        });
      }
    },
    onError: (error: Error) => {
      toast({
        title: "Generation Failed",
        description: error.message || "Failed to generate code.",
        variant: "destructive",
      });
    },
  });

  const handlePromptSubmit = useCallback((prompt: string) => {
    generateMutation.mutate(prompt);
  }, [generateMutation]);

  const handleInsertPattern = useCallback((patternCode: string) => {
    const setter = activeEditor === 'preview' ? setPreviewCode : setMasterCode;
    setter((prev) => {
      if (prev.includes("// Preview Channel") || prev.includes("// Master Channel")) {
        return patternCode;
      }
      return prev + "\n\n" + patternCode;
    });
  }, [activeEditor, setPreviewCode, setMasterCode]);

  const handleInsertChar = useCallback((char: string) => {
    const setter = activeEditor === 'preview' ? setPreviewCode : setMasterCode;
    setter((prev) => prev + char);
  }, [activeEditor, setPreviewCode, setMasterCode]);

  const handleSwapToMaster = useCallback(() => {
    setMasterCode(previewCode);
    toast({
      title: "Swapped to Master",
      description: "Preview code moved to Master channel.",
    });
  }, [previewCode, setMasterCode, toast]);

  const handlePlayPreview = useCallback(async () => {
    if (previewAudio.isPlaying) {
      previewAudio.stop();
    } else {
      await previewAudio.play(previewCode);
    }
  }, [previewAudio, previewCode]);

  const handlePlayMaster = useCallback(async () => {
    if (masterAudio.isPlaying) {
      masterAudio.stop();
    } else {
      await masterAudio.play(masterCode);
    }
  }, [masterAudio, masterCode]);

  const previewVolume = (100 - crossfader) / 100 * previewAudio.volume;
  const masterVolume = crossfader / 100 * masterAudio.volume;

  return (
    <div className="flex flex-col h-[100dvh] bg-background">
      <Header />
      
      <main className="flex-1 flex flex-col overflow-hidden p-4 gap-4">
        <PromptInput
          onSubmit={handlePromptSubmit}
          isLoading={generateMutation.isPending}
        />

        <QuickInsertToolbar
          onInsert={handleInsertPattern}
          selectedCategory={selectedCategory}
          onCategoryChange={setSelectedCategory}
        />

        <div className="flex-1 grid grid-cols-1 lg:grid-cols-2 gap-4 min-h-0">
          <ChannelPanel
            title="Preview"
            subtitle="Cue / Headphones"
            icon={<Headphones className="w-4 h-4" />}
            code={previewCode}
            onCodeChange={setPreviewCode}
            isPlaying={previewAudio.isPlaying}
            onPlay={handlePlayPreview}
            onStop={previewAudio.stop}
            volume={previewAudio.volume}
            onVolumeChange={previewAudio.setVolume}
            effectiveVolume={previewVolume}
            isActive={activeEditor === 'preview'}
            onActivate={() => setActiveEditor('preview')}
            variant="preview"
            onInsertChar={handleInsertChar}
          />

          <ChannelPanel
            title="Master"
            subtitle="Main Output"
            icon={<Radio className="w-4 h-4" />}
            code={masterCode}
            onCodeChange={setMasterCode}
            isPlaying={masterAudio.isPlaying}
            onPlay={handlePlayMaster}
            onStop={masterAudio.stop}
            volume={masterAudio.volume}
            onVolumeChange={masterAudio.setVolume}
            effectiveVolume={masterVolume}
            isActive={activeEditor === 'master'}
            onActivate={() => setActiveEditor('master')}
            variant="master"
            onInsertChar={handleInsertChar}
          />
        </div>

        <CrossfaderControl
          value={crossfader}
          onChange={setCrossfader}
          onSwap={handleSwapToMaster}
        />
      </main>
    </div>
  );
}

interface ChannelPanelProps {
  title: string;
  subtitle: string;
  icon: React.ReactNode;
  code: string;
  onCodeChange: (code: string) => void;
  isPlaying: boolean;
  onPlay: () => void;
  onStop: () => void;
  volume: number;
  onVolumeChange: (v: number) => void;
  effectiveVolume: number;
  isActive: boolean;
  onActivate: () => void;
  variant: 'preview' | 'master';
  onInsertChar: (char: string) => void;
}

function ChannelPanel({
  title,
  subtitle,
  icon,
  code,
  onCodeChange,
  isPlaying,
  onPlay,
  onStop,
  volume,
  onVolumeChange,
  effectiveVolume,
  isActive,
  onActivate,
  variant,
  onInsertChar,
}: ChannelPanelProps) {
  const isMuted = volume === 0;
  const borderColor = variant === 'preview' ? 'border-warning/50' : 'border-success/50';
  const activeBorderColor = variant === 'preview' ? 'border-warning' : 'border-success';
  const badgeVariant = variant === 'preview' ? 'bg-warning/20 text-warning-foreground' : 'bg-success/20 text-success-foreground';

  return (
    <Card 
      className={`flex flex-col overflow-hidden cursor-pointer transition-colors ${isActive ? activeBorderColor : borderColor} ${isActive ? 'ring-1 ring-offset-1 ring-offset-background' : ''}`}
      style={{ borderWidth: '2px' }}
      onClick={onActivate}
      data-testid={`panel-${variant}`}
    >
      <CardHeader className="py-3 px-4 flex flex-row items-center justify-between gap-2 border-b border-border">
        <div className="flex items-center gap-2">
          {icon}
          <div>
            <CardTitle className="text-sm font-semibold">{title}</CardTitle>
            <p className="text-xs text-muted-foreground">{subtitle}</p>
          </div>
        </div>
        
        <div className="flex items-center gap-2">
          {isPlaying && (
            <Badge className={`${badgeVariant} text-xs`}>
              <span className="relative flex h-2 w-2 mr-1">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-current opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-current"></span>
              </span>
              Live
            </Badge>
          )}
          {isActive && (
            <Badge variant="secondary" className="text-xs">
              Active
            </Badge>
          )}
        </div>
      </CardHeader>

      <CardContent className="flex-1 flex flex-col p-0 min-h-0" onClick={(e) => e.stopPropagation()}>
        <div className="px-2 pt-2">
          <SpecialCharsToolbar onInsert={onInsertChar} />
        </div>
        <div className="flex-1 p-2 min-h-0">
          <CodeEditor
            value={code}
            onChange={onCodeChange}
            className="h-full"
            minHeight="100%"
          />
        </div>

        <div className="flex items-center justify-between gap-4 p-3 border-t border-border bg-muted/30">
          <div className="flex items-center gap-2">
            <Tooltip>
              <TooltipTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={(e) => { e.stopPropagation(); onStop(); }}
                  disabled={!isPlaying}
                  data-testid={`button-stop-${variant}`}
                >
                  <Square className="w-4 h-4" />
                </Button>
              </TooltipTrigger>
              <TooltipContent>Stop</TooltipContent>
            </Tooltip>

            <Tooltip>
              <TooltipTrigger asChild>
                <Button
                  variant={isPlaying ? "secondary" : "default"}
                  size="icon"
                  onClick={(e) => { e.stopPropagation(); onPlay(); }}
                  className="w-12 h-12 rounded-full"
                  data-testid={`button-play-${variant}`}
                >
                  {isPlaying ? (
                    <Pause className="w-5 h-5" />
                  ) : (
                    <Play className="w-5 h-5 ml-0.5" />
                  )}
                </Button>
              </TooltipTrigger>
              <TooltipContent>{isPlaying ? 'Pause' : 'Play'}</TooltipContent>
            </Tooltip>
          </div>

          <div className="flex items-center gap-2 flex-1 max-w-[180px]">
            <Button
              variant="ghost"
              size="icon"
              className="h-7 w-7 flex-shrink-0"
              onClick={(e) => { e.stopPropagation(); onVolumeChange(isMuted ? 0.7 : 0); }}
              data-testid={`button-mute-${variant}`}
            >
              {isMuted ? (
                <VolumeX className="w-4 h-4" />
              ) : (
                <Volume2 className="w-4 h-4" />
              )}
            </Button>
            <div className="flex-1">
              <Slider
                value={[volume * 100]}
                onValueChange={([v]) => onVolumeChange(v / 100)}
                max={100}
                step={1}
                onClick={(e) => e.stopPropagation()}
                data-testid={`slider-volume-${variant}`}
              />
            </div>
            <span className="text-xs text-muted-foreground w-8 text-right">
              {Math.round(effectiveVolume * 100)}%
            </span>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

interface CrossfaderControlProps {
  value: number;
  onChange: (value: number) => void;
  onSwap: () => void;
}

function CrossfaderControl({ value, onChange, onSwap }: CrossfaderControlProps) {
  return (
    <div className="bg-card border border-border rounded-lg p-4">
      <div className="flex items-center justify-center gap-4 mb-3">
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant="outline"
              size="sm"
              onClick={onSwap}
              className="gap-2"
              data-testid="button-swap-to-master"
            >
              <Shuffle className="w-4 h-4" />
              Swap Preview to Master
              <ArrowRight className="w-4 h-4" />
            </Button>
          </TooltipTrigger>
          <TooltipContent>Copy Preview code to Master channel</TooltipContent>
        </Tooltip>
      </div>

      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2">
          <Headphones className="w-4 h-4 text-warning" />
          <span className="text-sm font-medium text-warning">CUE</span>
        </div>
        
        <div className="flex-1">
          <Slider
            value={[value]}
            onValueChange={([v]) => onChange(v)}
            max={100}
            step={1}
            className="cursor-pointer"
            data-testid="slider-crossfader"
          />
        </div>
        
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-success">MASTER</span>
          <Radio className="w-4 h-4 text-success" />
        </div>
      </div>

      <div className="flex justify-between mt-2">
        <span className="text-xs text-muted-foreground">{100 - value}%</span>
        <span className="text-xs text-muted-foreground font-medium">Crossfader</span>
        <span className="text-xs text-muted-foreground">{value}%</span>
      </div>
    </div>
  );
}
