import { useState } from "react";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Send, Loader2, Sparkles } from "lucide-react";

interface PromptInputProps {
  onSubmit: (prompt: string) => void;
  isLoading?: boolean;
  disabled?: boolean;
}

export function PromptInput({ onSubmit, isLoading = false, disabled = false }: PromptInputProps) {
  const [prompt, setPrompt] = useState("");

  const handleSubmit = () => {
    if (prompt.trim() && !isLoading && !disabled) {
      onSubmit(prompt.trim());
      setPrompt("");
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) {
      e.preventDefault();
      handleSubmit();
    }
  };

  const characterCount = prompt.length;
  const maxChars = 500;

  return (
    <div className="relative">
      <div className="flex items-start gap-2 p-3 rounded-lg border border-border bg-card">
        <Sparkles className="w-5 h-5 text-primary mt-1 flex-shrink-0" />
        
        <div className="flex-1 min-w-0">
          <Textarea
            value={prompt}
            onChange={(e) => setPrompt(e.target.value.slice(0, maxChars))}
            onKeyDown={handleKeyDown}
            placeholder="Describe the music you want to create... (e.g., 'Create a chill lofi beat with soft drums and a jazzy piano melody')"
            className="resize-none border-0 bg-transparent focus-visible:ring-0 focus-visible:ring-offset-0 text-sm min-h-[80px] max-h-[160px]"
            disabled={isLoading || disabled}
            data-testid="input-prompt"
          />
          
          <div className="flex items-center justify-between mt-2 pt-2 border-t border-border/50">
            <span className="text-xs text-muted-foreground">
              {characterCount}/{maxChars} characters
            </span>
            <span className="text-xs text-muted-foreground hidden sm:inline">
              Press Ctrl+Enter to generate
            </span>
          </div>
        </div>

        <Button
          onClick={handleSubmit}
          disabled={!prompt.trim() || isLoading || disabled}
          size="icon"
          className="flex-shrink-0"
          data-testid="button-generate"
        >
          {isLoading ? (
            <Loader2 className="w-4 h-4 animate-spin" />
          ) : (
            <Send className="w-4 h-4" />
          )}
        </Button>
      </div>
    </div>
  );
}
