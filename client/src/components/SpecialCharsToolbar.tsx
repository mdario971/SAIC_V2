import { Button } from "@/components/ui/button";

interface SpecialCharsToolbarProps {
  onInsert: (char: string) => void;
}

const specialChars = [
  { char: '()', label: '( )' },
  { char: '[]', label: '[ ]' },
  { char: '{}', label: '{ }' },
  { char: '~', label: '~' },
  { char: '*', label: '*' },
  { char: '/', label: '/' },
  { char: '<>', label: '< >' },
  { char: '"', label: '"' },
  { char: '.', label: '.' },
  { char: ',', label: ',' },
];

export function SpecialCharsToolbar({ onInsert }: SpecialCharsToolbarProps) {
  return (
    <div className="flex items-center gap-1 overflow-x-auto py-2 px-1 bg-muted/30 rounded-md">
      <span className="text-xs text-muted-foreground px-2 flex-shrink-0">Insert:</span>
      {specialChars.map(({ char, label }) => (
        <Button
          key={char}
          variant="ghost"
          size="sm"
          onClick={() => onInsert(char)}
          className="h-8 min-w-[32px] font-mono text-sm flex-shrink-0"
          data-testid={`button-char-${char.replace(/[<>]/g, '')}`}
        >
          {label}
        </Button>
      ))}
    </div>
  );
}
