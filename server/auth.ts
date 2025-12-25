import type { Request, Response, NextFunction } from "express";

// Basic HTTP Authentication middleware
// Credentials are set via environment variables: AUTH_USER and AUTH_PASS

export function basicAuth(req: Request, res: Response, next: NextFunction) {
  const authUser = process.env.AUTH_USER;
  const authPass = process.env.AUTH_PASS;

  // If no credentials are set, skip authentication
  if (!authUser || !authPass) {
    return next();
  }

  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Basic ")) {
    res.setHeader("WWW-Authenticate", 'Basic realm="SAIC - Strudel AI"');
    return res.status(401).send("Authentication required");
  }

  const base64Credentials = authHeader.split(" ")[1];
  const credentials = Buffer.from(base64Credentials, "base64").toString("utf-8");
  const [username, password] = credentials.split(":");

  if (username === authUser && password === authPass) {
    return next();
  }

  res.setHeader("WWW-Authenticate", 'Basic realm="SAIC - Strudel AI"');
  return res.status(401).send("Invalid credentials");
}
