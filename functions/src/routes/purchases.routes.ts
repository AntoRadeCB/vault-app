import { Router } from "express";
import * as purchasesController from "../controllers/purchases.controller";

const router = Router();

router.get("/", purchasesController.list);
router.post("/", purchasesController.create);

export default router;
