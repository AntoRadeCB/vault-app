import { Request, Response } from "express";
import * as statsService from "../services/stats.service";

export async function getStats(req: Request, res: Response): Promise<void> {
  try {
    const stats = await statsService.computeStats(req.uid!);
    res.json(stats);
  } catch (error: any) {
    console.error("Stats error:", error);
    res.status(500).json({ error: "Failed to compute stats", details: [error.message] });
  }
}
