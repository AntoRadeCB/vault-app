import { Request, Response } from "express";
import { db } from "../config/firebase.config";

export async function getProfile(req: Request, res: Response): Promise<void> {
  try {
    const doc = await db.collection("users").doc(req.uid!).get();
    if (!doc.exists) {
      res.json({});
      return;
    }
    const data = doc.data() || {};
    // Remove subcollection references that might be present
    res.json({
      ...data,
      uid: doc.id,
    });
  } catch (error: any) {
    console.error("Profile get error:", error);
    res.status(500).json({ error: "Failed to get profile", details: [error.message] });
  }
}

export async function updateProfile(req: Request, res: Response): Promise<void> {
  try {
    const updates = req.body;
    if (!updates || Object.keys(updates).length === 0) {
      res.status(400).json({ error: "No fields to update" });
      return;
    }
    await db.collection("users").doc(req.uid!).set(updates, { merge: true });
    const doc = await db.collection("users").doc(req.uid!).get();
    res.json({
      ...(doc.data() || {}),
      uid: doc.id,
    });
  } catch (error: any) {
    console.error("Profile update error:", error);
    res.status(500).json({ error: "Failed to update profile", details: [error.message] });
  }
}
