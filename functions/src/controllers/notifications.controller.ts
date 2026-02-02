import { Request, Response } from "express";
import * as notificationsService from "../services/notifications.service";

export async function list(req: Request, res: Response): Promise<void> {
  try {
    const notifications = await notificationsService.listNotifications(req.uid!);
    res.json(notifications);
  } catch (error: any) {
    console.error("Notifications list error:", error);
    res.status(500).json({ error: "Failed to list notifications", details: [error.message] });
  }
}

export async function unreadCount(req: Request, res: Response): Promise<void> {
  try {
    const count = await notificationsService.getUnreadCount(req.uid!);
    res.json({ count });
  } catch (error: any) {
    console.error("Notifications unread count error:", error);
    res.status(500).json({ error: "Failed to get unread count", details: [error.message] });
  }
}

export async function markAsRead(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    const success = await notificationsService.markAsRead(req.uid!, id);
    if (!success) {
      res.status(404).json({ error: "Notification not found" });
      return;
    }
    res.json({ success: true });
  } catch (error: any) {
    console.error("Notification mark read error:", error);
    res.status(500).json({ error: "Failed to mark notification as read", details: [error.message] });
  }
}

export async function remove(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    const success = await notificationsService.deleteNotification(req.uid!, id);
    if (!success) {
      res.status(404).json({ error: "Notification not found" });
      return;
    }
    res.json({ success: true });
  } catch (error: any) {
    console.error("Notification delete error:", error);
    res.status(500).json({ error: "Failed to delete notification", details: [error.message] });
  }
}

export async function clearAll(req: Request, res: Response): Promise<void> {
  try {
    const count = await notificationsService.clearAllNotifications(req.uid!);
    res.json({ success: true, deleted: count });
  } catch (error: any) {
    console.error("Notifications clear all error:", error);
    res.status(500).json({ error: "Failed to clear notifications", details: [error.message] });
  }
}
