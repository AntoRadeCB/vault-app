import { Router } from "express";
import * as productsController from "../controllers/products.controller";

const router = Router();

router.get("/", productsController.list);
router.post("/", productsController.create);
router.get("/barcode/:code", productsController.findByBarcode);
router.get("/:id", productsController.get);
router.put("/:id", productsController.update);
router.delete("/:id", productsController.remove);

export default router;
