import { defineSecret } from "firebase-functions/params";

// ── eBay Secrets (set via `firebase functions:secrets:set`) ──
export const EBAY_CLIENT_ID = defineSecret("EBAY_CLIENT_ID");
export const EBAY_CLIENT_SECRET = defineSecret("EBAY_CLIENT_SECRET");
export const EBAY_REDIRECT_URI = defineSecret("EBAY_REDIRECT_URI");

// ── Helper functions to read secret values at runtime ──
export function getEbayClientId(): string {
  return EBAY_CLIENT_ID.value();
}
export function getEbayClientSecret(): string {
  return EBAY_CLIENT_SECRET.value();
}
export function getEbayRedirectUri(): string {
  return EBAY_REDIRECT_URI.value();
}

// ── Sandbox toggle ──
// Set to "false" in production environment config
const EBAY_SANDBOX = process.env.EBAY_SANDBOX !== "false";

export function getEbayConfig() {
  const sandbox = EBAY_SANDBOX;
  return {
    sandbox,
    authUrl: sandbox
      ? "https://auth.sandbox.ebay.com/oauth2/authorize"
      : "https://auth.ebay.com/oauth2/authorize",
    tokenUrl: sandbox
      ? "https://api.sandbox.ebay.com/identity/v1/oauth2/token"
      : "https://api.ebay.com/identity/v1/oauth2/token",
    apiBase: sandbox
      ? "https://api.sandbox.ebay.com"
      : "https://api.ebay.com",
    scopes: [
      "https://api.ebay.com/oauth/api_scope",
      "https://api.ebay.com/oauth/api_scope/sell.inventory",
      "https://api.ebay.com/oauth/api_scope/sell.marketing",
      "https://api.ebay.com/oauth/api_scope/sell.account",
      "https://api.ebay.com/oauth/api_scope/sell.fulfillment",
      "https://api.ebay.com/oauth/api_scope/sell.finances",
    ],
  };
}
