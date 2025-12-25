import { Link, useLocation } from "wouter";
import { Button } from "@/components/ui/button";
import { Music2, Headphones, Info } from "lucide-react";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";

export function Header() {
  const [location] = useLocation();

  return (
    <header className="h-14 border-b border-border bg-card/50 backdrop-blur-sm sticky top-0 z-50 flex items-center justify-between px-4 gap-4">
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-md bg-primary flex items-center justify-center">
            <Music2 className="w-5 h-5 text-primary-foreground" />
          </div>
          <span className="font-semibold text-lg hidden sm:inline">Strudel AI</span>
        </div>
      </div>

      <nav className="flex items-center gap-1">
        <Tooltip>
          <TooltipTrigger asChild>
            <Link href="/">
              <Button
                variant={location === "/" ? "secondary" : "ghost"}
                size="sm"
                className="gap-2"
                data-testid="nav-simple"
              >
                <Music2 className="w-4 h-4" />
                <span className="hidden sm:inline">Simple</span>
              </Button>
            </Link>
          </TooltipTrigger>
          <TooltipContent>Simple Mode</TooltipContent>
        </Tooltip>

        <Tooltip>
          <TooltipTrigger asChild>
            <Link href="/dj">
              <Button
                variant={location === "/dj" ? "secondary" : "ghost"}
                size="sm"
                className="gap-2"
                data-testid="nav-dj"
              >
                <Headphones className="w-4 h-4" />
                <span className="hidden sm:inline">DJ Mode</span>
              </Button>
            </Link>
          </TooltipTrigger>
          <TooltipContent>DJ/Producer Mode with dual outputs</TooltipContent>
        </Tooltip>
      </nav>

      <div className="flex items-center gap-2">
        <Tooltip>
          <TooltipTrigger asChild>
            <Button variant="ghost" size="icon" data-testid="button-info">
              <Info className="w-4 h-4" />
            </Button>
          </TooltipTrigger>
          <TooltipContent>
            <p className="max-w-xs text-sm">
              Type natural language prompts to generate Strudel code, or use quick-insert buttons for common patterns.
            </p>
          </TooltipContent>
        </Tooltip>
      </div>
    </header>
  );
}
