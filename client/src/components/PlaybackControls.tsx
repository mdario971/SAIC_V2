import { Button } from "@/components/ui/button";
import { Slider } from "@/components/ui/slider";
import { Play, Pause, Square, Volume2, VolumeX, Minus, Plus } from "lucide-react";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";

interface PlaybackControlsProps {
  isPlaying: boolean;
  onPlay: () => void;
  onStop: () => void;
  volume: number;
  onVolumeChange: (volume: number) => void;
  bpm: number;
  onBpmChange: (bpm: number) => void;
  hasError?: boolean;
  errorMessage?: string;
}

export function PlaybackControls({
  isPlaying,
  onPlay,
  onStop,
  volume,
  onVolumeChange,
  bpm,
  onBpmChange,
  hasError = false,
  errorMessage,
}: PlaybackControlsProps) {
  const isMuted = volume === 0;

  return (
    <div className="flex items-center justify-between gap-4 p-4 bg-card border-t border-border">
      <div className="flex items-center gap-2">
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant="ghost"
              size="icon"
              onClick={onStop}
              disabled={!isPlaying}
              data-testid="button-stop"
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
              onClick={onPlay}
              className="w-14 h-14 rounded-full"
              disabled={hasError}
              data-testid="button-play"
            >
              {isPlaying ? (
                <Pause className="w-6 h-6" />
              ) : (
                <Play className="w-6 h-6 ml-1" />
              )}
            </Button>
          </TooltipTrigger>
          <TooltipContent>{isPlaying ? "Pause" : "Play"}</TooltipContent>
        </Tooltip>

        {isPlaying && (
          <div className="flex items-center gap-1 ml-2">
            <span className="relative flex h-3 w-3">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-success opacity-75"></span>
              <span className="relative inline-flex rounded-full h-3 w-3 bg-success"></span>
            </span>
            <span className="text-xs text-success font-medium">Playing</span>
          </div>
        )}

        {hasError && errorMessage && (
          <div className="text-xs text-destructive ml-2 max-w-[200px] truncate">
            {errorMessage}
          </div>
        )}
      </div>

      <div className="flex items-center gap-6">
        <div className="flex items-center gap-2">
          <span className="text-xs text-muted-foreground font-medium">BPM</span>
          <div className="flex items-center gap-1">
            <Button
              variant="ghost"
              size="icon"
              className="h-7 w-7"
              onClick={() => onBpmChange(Math.max(60, bpm - 5))}
              data-testid="button-bpm-minus"
            >
              <Minus className="w-3 h-3" />
            </Button>
            <span className="w-10 text-center font-mono text-sm" data-testid="text-bpm">
              {bpm}
            </span>
            <Button
              variant="ghost"
              size="icon"
              className="h-7 w-7"
              onClick={() => onBpmChange(Math.min(200, bpm + 5))}
              data-testid="button-bpm-plus"
            >
              <Plus className="w-3 h-3" />
            </Button>
          </div>
        </div>

        <div className="flex items-center gap-2 w-32">
          <Button
            variant="ghost"
            size="icon"
            className="h-7 w-7 flex-shrink-0"
            onClick={() => onVolumeChange(isMuted ? 0.7 : 0)}
            data-testid="button-mute"
          >
            {isMuted ? (
              <VolumeX className="w-4 h-4" />
            ) : (
              <Volume2 className="w-4 h-4" />
            )}
          </Button>
          <Slider
            value={[volume * 100]}
            onValueChange={([v]) => onVolumeChange(v / 100)}
            max={100}
            step={1}
            className="flex-1"
            data-testid="slider-volume"
          />
          <span className="text-xs text-muted-foreground w-8 text-right">
            {Math.round(volume * 100)}%
          </span>
        </div>
      </div>
    </div>
  );
}
