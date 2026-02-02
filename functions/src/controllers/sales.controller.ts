import { Request, Response } from "express";
import * as salesService from "../services/sales.service";

export async function list(req: Request, res: Response): Promise<void> {
  try {
    const sales = await salesService.listSales(req.uid!);
    res.json(sales);
  } catch (error: any) {
    console.error("Sales list error:", error);
    res.status(500).json({ error: "Failed to list sales", details: [error.message] });
  }
}

export async function create(req: Request, res: Response): Promise<void> {
  try {
    const { productName, salePrice, purchasePrice, fees, date } = req.body;
    if (!productName || salePrice == null || purchasePrice == null || fees == null) {
      res.status(400).json({
        error: "Missing required fields",
        details: ["productName, salePrice, purchasePrice, fees are required"],
      });
      return;
    }
    const sale = await salesService.createSale(req.uid!, {
      productName, salePrice, purchasePrice, fees, date,
    });
    res.status(201).json(sale);
  } catch (error: any) {
    console.error("Sale create error:", error);
    res.status(500).json({ error: "Failed to create sale", details: [error.message] });
  }
}
