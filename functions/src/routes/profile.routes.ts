import { Router } from "express";
import * as profileController from "../controllers/profile.controller";

const router = Router();

router.get("/", profileController.getProfile);
router.put("/", profileController.updateProfile);

export default router;
