import { Request, Response } from "express";
import * as productsService from "../services/products.service";

export async function list(req: Request, res: Response): Promise<void> {
  try {
    const products = await productsService.listProducts(req.uid!);
    res.json(products);
  } catch (error: any) {
    console.error("Products list error:", error);
    res.status(500).json({ error: "Failed to list products", details: [error.message] });
  }
}

export async function get(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    const product = await productsService.getProduct(req.uid!, id);
    if (!product) {
      res.status(404).json({ error: "Product not found" });
      return;
    }
    res.json(product);
  } catch (error: any) {
    console.error("Product get error:", error);
    res.status(500).json({ error: "Failed to get product", details: [error.message] });
  }
}

export async function create(req: Request, res: Response): Promise<void> {
  try {
    const { name, brand, quantity, price, status, imageUrl, barcode } = req.body;
    if (!name || !brand || quantity == null || price == null || !status) {
      res.status(400).json({ error: "Missing required fields", details: ["name, brand, quantity, price, status are required"] });
      return;
    }
    const product = await productsService.createProduct(req.uid!, {
      name, brand, quantity, price, status, imageUrl, barcode,
    });
    res.status(201).json(product);
  } catch (error: any) {
    console.error("Product create error:", error);
    res.status(500).json({ error: "Failed to create product", details: [error.message] });
  }
}

export async function update(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    const product = await productsService.updateProduct(req.uid!, id, req.body);
    if (!product) {
      res.status(404).json({ error: "Product not found" });
      return;
    }
    res.json(product);
  } catch (error: any) {
    console.error("Product update error:", error);
    res.status(500).json({ error: "Failed to update product", details: [error.message] });
  }
}

export async function remove(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    const deleted = await productsService.deleteProduct(req.uid!, id);
    if (!deleted) {
      res.status(404).json({ error: "Product not found" });
      return;
    }
    res.json({ success: true });
  } catch (error: any) {
    console.error("Product delete error:", error);
    res.status(500).json({ error: "Failed to delete product", details: [error.message] });
  }
}

export async function findByBarcode(req: Request, res: Response): Promise<void> {
  try {
    const code = req.params.code as string;
    const product = await productsService.findByBarcode(req.uid!, code);
    if (!product) {
      res.status(404).json({ error: "Product not found for barcode" });
      return;
    }
    res.json(product);
  } catch (error: any) {
    console.error("Product barcode search error:", error);
    res.status(500).json({ error: "Failed to search by barcode", details: [error.message] });
  }
}
