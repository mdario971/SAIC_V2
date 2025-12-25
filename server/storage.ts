import { type User, type InsertUser, type Snippet, type InsertSnippet } from "@shared/schema";
import { randomUUID } from "crypto";

export interface IStorage {
  getUser(id: string): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;
  getSnippets(): Promise<Snippet[]>;
  getSnippet(id: string): Promise<Snippet | undefined>;
  createSnippet(snippet: InsertSnippet): Promise<Snippet>;
  deleteSnippet(id: string): Promise<boolean>;
}

export class MemStorage implements IStorage {
  private users: Map<string, User>;
  private snippets: Map<string, Snippet>;

  constructor() {
    this.users = new Map();
    this.snippets = new Map();
  }

  async getUser(id: string): Promise<User | undefined> {
    return this.users.get(id);
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    return Array.from(this.users.values()).find(
      (user) => user.username === username,
    );
  }

  async createUser(insertUser: InsertUser): Promise<User> {
    const id = randomUUID();
    const user: User = { ...insertUser, id };
    this.users.set(id, user);
    return user;
  }

  async getSnippets(): Promise<Snippet[]> {
    return Array.from(this.snippets.values());
  }

  async getSnippet(id: string): Promise<Snippet | undefined> {
    return this.snippets.get(id);
  }

  async createSnippet(insertSnippet: InsertSnippet): Promise<Snippet> {
    const id = randomUUID();
    const snippet: Snippet = { ...insertSnippet, id };
    this.snippets.set(id, snippet);
    return snippet;
  }

  async deleteSnippet(id: string): Promise<boolean> {
    return this.snippets.delete(id);
  }
}

export const storage = new MemStorage();
