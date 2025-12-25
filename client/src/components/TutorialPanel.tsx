import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Copy, Check } from "lucide-react";
import { useState } from "react";
import { strudelBasics } from "@/lib/strudel-patterns";

interface TutorialPanelProps {
  onInsertCode?: (code: string) => void;
}

export function TutorialPanel({ onInsertCode }: TutorialPanelProps) {
  return (
    <Card className="h-full overflow-hidden">
      <CardContent className="p-0">
        <div className="p-4 border-b border-border">
          <h3 className="font-semibold text-sm">Strudel Basics</h3>
          <p className="text-xs text-muted-foreground mt-1">
            Learn the fundamentals of live coding music
          </p>
        </div>
        
        <Accordion type="multiple" defaultValue={["getting-started"]} className="px-2">
          {strudelBasics.map((section, index) => (
            <AccordionItem 
              key={index} 
              value={section.title.toLowerCase().replace(/\s+/g, '-')}
              className="border-b-0"
            >
              <AccordionTrigger className="text-sm py-3 hover:no-underline">
                {section.title}
              </AccordionTrigger>
              <AccordionContent className="pb-4">
                <div className="space-y-3">
                  <p className="text-sm text-muted-foreground whitespace-pre-line leading-relaxed">
                    {section.content}
                  </p>
                  
                  {section.examples.length > 0 && (
                    <div className="space-y-2">
                      <span className="text-xs font-medium text-muted-foreground">
                        Examples:
                      </span>
                      {section.examples.map((example, i) => (
                        <CodeExample 
                          key={i} 
                          code={example} 
                          onInsert={onInsertCode}
                        />
                      ))}
                    </div>
                  )}
                </div>
              </AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
      </CardContent>
    </Card>
  );
}

function CodeExample({ 
  code, 
  onInsert 
}: { 
  code: string; 
  onInsert?: (code: string) => void;
}) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleInsert = () => {
    onInsert?.(code);
  };

  return (
    <div className="group relative">
      <pre className="text-xs font-mono bg-muted/50 p-3 rounded-md overflow-x-auto">
        {code}
      </pre>
      <div className="absolute top-1 right-1 flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
        <Button
          variant="ghost"
          size="icon"
          className="h-6 w-6"
          onClick={handleCopy}
          data-testid="button-copy-code"
        >
          {copied ? (
            <Check className="w-3 h-3 text-success" />
          ) : (
            <Copy className="w-3 h-3" />
          )}
        </Button>
        {onInsert && (
          <Button
            variant="ghost"
            size="sm"
            className="h-6 text-xs px-2"
            onClick={handleInsert}
            data-testid="button-insert-code"
          >
            Insert
          </Button>
        )}
      </div>
    </div>
  );
}
