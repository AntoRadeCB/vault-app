import { Router } from "express";
import * as shipmentsController from "../controllers/shipments.controller";

const router = Router();

router.get("/", shipmentsController.list);
router.post("/", shipmentsController.create);
router.get("/:id", shipmentsController.get);
router.put("/:id", shipmentsController.update);
router.delete("/:id", shipmentsController.remove);
router.post("/:id/register-tracking", shipmentsController.registerTrackingHandler);
router.get("/:id/tracking-status", shipmentsController.getTrackingStatusHandler);

export default router;
