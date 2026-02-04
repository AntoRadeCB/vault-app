import { Router } from "express";
import * as salesController from "../controllers/sales.controller";

const router = Router();

router.get("/", salesController.list);
router.post("/", salesController.create);

export default router;
