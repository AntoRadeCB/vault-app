import { Request, Response, NextFunction } from "express";
import { auth } from "../config/firebase.config";

// Extend Express Request to include uid
declare global {
  namespace Express {
    interface Request {
      uid?: string;
    }
  }
}

export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({ error: "Missing or invalid Authorization header" });
    return;
  }

  const token = authHeader.split("Bearer ")[1];

  if (!token) {
    res.status(401).json({ error: "Missing token" });
    return;
  }

  try {
    const decoded = await auth.verifyIdToken(token);
    req.uid = decoded.uid;
    next();
  } catch (error: any) {
    console.error("Auth error:", error.message);
    res.status(401).json({ error: "Invalid or expired token" });
    return;
  }
}
