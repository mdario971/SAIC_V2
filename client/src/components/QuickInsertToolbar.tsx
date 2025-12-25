import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ScrollArea, ScrollBar } from "@/components/ui/scroll-area";
import { strudelPatterns, categoryColors, type StrudelPattern } from "@/lib/strudel-patterns";
import { Drum, Music, Waves, Sparkles, Music2 } from "lucide-react";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";

interface QuickInsertToolbarProps {
  onInsert: (code: string) => void;
  selectedCategory?: string;
  onCategoryChange?: (category: string | undefined) => void;
}

const categoryIcons: Record<string, React.ReactNode> = {
  beats: <Drum className="w-3.5 h-3.5" />,
  bass: <Waves className="w-3.5 h-3.5" />,
  synth: <Music className="w-3.5 h-3.5" />,
  melody: <Music2 className="w-3.5 h-3.5" />,
  effects: <Sparkles className="w-3.5 h-3.5" />,
};

const categories = ['beats', 'bass', 'synth', 'melody', 'effects'] as const;

export function QuickInsertToolbar({ 
  onInsert, 
  selectedCategory,
  onCategoryChange 
}: QuickInsertToolbarProps) {
  const filteredPatterns = selectedCategory 
    ? strudelPatterns.filter(p => p.category === selectedCategory)
    : strudelPatterns;

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2 flex-wrap">
        <span className="text-xs font-medium text-muted-foreground">Quick Insert:</span>
        <div className="flex items-center gap-1 flex-wrap">
          <Button
            variant={!selectedCategory ? "secondary" : "ghost"}
            size="sm"
            onClick={() => onCategoryChange?.(undefined)}
            className="h-7 text-xs"
            data-testid="button-category-all"
          >
            All
          </Button>
          {categories.map((cat) => (
            <Button
              key={cat}
              variant={selectedCategory === cat ? "secondary" : "ghost"}
              size="sm"
              onClick={() => onCategoryChange?.(cat)}
              className="h-7 text-xs gap-1.5"
              data-testid={`button-category-${cat}`}
            >
              {categoryIcons[cat]}
              <span className="capitalize hidden sm:inline">{cat}</span>
            </Button>
          ))}
        </div>
      </div>

      <ScrollArea className="w-full whitespace-nowrap">
        <div className="flex gap-2 pb-2">
          {filteredPatterns.map((pattern) => (
            <PatternButton 
              key={pattern.id} 
              pattern={pattern} 
              onInsert={onInsert} 
            />
          ))}
        </div>
        <ScrollBar orientation="horizontal" />
      </ScrollArea>
    </div>
  );
}

function PatternButton({ 
  pattern, 
  onInsert 
}: { 
  pattern: StrudelPattern; 
  onInsert: (code: string) => void;
}) {
  return (
    <Tooltip>
      <TooltipTrigger asChild>
        <Button
          variant="outline"
          size="sm"
          onClick={() => onInsert(pattern.code)}
          className="h-9 gap-2 flex-shrink-0"
          data-testid={`button-pattern-${pattern.id}`}
        >
          {categoryIcons[pattern.category]}
          <span>{pattern.name}</span>
          <Badge 
            variant="secondary" 
            className={`text-[10px] px-1.5 py-0 ${categoryColors[pattern.category]}`}
          >
            {pattern.category}
          </Badge>
        </Button>
      </TooltipTrigger>
      <TooltipContent side="bottom" className="max-w-xs">
        <p className="font-medium mb-1">{pattern.description}</p>
        <pre className="text-xs font-mono bg-muted p-2 rounded overflow-x-auto">
          {pattern.code}
        </pre>
      </TooltipContent>
    </Tooltip>
  );
}
