import { Request, Response } from "express";
import * as purchasesService from "../services/purchases.service";

export async function list(req: Request, res: Response): Promise<void> {
  try {
    const purchases = await purchasesService.listPurchases(req.uid!);
    res.json(purchases);
  } catch (error: any) {
    console.error("Purchases list error:", error);
    res.status(500).json({ error: "Failed to list purchases", details: [error.message] });
  }
}

export async function create(req: Request, res: Response): Promise<void> {
  try {
    const { productName, price, quantity, date, workspace } = req.body;
    if (!productName || price == null || quantity == null) {
      res.status(400).json({
        error: "Missing required fields",
        details: ["productName, price, quantity are required"],
      });
      return;
    }
    const purchase = await purchasesService.createPurchase(req.uid!, {
      productName, price, quantity, date, workspace: workspace ?? "",
    });
    res.status(201).json(purchase);
  } catch (error: any) {
    console.error("Purchase create error:", error);
    res.status(500).json({ error: "Failed to create purchase", details: [error.message] });
  }
}
