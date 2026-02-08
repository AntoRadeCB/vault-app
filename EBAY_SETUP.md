# eBay Integration Setup

## Overview

Vault App's eBay integration allows users to list their TCG cards directly on eBay, manage orders, and track shipments — all from within the app.

The integration uses eBay's **Inventory API**, **Fulfillment API**, and **OAuth 2.0 Authorization Code Grant**.

## Architecture

```
Flutter App → Cloud Functions (Express API) → eBay REST APIs
                    ↕
               Firestore (tokens, listings, orders)
```

## Setup Steps

### 1. Create eBay Developer Account

1. Go to [developer.ebay.com](https://developer.ebay.com)
2. Create an application (sandbox first, then production)
3. Note your **App ID (Client ID)**, **Cert ID (Client Secret)**, and **Dev ID**
4. Set the **OAuth Redirect URI** (RuName):
   - Sandbox: `https://europe-west1-inventorymanager-dev-20262.cloudfunctions.net/api/ebay/callback`
   - Or your custom domain

### 2. Configure Firebase Secrets

```bash
# Set secrets (you'll be prompted for values)
firebase functions:secrets:set EBAY_CLIENT_ID
firebase functions:secrets:set EBAY_CLIENT_SECRET
firebase functions:secrets:set EBAY_REDIRECT_URI

# Optional: for webhook verification
firebase functions:config:set ebay.verification_token="YOUR_TOKEN"
firebase functions:config:set ebay.webhook_endpoint="YOUR_WEBHOOK_URL"
```

### 3. Environment Configuration

The integration defaults to **sandbox mode**. To switch to production:

```bash
# In your Cloud Functions environment
EBAY_SANDBOX=false
```

Or set it in your `.env` / Firebase config.

### 4. eBay Sandbox vs Production

| Setting | Sandbox | Production |
|---------|---------|------------|
| Auth URL | `auth.sandbox.ebay.com` | `auth.ebay.com` |
| API Base | `api.sandbox.ebay.com` | `api.ebay.com` |
| Client ID | Sandbox keys | Production keys |

### 5. Deploy

```bash
cd functions
npm run build
firebase deploy --only functions
```

### 6. eBay Notifications (Webhooks)

1. Go to eBay Developer Portal → Alerts & Notifications
2. Set notification delivery URL to:
   `https://europe-west1-inventorymanager-dev-20262.cloudfunctions.net/ebayWebhook`
3. Subscribe to topics:
   - `marketplace.order.created`
   - `marketplace.order.payment`

## Files Added

### Cloud Functions (`functions/src/`)
- `config/ebay.config.ts` — eBay API configuration & secrets
- `services/ebay.service.ts` — All eBay business logic (OAuth, listings, orders, webhooks)
- `controllers/ebay.controller.ts` — Express request handlers
- `routes/ebay.routes.ts` — Route definitions
- `index.ts` — Updated with eBay routes + standalone webhook endpoint

### Flutter (`lib/`)
- `models/ebay_listing.dart` — EbayListing model
- `models/ebay_order.dart` — EbayOrder model
- `services/ebay_service.dart` — API client for eBay Cloud Functions
- `screens/ebay_screen.dart` — Main eBay management screen (3 tabs)
- `widgets/ebay_listing_dialog.dart` — Create listing dialog
- `widgets/ebay_order_detail.dart` — Order detail bottom sheet
- `screens/inventory_screen.dart` — Updated with "Vendi su eBay" long-press action

## Firestore Collections

```
users/{uid}/integrations/ebay     — OAuth tokens & connection status
users/{uid}/ebayListings/{id}     — Cached eBay listings
users/{uid}/ebayOrders/{id}       — Cached eBay orders
```

## API Endpoints

All under `/api/ebay/` (require Firebase Auth):

| Method | Path | Description |
|--------|------|-------------|
| GET | `/ebay/auth-url` | Get OAuth authorization URL |
| POST | `/ebay/callback` | Exchange auth code for tokens |
| POST | `/ebay/disconnect` | Revoke & delete tokens |
| GET | `/ebay/status` | Connection status |
| POST | `/ebay/listings` | Create listing |
| GET | `/ebay/listings` | Get listings |
| PUT | `/ebay/listings/:id` | Update listing |
| DELETE | `/ebay/listings/:id` | End listing |
| GET | `/ebay/orders` | Fetch & sync orders |
| GET | `/ebay/orders/:id` | Order detail |
| POST | `/ebay/orders/:id/ship` | Mark shipped |
| POST | `/ebay/orders/:id/refund` | Issue refund |

Standalone webhook: `ebayWebhook` Cloud Function (no auth).

## Security Notes

- Tokens are XOR-encrypted in Firestore (replace encryption key in production)
- All API endpoints require Firebase Auth (Bearer token)
- Webhook endpoint validates eBay challenge codes
- Token auto-refresh happens transparently
- Failed refresh → auto-disconnect
