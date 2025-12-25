import type { Express } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { generateStrudelCode } from "./openai";
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
  // AI Code Generation endpoint
  app.post("/api/generate", async (req, res) => {
    try {
      const { prompt, context } = generateRequestSchema.parse(req.body);
      
      const code = await generateStrudelCode(prompt, context);
      
      res.json({ code, success: true });
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
