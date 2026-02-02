/**
 * @swagger
 * tags:
 *   name: Stats
 *   description: Dashboard statistics (computed server-side)
 */

/**
 * @swagger
 * /stats:
 *   get:
 *     summary: Get all dashboard statistics
 *     description: Returns all computed stats in a single call including capital, profits, sales metrics, inventory, and ROI.
 *     tags: [Stats]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard statistics
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Stats'
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
