import { Request, Response } from "express";
import * as ebayService from "../services/ebay.service";

// ── OAuth ──

export async function getAuthUrl(req: Request, res: Response): Promise<void> {
  try {
    const url = ebayService.generateAuthUrl();
    res.json({ url });
  } catch (error: any) {
    console.error("ebay/auth-url error:", error.message);
    res.status(500).json({ error: error.message });
  }
}

export async function handleCallback(req: Request, res: Response): Promise<void> {
  try {
    const { code } = req.body;
    if (!code) {
      res.status(400).json({ error: "Missing authorization code" });
      return;
    }
    const result = await ebayService.handleCallback(req.uid!, code);
    res.json(result);
  } catch (error: any) {
    console.error("ebay/callback error:", error.message);
    res.status(500).json({ error: error.message });
  }
}

export async function disconnect(req: Request, res: Response): Promise<void> {
  try {
    await ebayService.disconnect(req.uid!);
    res.json({ success: true });
  } catch (error: any) {
    console.error("ebay/disconnect error:", error.message);
    res.status(500).json({ error: error.message });
  }
}

export async function getStatus(req: Request, res: Response): Promise<void> {
  try {
    const status = await ebayService.getConnectionStatus(req.uid!);
    res.json(status);
  } catch (error: any) {
    console.error("ebay/status error:", error.message);
    res.status(500).json({ error: error.message });
  }
}

// ── Listings ──

export async function createListing(req: Request, res: Response): Promise<void> {
  try {
    const result = await ebayService.createListing(req.uid!, req.body);
    res.status(201).json(result);
  } catch (error: any) {
    console.error("ebay/listings POST error:", error.message);
    res.status(500).json({ error: error.message });
  }
}

export async function getListings(req: Request, res: Response): Promise<void> {
  try {
    const listings = await ebayService.getListings(req.uid!);
    res.json({ listings });
  } catch (error: any) {
    console.error("ebay/listings GET error:", error.message);
    res.status(500).json({ error: error.message });
  }
}

export async function updateListing(req: Request, res: Response): Promise<void> {
  try {
    await ebayService.updateListing(req.uid!, req.params.id as string, req.body);
    res.json({ success: true });
  } catch (error: any) {
    console.error("ebay/listings PUT error:", error.message);
    res.status(500).json({ error: error.message });
  }
}

export async function deleteListing(req: Request, res: Response): Promise<void> {
  try {
    await ebayService.deleteListing(req.uid!, req.params.id as string);
    res.json({ success: true });
  } catch (error: any) {
    console.error("ebay/listings DELETE error:", error.message);
    res.status(500).json({ error: error.message });
  }
}

// ── Orders ──

export async function getOrders(req: Request, res: Response): Promise<void> {
  try {
    const orders = await ebayService.getOrders(req.uid!);
    res.json({ orders });
  } catch (error: any) {
    console.error("ebay/orders GET error:", error.message);
    res.status(500).json({ error: error.message });
  }
}

export async function getOrderDetail(req: Request, res: Response): Promise<void> {
  try {
    const order = await ebayService.getOrderDetail(req.uid!, req.params.id as string);
    res.json(order);
  } catch (error: any) {
    console.error("ebay/orders/:id GET error:", error.message);
    res.status(500).json({ error: error.message });
  }
}

export async function shipOrder(req: Request, res: Response): Promise<void> {
  try {
    const { trackingNumber, carrier } = req.body;
    if (!trackingNumber || !carrier) {
      res.status(400).json({ error: "Missing trackingNumber or carrier" });
      return;
    }
    const result = await ebayService.shipOrder(
      req.uid!,
      req.params.id as string,
      trackingNumber,
      carrier
    );
    res.json(result);
  } catch (error: any) {
    console.error("ebay/orders/:id/ship error:", error.message);
    res.status(500).json({ error: error.message });
  }
}

export async function refundOrder(req: Request, res: Response): Promise<void> {
  try {
    const { reason, amount } = req.body;
    const result = await ebayService.refundOrder(
      req.uid!,
      req.params.id as string,
      reason,
      amount
    );
    res.json(result);
  } catch (error: any) {
    console.error("ebay/orders/:id/refund error:", error.message);
    res.status(500).json({ error: error.message });
  }
}

// ── Webhook (no auth) ──

export async function handleWebhook(req: Request, res: Response): Promise<void> {
  try {
    // eBay webhook verification challenge
    if (req.query.challenge_code) {
      const crypto = await import("crypto");
      const verificationToken = process.env.EBAY_VERIFICATION_TOKEN || "";
      const endpoint = process.env.EBAY_WEBHOOK_ENDPOINT || "";
      const hash = crypto
        .createHash("sha256")
        .update(req.query.challenge_code as string)
        .update(verificationToken)
        .update(endpoint)
        .digest("hex");
      res.json({ challengeResponse: hash });
      return;
    }

    await ebayService.handleWebhookNotification(req.body);
    res.status(200).json({ status: "ok" });
  } catch (error: any) {
    console.error("ebay/notifications webhook error:", error.message);
    // Always return 200 to eBay to prevent retries
    res.status(200).json({ status: "error", message: error.message });
  }
}

// ── Policies ──

export async function getPolicies(req: Request, res: Response): Promise<void> {
  try {
    const policies = await ebayService.getPolicies(req.uid!);
    res.json(policies);
  } catch (error: any) {
    console.error("ebay/policies GET error:", error.message);
    res.status(500).json({ error: error.message });
  }
}

export async function createPolicies(req: Request, res: Response): Promise<void> {
  try {
    const result = await ebayService.createDefaultPolicies(req.uid!, req.body);
    res.json(result);
  } catch (error: any) {
    console.error("ebay/policies POST error:", error.message);
    res.status(500).json({ error: error.message });
  }
}

// ── Price Check (Browse API — no user auth needed) ──

export async function priceCheck(req: Request, res: Response): Promise<void> {
  try {
    const query = req.query.q as string;
    const limit = parseInt(req.query.limit as string) || 10;

    if (!query) {
      res.status(400).json({ error: "Missing query parameter 'q'" });
      return;
    }

    const result = await ebayService.searchSoldItems(query, limit);
    res.json(result);
  } catch (error: any) {
    console.error("ebay/price-check error:", error.message);
    res.status(500).json({ error: error.message });
  }
}
