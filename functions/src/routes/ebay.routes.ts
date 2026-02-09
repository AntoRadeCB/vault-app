import { Router } from "express";
import * as ebayController from "../controllers/ebay.controller";

const router = Router();

// OAuth
router.get("/auth-url", ebayController.getAuthUrl);
router.post("/callback", ebayController.handleCallback);
router.post("/disconnect", ebayController.disconnect);
router.get("/status", ebayController.getStatus);

// Listings
router.post("/listings", ebayController.createListing);
router.get("/listings", ebayController.getListings);
router.put("/listings/:id", ebayController.updateListing);
router.delete("/listings/:id", ebayController.deleteListing);

// Policies
router.get("/policies", ebayController.getPolicies);
router.post("/policies", ebayController.createPolicies);

// Price check (Browse API — no user auth needed)
router.get("/price-check", ebayController.priceCheck);

// Orders
router.get("/orders", ebayController.getOrders);
router.get("/orders/:id", ebayController.getOrderDetail);
router.post("/orders/:id/ship", ebayController.shipOrder);
router.post("/orders/:id/refund", ebayController.refundOrder);

export default router;
