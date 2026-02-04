import swaggerJsdoc from "swagger-jsdoc";

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "Vault API",
      version: "2.0.0",
      description: "Backend REST API for the Vault App — a reselling tracker for Vinted.",
      contact: {
        name: "Vault Team",
      },
    },
    servers: [
      {
        url: "/",
        description: "Firebase Functions",
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: "http",
          scheme: "bearer",
          bearerFormat: "JWT",
          description: "Firebase ID Token",
        },
      },
      schemas: {
        Error: {
          type: "object",
          properties: {
            error: { type: "string" },
            details: {
              type: "array",
              items: { type: "string" },
            },
          },
          required: ["error"],
        },
        Product: {
          type: "object",
          properties: {
            id: { type: "string" },
            name: { type: "string" },
            brand: { type: "string" },
            quantity: { type: "number" },
            price: { type: "number" },
            status: {
              type: "string",
              enum: ["shipped", "inInventory", "listed"],
            },
            imageUrl: { type: "string", nullable: true },
            barcode: { type: "string", nullable: true },
            createdAt: { type: "string", format: "date-time" },
          },
        },
        ProductInput: {
          type: "object",
          properties: {
            name: { type: "string" },
            brand: { type: "string" },
            quantity: { type: "number" },
            price: { type: "number" },
            status: {
              type: "string",
              enum: ["shipped", "inInventory", "listed"],
            },
            imageUrl: { type: "string" },
            barcode: { type: "string" },
          },
          required: ["name", "brand", "quantity", "price", "status"],
        },
        Purchase: {
          type: "object",
          properties: {
            id: { type: "string" },
            productName: { type: "string" },
            price: { type: "number" },
            quantity: { type: "number" },
            date: { type: "string", format: "date-time" },
            workspace: { type: "string" },
          },
        },
        PurchaseInput: {
          type: "object",
          properties: {
            productName: { type: "string" },
            price: { type: "number" },
            quantity: { type: "number" },
            date: { type: "string", format: "date-time" },
            workspace: { type: "string" },
          },
          required: ["productName", "price", "quantity"],
        },
        Sale: {
          type: "object",
          properties: {
            id: { type: "string" },
            productName: { type: "string" },
            salePrice: { type: "number" },
            purchasePrice: { type: "number" },
            fees: { type: "number" },
            date: { type: "string", format: "date-time" },
          },
        },
        SaleInput: {
          type: "object",
          properties: {
            productName: { type: "string" },
            salePrice: { type: "number" },
            purchasePrice: { type: "number" },
            fees: { type: "number" },
            date: { type: "string", format: "date-time" },
          },
          required: ["productName", "salePrice", "purchasePrice", "fees"],
        },
        TrackingEvent: {
          type: "object",
          properties: {
            status: { type: "string" },
            statusCode: { type: "string", nullable: true },
            statusMilestone: { type: "string", nullable: true },
            timestamp: { type: "string", format: "date-time", nullable: true },
            location: { type: "string", nullable: true },
            description: { type: "string", nullable: true },
            courierCode: { type: "string", nullable: true },
          },
        },
        Shipment: {
          type: "object",
          properties: {
            id: { type: "string" },
            trackingCode: { type: "string" },
            carrier: { type: "string", nullable: true },
            carrierName: { type: "string", nullable: true },
            type: {
              type: "string",
              enum: ["purchase", "sale"],
            },
            productName: { type: "string" },
            productId: { type: "string", nullable: true },
            status: {
              type: "string",
              enum: ["pending", "inTransit", "delivered", "exception", "unknown"],
            },
            createdAt: { type: "string", format: "date-time" },
            lastUpdate: { type: "string", format: "date-time", nullable: true },
            lastEvent: { type: "string", nullable: true },
            trackerId: { type: "string", nullable: true },
            trackingApiStatus: { type: "string", nullable: true },
            trackingHistory: {
              type: "array",
              items: { $ref: "#/components/schemas/TrackingEvent" },
            },
            externalTrackingUrl: { type: "string", nullable: true },
          },
        },
        ShipmentInput: {
          type: "object",
          properties: {
            trackingCode: { type: "string" },
            carrier: { type: "string" },
            carrierName: { type: "string" },
            type: {
              type: "string",
              enum: ["purchase", "sale"],
            },
            productName: { type: "string" },
            productId: { type: "string" },
            status: {
              type: "string",
              enum: ["pending", "inTransit", "delivered", "exception", "unknown"],
            },
          },
          required: ["trackingCode", "productName"],
        },
        AppNotification: {
          type: "object",
          properties: {
            id: { type: "string" },
            title: { type: "string" },
            body: { type: "string" },
            type: {
              type: "string",
              enum: ["shipmentUpdate", "sale", "lowStock", "system"],
            },
            createdAt: { type: "string", format: "date-time" },
            read: { type: "boolean" },
            referenceId: { type: "string", nullable: true },
            metadata: { type: "object", nullable: true },
          },
        },
        Stats: {
          type: "object",
          properties: {
            capitaleImmobilizzato: { type: "number" },
            ordiniInArrivo: { type: "number" },
            capitaleSpedito: { type: "number" },
            profittoConsolidato: { type: "number" },
            salesCount: { type: "number" },
            purchasesCount: { type: "number" },
            totalRevenue: { type: "number" },
            totalSpent: { type: "number" },
            totalFees: { type: "number" },
            inventoryCount: { type: "number" },
            totalQuantity: { type: "number" },
            avgProfitPerSale: { type: "number" },
            bestSale: {
              type: "object",
              nullable: true,
              properties: {
                productName: { type: "string" },
                profit: { type: "number" },
              },
            },
            totalInventoryValue: { type: "number" },
            roi: { type: "number" },
          },
        },
        Profile: {
          type: "object",
          properties: {
            displayName: { type: "string" },
            email: { type: "string" },
            photoUrl: { type: "string" },
          },
          additionalProperties: true,
        },
        UnreadCount: {
          type: "object",
          properties: {
            count: { type: "number" },
          },
        },
      },
    },
    security: [
      {
        bearerAuth: [],
      },
    ],
  },
  apis: ["./lib/docs/*.js"],
};

export const swaggerSpec = swaggerJsdoc(options);
