import { useRef, useEffect, useCallback } from "react";
import { Textarea } from "@/components/ui/textarea";

interface CodeEditorProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  readOnly?: boolean;
  className?: string;
  minHeight?: string;
}

export function CodeEditor({
  value,
  onChange,
  placeholder = "// Your Strudel code here...",
  readOnly = false,
  className = "",
  minHeight = "200px",
}: CodeEditorProps) {
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const lineNumbersRef = useRef<HTMLDivElement>(null);

  const updateLineNumbers = useCallback(() => {
    if (!textareaRef.current || !lineNumbersRef.current) return;
    
    const lines = value.split("\n").length;
    const lineNumbers = Array.from({ length: lines }, (_, i) => i + 1).join("\n");
    lineNumbersRef.current.textContent = lineNumbers;
  }, [value]);

  useEffect(() => {
    updateLineNumbers();
  }, [value, updateLineNumbers]);

  const handleScroll = () => {
    if (textareaRef.current && lineNumbersRef.current) {
      lineNumbersRef.current.scrollTop = textareaRef.current.scrollTop;
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Tab") {
      e.preventDefault();
      const start = e.currentTarget.selectionStart;
      const end = e.currentTarget.selectionEnd;
      const newValue = value.substring(0, start) + "  " + value.substring(end);
      onChange(newValue);
      
      requestAnimationFrame(() => {
        if (textareaRef.current) {
          textareaRef.current.selectionStart = textareaRef.current.selectionEnd = start + 2;
        }
      });
    }
  };

  return (
    <div 
      className={`relative flex rounded-lg border border-border bg-card overflow-hidden ${className}`}
      style={{ minHeight }}
    >
      <div
        ref={lineNumbersRef}
        className="w-12 flex-shrink-0 bg-muted/30 text-muted-foreground text-right pr-3 py-4 font-mono text-sm leading-6 select-none overflow-hidden border-r border-border"
        aria-hidden="true"
      >
        1
      </div>
      
      <Textarea
        ref={textareaRef}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        onScroll={handleScroll}
        onKeyDown={handleKeyDown}
        placeholder={placeholder}
        readOnly={readOnly}
        spellCheck={false}
        autoComplete="off"
        autoCorrect="off"
        autoCapitalize="off"
        className="flex-1 resize-none border-0 bg-transparent font-mono text-sm leading-6 focus-visible:ring-0 focus-visible:ring-offset-0 rounded-none min-h-full"
        style={{ minHeight }}
        data-testid="input-code-editor"
      />
    </div>
  );
}
