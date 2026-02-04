import { Request, Response } from "express";
import * as shipmentsService from "../services/shipments.service";
import * as trackingService from "../services/tracking.service";
import { defineSecret } from "firebase-functions/params";

const SHIP24_API_KEY = defineSecret("SHIP24_API_KEY");

export async function list(req: Request, res: Response): Promise<void> {
  try {
    const shipments = await shipmentsService.listShipments(req.uid!);
    res.json(shipments);
  } catch (error: any) {
    console.error("Shipments list error:", error);
    res.status(500).json({ error: "Failed to list shipments", details: [error.message] });
  }
}

export async function get(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    const shipment = await shipmentsService.getShipment(req.uid!, id);
    if (!shipment) {
      res.status(404).json({ error: "Shipment not found" });
      return;
    }
    res.json(shipment);
  } catch (error: any) {
    console.error("Shipment get error:", error);
    res.status(500).json({ error: "Failed to get shipment", details: [error.message] });
  }
}

export async function create(req: Request, res: Response): Promise<void> {
  try {
    const { trackingCode, productName, carrier, carrierName, type, productId, status } = req.body;
    if (!trackingCode || !productName) {
      res.status(400).json({
        error: "Missing required fields",
        details: ["trackingCode, productName are required"],
      });
      return;
    }
    const shipment = await shipmentsService.createShipment(req.uid!, {
      trackingCode, productName, carrier, carrierName, type, productId,
      status: status ?? "pending",
    });
    res.status(201).json(shipment);
  } catch (error: any) {
    console.error("Shipment create error:", error);
    res.status(500).json({ error: "Failed to create shipment", details: [error.message] });
  }
}

export async function update(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    const shipment = await shipmentsService.updateShipment(req.uid!, id, req.body);
    if (!shipment) {
      res.status(404).json({ error: "Shipment not found" });
      return;
    }
    res.json(shipment);
  } catch (error: any) {
    console.error("Shipment update error:", error);
    res.status(500).json({ error: "Failed to update shipment", details: [error.message] });
  }
}

export async function remove(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    const deleted = await shipmentsService.deleteShipment(req.uid!, id);
    if (!deleted) {
      res.status(404).json({ error: "Shipment not found" });
      return;
    }
    res.json({ success: true });
  } catch (error: any) {
    console.error("Shipment delete error:", error);
    res.status(500).json({ error: "Failed to delete shipment", details: [error.message] });
  }
}

export async function registerTrackingHandler(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    const shipment = await shipmentsService.getShipment(req.uid!, id);
    if (!shipment) {
      res.status(404).json({ error: "Shipment not found" });
      return;
    }

    const apiKey = SHIP24_API_KEY.value();
    const { courierCode } = req.body;

    const result = await trackingService.registerTracking(
      apiKey,
      shipment.trackingCode,
      courierCode
    );

    // Update shipment with tracker info
    await shipmentsService.updateShipmentTracking(req.uid!, id, {
      trackerId: result.trackerId ?? undefined,
      trackingApiStatus: "registered",
      externalTrackingUrl: `https://t.ship24.com/t/${shipment.trackingCode}`,
    });

    res.json({
      success: true,
      trackerId: result.trackerId,
      trackingNumber: result.trackingNumber,
      isTracked: result.isTracked,
      courierCode: result.courierCode,
    });
  } catch (error: any) {
    console.error("Register tracking error:", error);
    res.status(500).json({ error: "Failed to register tracking", details: [error.message] });
  }
}

export async function getTrackingStatusHandler(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    const shipment = await shipmentsService.getShipment(req.uid!, id);
    if (!shipment) {
      res.status(404).json({ error: "Shipment not found" });
      return;
    }

    const apiKey = SHIP24_API_KEY.value();

    const result = await trackingService.getTrackingStatus(
      apiKey,
      shipment.trackingCode,
      shipment.trackerId ?? undefined
    );

    // Update shipment with latest tracking data
    const appStatus = trackingService.mapMilestoneToAppStatus(result.status);
    await shipmentsService.updateShipmentTracking(req.uid!, id, {
      trackerId: result.trackerId ?? undefined,
      trackingApiStatus: result.status,
      carrier: result.carrier ?? undefined,
      lastEvent: result.trackingHistory.length > 0 ? result.trackingHistory[0].status : undefined,
      trackingHistory: result.trackingHistory,
      externalTrackingUrl: result.trackingUrl,
      status: appStatus,
    });

    res.json(result);
  } catch (error: any) {
    console.error("Get tracking status error:", error);
    res.status(500).json({ error: "Failed to get tracking status", details: [error.message] });
  }
}
