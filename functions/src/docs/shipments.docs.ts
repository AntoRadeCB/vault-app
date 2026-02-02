/**
 * @swagger
 * tags:
 *   name: Shipments
 *   description: Shipment and tracking management
 */

/**
 * @swagger
 * /shipments:
 *   get:
 *     summary: List all shipments
 *     tags: [Shipments]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Array of shipments ordered by createdAt desc
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Shipment'
 *       401:
 *         description: Unauthorized
 *   post:
 *     summary: Create a shipment
 *     tags: [Shipments]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ShipmentInput'
 *     responses:
 *       201:
 *         description: Created shipment
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Shipment'
 *       400:
 *         description: Missing required fields
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Unauthorized
 */

/**
 * @swagger
 * /shipments/{id}:
 *   get:
 *     summary: Get a shipment by ID
 *     tags: [Shipments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Shipment ID
 *     responses:
 *       200:
 *         description: Shipment details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Shipment'
 *       404:
 *         description: Shipment not found
 *       401:
 *         description: Unauthorized
 *   put:
 *     summary: Update a shipment
 *     tags: [Shipments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Shipment ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ShipmentInput'
 *     responses:
 *       200:
 *         description: Updated shipment
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Shipment'
 *       404:
 *         description: Shipment not found
 *       401:
 *         description: Unauthorized
 *   delete:
 *     summary: Delete a shipment
 *     tags: [Shipments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Shipment ID
 *     responses:
 *       200:
 *         description: Deletion confirmed
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *       404:
 *         description: Shipment not found
 *       401:
 *         description: Unauthorized
 */

/**
 * @swagger
 * /shipments/{id}/register-tracking:
 *   post:
 *     summary: Register tracking on Ship24
 *     tags: [Shipments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Shipment ID
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               courierCode:
 *                 type: string
 *                 description: Optional courier code hint
 *     responses:
 *       200:
 *         description: Tracking registered
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 trackerId:
 *                   type: string
 *                   nullable: true
 *                 trackingNumber:
 *                   type: string
 *                 isTracked:
 *                   type: boolean
 *                 courierCode:
 *                   type: array
 *                   items:
 *                     type: string
 *       404:
 *         description: Shipment not found
 *       401:
 *         description: Unauthorized
 */

/**
 * @swagger
 * /shipments/{id}/tracking-status:
 *   get:
 *     summary: Get tracking status from Ship24
 *     tags: [Shipments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Shipment ID
 *     responses:
 *       200:
 *         description: Tracking status details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 trackerId:
 *                   type: string
 *                   nullable: true
 *                 trackingNumber:
 *                   type: string
 *                 status:
 *                   type: string
 *                 statusCode:
 *                   type: string
 *                   nullable: true
 *                 statusCategory:
 *                   type: string
 *                   nullable: true
 *                 carrier:
 *                   type: string
 *                   nullable: true
 *                 carrierName:
 *                   type: string
 *                   nullable: true
 *                 trackingUrl:
 *                   type: string
 *                 trackingHistory:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/TrackingEvent'
 *                 estimatedDelivery:
 *                   type: string
 *                   nullable: true
 *                 originCountry:
 *                   type: string
 *                   nullable: true
 *                 destinationCountry:
 *                   type: string
 *                   nullable: true
 *       404:
 *         description: Shipment not found
 *       401:
 *         description: Unauthorized
 */
