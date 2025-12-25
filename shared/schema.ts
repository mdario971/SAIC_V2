import { sql } from "drizzle-orm";
import { pgTable, text, varchar } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

export const users = pgTable("users", {
  id: varchar("id").primaryKey().default(sql`gen_random_uuid()`),
  username: text("username").notNull().unique(),
  password: text("password").notNull(),
});

export const insertUserSchema = createInsertSchema(users).pick({
  username: true,
  password: true,
});

export type InsertUser = z.infer<typeof insertUserSchema>;
export type User = typeof users.$inferSelect;

// Snippet types for in-memory storage
export interface Snippet {
  id: string;
  name: string;
  code: string;
  category?: string;
}

export interface InsertSnippet {
  name: string;
  code: string;
  category?: string;
}

// Zod schemas for validation
export const insertSnippetSchema = z.object({
  name: z.string().min(1, "Name is required").max(100),
  code: z.string().min(1, "Code is required").max(10000),
  category: z.string().max(50).optional(),
});

export type ValidatedInsertSnippet = z.infer<typeof insertSnippetSchema>;
