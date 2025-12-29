import type { Express } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { generateStrudelCode, isOpenAIAvailable } from "./openai";
import { generateStrudelCodeWithClaude, isAnthropicAvailable } from "./anthropic";
import { z } from "zod";

const generateRequestSchema = z.object({
  prompt: z.string().min(1).max(500),
  context: z.object({
    genre: z.string().optional(),
    bpm: z.number().optional(),
    key: z.string().optional(),
    includeDrums: z.boolean().optional(),
    includeBass: z.boolean().optional(),
    includeSynth: z.boolean().optional(),
  }).optional(),
});

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {
  // AI Code Generation endpoint - uses Claude if available, falls back to OpenAI
  app.post("/api/generate", async (req, res) => {
    try {
      const { prompt, context } = generateRequestSchema.parse(req.body);
      
      let code: string;
      let provider: string;
      
      if (isAnthropicAvailable()) {
        code = await generateStrudelCodeWithClaude(prompt, context);
        provider = "claude";
      } else if (isOpenAIAvailable()) {
        code = await generateStrudelCode(prompt, context);
        provider = "openai";
      } else {
        return res.status(503).json({
          error: "No AI provider configured. Please set ANTHROPIC_API_KEY or OPENAI_API_KEY environment variable.",
          success: false
        });
      }
      
      res.json({ code, success: true, provider });
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ 
          error: "Invalid request. Prompt must be between 1-500 characters.",
          success: false 
        });
      }
      
      console.error("Generate error:", error);
      res.status(500).json({ 
        error: error instanceof Error ? error.message : "Failed to generate code",
        success: false 
      });
    }
  });
  
  // API status endpoint
  app.get("/api/status", (req, res) => {
    res.json({
      anthropic: isAnthropicAvailable(),
      openai: isOpenAIAvailable(),
      provider: isAnthropicAvailable() ? "claude" : isOpenAIAvailable() ? "openai" : null
    });
  });

  // Code snippets storage endpoints
  app.get("/api/snippets", async (req, res) => {
    try {
      const snippets = await storage.getSnippets();
      res.json({ snippets, success: true });
    } catch (error) {
      console.error("Get snippets error:", error);
      res.status(500).json({ error: "Failed to fetch snippets", success: false });
    }
  });

  app.post("/api/snippets", async (req, res) => {
    try {
      const { insertSnippetSchema } = await import("@shared/schema");
      const validatedData = insertSnippetSchema.parse(req.body);
      
      const snippet = await storage.createSnippet(validatedData);
      res.json({ snippet, success: true });
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({ 
          error: "Invalid snippet data: " + error.errors.map(e => e.message).join(", "),
          success: false 
        });
      }
      console.error("Create snippet error:", error);
      res.status(500).json({ error: "Failed to save snippet", success: false });
    }
  });

  return httpServer;
}
