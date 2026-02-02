import { Router } from "express";
import * as notificationsController from "../controllers/notifications.controller";

const router = Router();

router.get("/", notificationsController.list);
router.get("/unread/count", notificationsController.unreadCount);
router.delete("/", notificationsController.clearAll);
router.put("/:id/read", notificationsController.markAsRead);
router.delete("/:id", notificationsController.remove);

export default router;
