import { useState, useCallback } from "react";
import { useMutation } from "@tanstack/react-query";
import { Header } from "@/components/Header";
import { PromptInput } from "@/components/PromptInput";
import { CodeEditor } from "@/components/CodeEditor";
import { QuickInsertToolbar } from "@/components/QuickInsertToolbar";
import { PlaybackControls } from "@/components/PlaybackControls";
import { TutorialPanel } from "@/components/TutorialPanel";
import { SpecialCharsToolbar } from "@/components/SpecialCharsToolbar";
import { useStrudelAudio } from "@/hooks/useStrudelAudio";
import { useLocalStorage } from "@/hooks/useLocalStorage";
import { apiRequest } from "@/lib/queryClient";
import { Button } from "@/components/ui/button";
import { ChevronDown, ChevronUp, BookOpen } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

const DEFAULT_CODE = `// Welcome to Strudel AI!
// Type a prompt above or use Quick Insert buttons
// Press Ctrl+Enter to generate code from your prompt

// Example: basic beat
s("bd sd bd sd")
`;

export default function SimplePage() {
  const [code, setCode] = useLocalStorage("strudel-code", DEFAULT_CODE);
  const [selectedCategory, setSelectedCategory] = useState<string | undefined>();
  const [showTutorial, setShowTutorial] = useState(false);
  const { toast } = useToast();
  
  const audio = useStrudelAudio();

  const generateMutation = useMutation({
    mutationFn: async (prompt: string) => {
      const response = await apiRequest("POST", "/api/generate", { prompt });
      return response.json();
    },
    onSuccess: (data) => {
      if (data.code) {
        setCode(data.code);
        toast({
          title: "Code Generated",
          description: "Your music code is ready! Press play to hear it.",
        });
      }
    },
    onError: (error: Error) => {
      toast({
        title: "Generation Failed",
        description: error.message || "Failed to generate code. Please try again.",
        variant: "destructive",
      });
    },
  });

  const handlePromptSubmit = useCallback((prompt: string) => {
    generateMutation.mutate(prompt);
  }, [generateMutation]);

  const handleInsertPattern = useCallback((patternCode: string) => {
    setCode((prev) => {
      if (prev.trim() === DEFAULT_CODE.trim() || prev.trim() === "") {
        return patternCode;
      }
      return prev + "\n\n" + patternCode;
    });
  }, [setCode]);

  const handleInsertChar = useCallback((char: string) => {
    setCode((prev) => prev + char);
  }, [setCode]);

  const handlePlay = useCallback(async () => {
    if (audio.isPlaying) {
      audio.stop();
    } else {
      await audio.play(code);
    }
  }, [audio, code]);

  return (
    <div className="flex flex-col h-[100dvh] bg-background">
      <Header />
      
      <main className="flex-1 flex flex-col lg:flex-row overflow-hidden">
        <div className="flex-1 flex flex-col overflow-hidden p-4 gap-4">
          <PromptInput
            onSubmit={handlePromptSubmit}
            isLoading={generateMutation.isPending}
          />

          <QuickInsertToolbar
            onInsert={handleInsertPattern}
            selectedCategory={selectedCategory}
            onCategoryChange={setSelectedCategory}
          />

          <div className="flex-1 flex flex-col min-h-0">
            <SpecialCharsToolbar onInsert={handleInsertChar} />
            <div className="flex-1 mt-2">
              <CodeEditor
                value={code}
                onChange={setCode}
                className="h-full"
                minHeight="100%"
              />
            </div>
          </div>
        </div>

        <div className="lg:hidden">
          <Button
            variant="ghost"
            className="w-full justify-between py-3 rounded-none border-t border-border"
            onClick={() => setShowTutorial(!showTutorial)}
            data-testid="button-toggle-tutorial"
          >
            <span className="flex items-center gap-2">
              <BookOpen className="w-4 h-4" />
              Strudel Basics
            </span>
            {showTutorial ? (
              <ChevronDown className="w-4 h-4" />
            ) : (
              <ChevronUp className="w-4 h-4" />
            )}
          </Button>
          {showTutorial && (
            <div className="max-h-[40vh] overflow-auto border-t border-border">
              <TutorialPanel onInsertCode={handleInsertPattern} />
            </div>
          )}
        </div>

        <div className="hidden lg:block w-80 xl:w-96 border-l border-border overflow-auto">
          <TutorialPanel onInsertCode={handleInsertPattern} />
        </div>
      </main>

      <PlaybackControls
        isPlaying={audio.isPlaying}
        onPlay={handlePlay}
        onStop={audio.stop}
        volume={audio.volume}
        onVolumeChange={audio.setVolume}
        bpm={audio.bpm}
        onBpmChange={audio.setBpm}
        hasError={!!audio.error}
        errorMessage={audio.error || undefined}
      />
    </div>
  );
}
