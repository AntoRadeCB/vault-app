import { db } from "../config/firebase.config";
import {
  getEbayConfig,
  getEbayClientId,
  getEbayClientSecret,
  getEbayRedirectUri,
} from "../config/ebay.config";
import { FieldValue } from "firebase-admin/firestore";

// ── Simple XOR encryption for token storage ──
const ENCRYPTION_KEY = "vault-ebay-token-key-v1"; // Replace with a proper key in production

function xorEncrypt(text: string): string {
  let result = "";
  for (let i = 0; i < text.length; i++) {
    result += String.fromCharCode(
      text.charCodeAt(i) ^ ENCRYPTION_KEY.charCodeAt(i % ENCRYPTION_KEY.length)
    );
  }
  return Buffer.from(result, "binary").toString("base64");
}

function xorDecrypt(encoded: string): string {
  const text = Buffer.from(encoded, "base64").toString("binary");
  let result = "";
  for (let i = 0; i < text.length; i++) {
    result += String.fromCharCode(
      text.charCodeAt(i) ^ ENCRYPTION_KEY.charCodeAt(i % ENCRYPTION_KEY.length)
    );
  }
  return result;
}

// ── Token helpers ──

interface EbayTokens {
  accessToken: string;
  refreshToken: string;
  expiresAt: number; // epoch ms
  ebayUserId?: string;
  connected: boolean;
}

function integrationRef(uid: string) {
  return db.collection("users").doc(uid).collection("integrations").doc("ebay");
}

async function storeTokens(uid: string, tokens: EbayTokens): Promise<void> {
  await integrationRef(uid).set({
    accessToken: xorEncrypt(tokens.accessToken),
    refreshToken: xorEncrypt(tokens.refreshToken),
    expiresAt: tokens.expiresAt,
    ebayUserId: tokens.ebayUserId || null,
    connected: true,
    updatedAt: FieldValue.serverTimestamp(),
  });
}

async function getTokens(uid: string): Promise<EbayTokens | null> {
  const doc = await integrationRef(uid).get();
  if (!doc.exists) return null;
  const data = doc.data()!;
  if (!data.connected) return null;
  return {
    accessToken: xorDecrypt(data.accessToken),
    refreshToken: xorDecrypt(data.refreshToken),
    expiresAt: data.expiresAt,
    ebayUserId: data.ebayUserId,
    connected: data.connected,
  };
}

async function deleteTokens(uid: string): Promise<void> {
  await integrationRef(uid).set({ connected: false, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
}

// ── eBay API calls ──

async function exchangeCodeForTokens(code: string): Promise<{
  access_token: string;
  refresh_token: string;
  expires_in: number;
}> {
  const config = getEbayConfig();
  const clientId = getEbayClientId();
  const clientSecret = getEbayClientSecret();
  const redirectUri = getEbayRedirectUri();

  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");

  const res = await fetch(config.tokenUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Authorization: `Basic ${credentials}`,
    },
    body: new URLSearchParams({
      grant_type: "authorization_code",
      code,
      redirect_uri: redirectUri,
    }).toString(),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`eBay token exchange failed (${res.status}): ${text}`);
  }

  return res.json();
}

async function refreshAccessToken(refreshToken: string): Promise<{
  access_token: string;
  expires_in: number;
}> {
  const config = getEbayConfig();
  const clientId = getEbayClientId();
  const clientSecret = getEbayClientSecret();
  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");

  const res = await fetch(config.tokenUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Authorization: `Basic ${credentials}`,
    },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: refreshToken,
      scope: getEbayConfig().scopes.join(" "),
    }).toString(),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`eBay token refresh failed (${res.status}): ${text}`);
  }

  return res.json();
}

/**
 * Get a valid access token for the user, refreshing if expired.
 * Returns null if user is not connected.
 */
export async function getValidAccessToken(uid: string): Promise<string | null> {
  const tokens = await getTokens(uid);
  if (!tokens) return null;

  // Refresh if expiring within 5 minutes
  if (Date.now() > tokens.expiresAt - 5 * 60 * 1000) {
    try {
      const refreshed = await refreshAccessToken(tokens.refreshToken);
      const newTokens: EbayTokens = {
        accessToken: refreshed.access_token,
        refreshToken: tokens.refreshToken,
        expiresAt: Date.now() + refreshed.expires_in * 1000,
        ebayUserId: tokens.ebayUserId,
        connected: true,
      };
      await storeTokens(uid, newTokens);
      return refreshed.access_token;
    } catch (err) {
      console.error("Failed to refresh eBay token:", err);
      // If refresh fails, mark as disconnected
      await deleteTokens(uid);
      return null;
    }
  }

  return tokens.accessToken;
}

async function ebayApiFetch(
  accessToken: string,
  path: string,
  options: { method?: string; body?: any; headers?: Record<string, string> } = {}
): Promise<any> {
  const config = getEbayConfig();
  const url = `${config.apiBase}${path}`;
  const method = options.method || "GET";

  const headers: Record<string, string> = {
    Authorization: `Bearer ${accessToken}`,
    "Content-Type": "application/json",
    Accept: "application/json",
    "Accept-Language": "it-IT",
    "Content-Language": "it-IT",
    ...options.headers,
  };

  // Add marketplace header for sell APIs
  if (path.includes("/sell/")) {
    headers["X-EBAY-C-MARKETPLACE-ID"] = "EBAY_IT";
  }

  const res = await fetch(url, {
    method,
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  // Handle 204 No Content
  if (res.status === 204) return null;

  const text = await res.text();
  if (!res.ok) {
    throw new Error(`eBay API ${method} ${path} failed (${res.status}): ${text}`);
  }

  return text ? JSON.parse(text) : null;
}

// ══════════════════════════════════════════════════
// Exported service functions
// ══════════════════════════════════════════════════

export function generateAuthUrl(): string {
  const config = getEbayConfig();
  const clientId = getEbayClientId();
  const redirectUri = getEbayRedirectUri();

  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: "code",
    scope: config.scopes.join(" "),
  });

  return `${config.authUrl}?${params.toString()}`;
}

export async function handleCallback(
  uid: string,
  code: string
): Promise<{ success: boolean; ebayUserId?: string }> {
  const tokenData = await exchangeCodeForTokens(code);

  const tokens: EbayTokens = {
    accessToken: tokenData.access_token,
    refreshToken: tokenData.refresh_token,
    expiresAt: Date.now() + tokenData.expires_in * 1000,
    connected: true,
  };

  await storeTokens(uid, tokens);

  // Optionally fetch eBay user info
  try {
    const accessToken = tokenData.access_token;
    const config = getEbayConfig();
    const userRes = await fetch(`${config.apiBase}/commerce/identity/v1/user/`, {
      headers: { Authorization: `Bearer ${accessToken}`, Accept: "application/json" },
    });
    if (userRes.ok) {
      const userData = await userRes.json();
      const ebayUserId = userData.username || userData.userId;
      if (ebayUserId) {
        tokens.ebayUserId = ebayUserId;
        await storeTokens(uid, tokens);
      }
      return { success: true, ebayUserId };
    }
  } catch (e) {
    console.warn("Could not fetch eBay user info:", e);
  }

  return { success: true };
}

export async function disconnect(uid: string): Promise<void> {
  // Try to revoke the token (best effort)
  const tokens = await getTokens(uid);
  if (tokens) {
    try {
      const config = getEbayConfig();
      const clientId = getEbayClientId();
      const clientSecret = getEbayClientSecret();
      const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");

      await fetch(`${config.tokenUrl.replace("/token", "/revoke")}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          Authorization: `Basic ${credentials}`,
        },
        body: new URLSearchParams({
          token: tokens.refreshToken,
          token_type_hint: "refresh_token",
        }).toString(),
      });
    } catch (e) {
      console.warn("eBay token revocation failed (non-critical):", e);
    }
  }
  await deleteTokens(uid);
}

export async function getConnectionStatus(uid: string): Promise<{
  connected: boolean;
  ebayUserId?: string;
}> {
  const doc = await integrationRef(uid).get();
  if (!doc.exists) return { connected: false };
  const data = doc.data()!;
  return { connected: !!data.connected, ebayUserId: data.ebayUserId };
}

// ── Condition mapping ──
// Category 183454 (single trading cards) only accepts specific conditionIds.
// We map to eBay conditionEnum values; for TCG categories, "UNGRADED" is the safe default.
function mapCondition(condition: string, categoryId?: string): string {
  // TCG single cards categories use different condition values
  const tcgCategories = ["183454", "183456", "183457"];
  if (categoryId && tcgCategories.includes(categoryId)) {
    // For TCG cards: valid conditions are typically 4000 (Ungraded), 3000 (Graded)
    // The Inventory API uses enum strings, not IDs
    return "LIKE_NEW"; // Maps to conditionId 2750, accepted for some card categories
  }
  
  const map: Record<string, string> = {
    "NEW": "NEW",
    "LIKE_NEW": "LIKE_NEW",
    "USED_EXCELLENT": "LIKE_NEW",
    "USED_VERY_GOOD": "VERY_GOOD",
    "USED_GOOD": "GOOD",
    "USED_ACCEPTABLE": "ACCEPTABLE",
  };
  return map[condition] || "LIKE_NEW";
}

// ── Inventory / Listings ──

export async function createListing(
  uid: string,
  productData: {
    productId: string;
    title: string;
    description: string;
    price: number;
    currency?: string;
    quantity?: number;
    condition: string;
    conditionDescription?: string;
    categoryId: string;
    imageUrls: string[];
    shippingProfileId?: string;
    returnProfileId?: string;
    paymentProfileId?: string;
    aspects?: Record<string, string[]>;
  }
): Promise<{ success: boolean; listingId?: string; ebayItemId?: string }> {
  const accessToken = await getValidAccessToken(uid);
  if (!accessToken) throw new Error("eBay not connected");

  const sku = `vault-${productData.productId}-${Date.now()}`;

  // 1. Create inventory item
  const isTcgCategory = ["183454", "183456", "183457"].includes(productData.categoryId);
  
  await ebayApiFetch(accessToken, `/sell/inventory/v1/inventory_item/${sku}`, {
    method: "PUT",
    body: {
      product: {
        title: productData.title,
        description: productData.description,
        imageUrls: productData.imageUrls,
        // Item specifics required by eBay for TCG categories
        ...(isTcgCategory ? {
          aspects: {
            "Gioco": ["Pokémon"],
            "Lingua": ["Italiano"],
            "Rarità": ["Non specificato"],
            ...(productData.aspects || {}),
          },
        } : {}),
      },
      // TCG cards (183454): valid conditionIds are 2750(Graded/LIKE_NEW), 3000(Used), 4000(Ungraded)
      // For TCG: LIKE_NEW maps to 2750 ("Valutata/Graded") which is accepted
      condition: isTcgCategory ? "LIKE_NEW" : mapCondition(productData.condition, productData.categoryId),
      conditionDescription: productData.conditionDescription,
      availability: {
        shipToLocationAvailability: {
          quantity: productData.quantity || 1,
        },
      },
    },
  });

  // 2. Create offer
  // Ensure merchant location exists
  const locationKey = "vault-default-location";
  try {
    await ebayApiFetch(accessToken, `/sell/inventory/v1/location/${locationKey}`, {
      method: "POST",
      body: {
        location: {
          address: {
            city: "Roma",
            stateOrProvince: "RM",
            postalCode: "00100",
            country: "IT",
          },
        },
        locationTypes: ["WAREHOUSE"],
        name: "Vault Default Location",
        merchantLocationStatus: "ENABLED",
      },
    });
  } catch (_) {
    // Location may already exist — that's fine
  }

  const offerData = await ebayApiFetch(accessToken, "/sell/inventory/v1/offer", {
    method: "POST",
    body: {
      sku,
      marketplaceId: "EBAY_IT",
      format: "FIXED_PRICE",
      merchantLocationKey: locationKey,
      listingDescription: productData.description,
      availableQuantity: productData.quantity || 1,
      categoryId: productData.categoryId,
      pricingSummary: {
        price: {
          value: productData.price.toFixed(2),
          currency: productData.currency || "EUR",
        },
      },
      listingPolicies: await (async () => {
        // Use provided IDs, or fall back to saved policies
        const saved = await getSavedPolicies(uid);
        const policies: any = {
          fulfillmentPolicyId: productData.shippingProfileId || saved?.fulfillmentPolicyId || undefined,
          returnPolicyId: productData.returnProfileId || saved?.returnPolicyId || undefined,
        };
        const paymentId = productData.paymentProfileId || saved?.paymentPolicyId;
        if (paymentId) policies.paymentPolicyId = paymentId;
        return policies;
      })(),
    },
  });

  const offerId = offerData?.offerId;
  if (!offerId) throw new Error("Failed to create eBay offer");

  // 3. Publish offer
  let ebayItemId: string | undefined;
  let publishError: string | undefined;
  try {
    console.log("[createListing] Publishing offer:", offerId);
    const publishResult = await ebayApiFetch(
      accessToken,
      `/sell/inventory/v1/offer/${offerId}/publish`,
      { method: "POST" }
    );
    ebayItemId = publishResult?.listingId;
    console.log("[createListing] Published! itemId:", ebayItemId);
  } catch (err: any) {
    publishError = err.message;
    console.error("[createListing] Failed to publish offer:", err.message);
    // Still save the listing in draft state
  }

  // 4. Store in Firestore
  const listingRef = db
    .collection("users")
    .doc(uid)
    .collection("ebayListings")
    .doc();

  await listingRef.set({
    productId: productData.productId,
    sku,
    offerId,
    ebayItemId: ebayItemId || null,
    title: productData.title,
    description: productData.description,
    price: productData.price,
    currency: productData.currency || "EUR",
    quantity: productData.quantity || 1,
    condition: productData.condition,
    categoryId: productData.categoryId,
    imageUrls: productData.imageUrls,
    status: ebayItemId ? "active" : "draft",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    listingId: listingRef.id,
    ebayItemId,
  };
}

export async function getListings(uid: string): Promise<any[]> {
  // Get from Firestore (our cached copy)
  const snap = await db
    .collection("users")
    .doc(uid)
    .collection("ebayListings")
    .orderBy("createdAt", "desc")
    .get();

  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function updateListing(
  uid: string,
  listingId: string,
  updates: { price?: number; quantity?: number; description?: string }
): Promise<void> {
  const accessToken = await getValidAccessToken(uid);
  if (!accessToken) throw new Error("eBay not connected");

  const listingDoc = await db
    .collection("users")
    .doc(uid)
    .collection("ebayListings")
    .doc(listingId)
    .get();

  if (!listingDoc.exists) throw new Error("Listing not found");

  const listing = listingDoc.data()!;

  if (listing.offerId) {
    const offerUpdate: any = {};
    if (updates.price !== undefined) {
      offerUpdate.pricingSummary = {
        price: { value: updates.price.toFixed(2), currency: listing.currency || "EUR" },
      };
    }
    if (updates.quantity !== undefined) {
      offerUpdate.availableQuantity = updates.quantity;
    }
    if (updates.description !== undefined) {
      offerUpdate.listingDescription = updates.description;
    }

    await ebayApiFetch(
      accessToken,
      `/sell/inventory/v1/offer/${listing.offerId}`,
      { method: "PUT", body: { ...offerUpdate, marketplaceId: "EBAY_IT", sku: listing.sku, format: "FIXED_PRICE", categoryId: listing.categoryId } }
    );
  }

  // Update Firestore
  const firestoreUpdates: any = { updatedAt: FieldValue.serverTimestamp() };
  if (updates.price !== undefined) firestoreUpdates.price = updates.price;
  if (updates.quantity !== undefined) firestoreUpdates.quantity = updates.quantity;
  if (updates.description !== undefined) firestoreUpdates.description = updates.description;

  await db
    .collection("users")
    .doc(uid)
    .collection("ebayListings")
    .doc(listingId)
    .update(firestoreUpdates);
}

export async function deleteListing(uid: string, listingId: string): Promise<void> {
  const accessToken = await getValidAccessToken(uid);
  if (!accessToken) throw new Error("eBay not connected");

  const listingDoc = await db
    .collection("users")
    .doc(uid)
    .collection("ebayListings")
    .doc(listingId)
    .get();

  if (!listingDoc.exists) throw new Error("Listing not found");

  const listing = listingDoc.data()!;

  // Withdraw offer if published
  if (listing.offerId) {
    try {
      await ebayApiFetch(
        accessToken,
        `/sell/inventory/v1/offer/${listing.offerId}/withdraw`,
        { method: "POST" }
      );
    } catch (err: any) {
      console.warn("Could not withdraw offer:", err.message);
    }
  }

  // Delete inventory item
  if (listing.sku) {
    try {
      await ebayApiFetch(
        accessToken,
        `/sell/inventory/v1/inventory_item/${listing.sku}`,
        { method: "DELETE" }
      );
    } catch (err: any) {
      console.warn("Could not delete inventory item:", err.message);
    }
  }

  // Update Firestore
  await db
    .collection("users")
    .doc(uid)
    .collection("ebayListings")
    .doc(listingId)
    .update({ status: "ended", updatedAt: FieldValue.serverTimestamp() });
}

// ── Orders ──

export async function getOrders(uid: string, limit = 50): Promise<any[]> {
  const accessToken = await getValidAccessToken(uid);
  if (!accessToken) throw new Error("eBay not connected");

  const result = await ebayApiFetch(
    accessToken,
    `/sell/fulfillment/v1/order?limit=${limit}&orderBy=creationdate%20desc`
  );

  const orders = result?.orders || [];

  // Sync to Firestore
  const batch = db.batch();
  for (const order of orders) {
    const orderRef = db
      .collection("users")
      .doc(uid)
      .collection("ebayOrders")
      .doc(order.orderId);

    batch.set(
      orderRef,
      {
        ebayOrderId: order.orderId,
        status: order.orderFulfillmentStatus || "NOT_STARTED",
        paymentStatus: order.orderPaymentStatus || "UNKNOWN",
        total: parseFloat(order.pricingSummary?.total?.value || "0"),
        currency: order.pricingSummary?.total?.currency || "EUR",
        buyer: {
          username: order.buyer?.username || "",
        },
        items: (order.lineItems || []).map((li: any) => ({
          title: li.title,
          sku: li.sku,
          quantity: li.quantity,
          price: parseFloat(li.lineItemCost?.value || "0"),
          imageUrl: li.image?.imageUrl || null,
        })),
        shippingAddress: order.fulfillmentStartInstructions?.[0]?.shippingStep
          ?.shipTo || null,
        creationDate: order.creationDate,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
  await batch.commit();

  return orders;
}

export async function getOrderDetail(uid: string, orderId: string): Promise<any> {
  const accessToken = await getValidAccessToken(uid);
  if (!accessToken) throw new Error("eBay not connected");

  return ebayApiFetch(accessToken, `/sell/fulfillment/v1/order/${orderId}`);
}

export async function shipOrder(
  uid: string,
  orderId: string,
  trackingNumber: string,
  carrier: string
): Promise<any> {
  const accessToken = await getValidAccessToken(uid);
  if (!accessToken) throw new Error("eBay not connected");

  // Get order to find line items
  const order = await ebayApiFetch(
    accessToken,
    `/sell/fulfillment/v1/order/${orderId}`
  );

  const lineItems = (order.lineItems || []).map((li: any) => ({
    lineItemId: li.lineItemId,
    quantity: li.quantity,
  }));

  const result = await ebayApiFetch(
    accessToken,
    `/sell/fulfillment/v1/order/${orderId}/shipping_fulfillment`,
    {
      method: "POST",
      body: {
        lineItems,
        trackingNumber,
        shippingCarrierCode: carrier,
      },
    }
  );

  // Update Firestore
  await db
    .collection("users")
    .doc(uid)
    .collection("ebayOrders")
    .doc(orderId)
    .update({
      status: "FULFILLED",
      tracking: { trackingNumber, carrier },
      updatedAt: FieldValue.serverTimestamp(),
    });

  return result;
}

export async function refundOrder(
  uid: string,
  orderId: string,
  reason: string,
  amount?: number
): Promise<any> {
  const accessToken = await getValidAccessToken(uid);
  if (!accessToken) throw new Error("eBay not connected");

  const order = await ebayApiFetch(
    accessToken,
    `/sell/fulfillment/v1/order/${orderId}`
  );

  const refundAmount = amount || parseFloat(order.pricingSummary?.total?.value || "0");

  const result = await ebayApiFetch(
    accessToken,
    `/sell/fulfillment/v1/order/${orderId}/issue_refund`,
    {
      method: "POST",
      body: {
        reasonForRefund: reason || "OTHER",
        orderLevelRefundAmount: {
          value: refundAmount.toFixed(2),
          currency: order.pricingSummary?.total?.currency || "EUR",
        },
      },
    }
  );

  // Update Firestore
  await db
    .collection("users")
    .doc(uid)
    .collection("ebayOrders")
    .doc(orderId)
    .update({
      status: "REFUNDED",
      refund: { amount: refundAmount, reason },
      updatedAt: FieldValue.serverTimestamp(),
    });

  return result;
}

// ── Notifications / Webhook ──

export async function handleWebhookNotification(payload: any): Promise<void> {
  // eBay sends notifications with topic and data
  const topic = payload?.metadata?.topic;
  const data = payload?.notification?.data;

  if (!topic || !data) {
    console.warn("Invalid eBay webhook payload");
    return;
  }

  console.log(`eBay webhook: ${topic}`);

  // For order notifications, we need to find the user by their eBay account
  // This requires a lookup of which Vault user has this eBay account connected
  if (
    topic === "marketplace.account_deletion" ||
    !data.orderId
  ) {
    return;
  }

  // Search for users with eBay connected
  const usersSnap = await db
    .collectionGroup("integrations")
    .where("connected", "==", true)
    .get();

  for (const integDoc of usersSnap.docs) {
    if (integDoc.id !== "ebay") continue;
    const userDocRef = integDoc.ref.parent.parent;
    if (!userDocRef) continue;
    const uid = userDocRef.id;

    try {
      // Fetch the order detail using this user's token
      const accessToken = await getValidAccessToken(uid);
      if (!accessToken) continue;

      const order = await ebayApiFetch(
        accessToken,
        `/sell/fulfillment/v1/order/${data.orderId}`
      );
      if (!order) continue;

      // Store order
      await db
        .collection("users")
        .doc(uid)
        .collection("ebayOrders")
        .doc(data.orderId)
        .set(
          {
            ebayOrderId: data.orderId,
            status: order.orderFulfillmentStatus || "NOT_STARTED",
            paymentStatus: order.orderPaymentStatus || "UNKNOWN",
            total: parseFloat(order.pricingSummary?.total?.value || "0"),
            currency: order.pricingSummary?.total?.currency || "EUR",
            buyer: { username: order.buyer?.username || "" },
            items: (order.lineItems || []).map((li: any) => ({
              title: li.title,
              sku: li.sku,
              quantity: li.quantity,
              price: parseFloat(li.lineItemCost?.value || "0"),
            })),
            shippingAddress:
              order.fulfillmentStartInstructions?.[0]?.shippingStep?.shipTo || null,
            creationDate: order.creationDate,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

      // Create notification
      await userDocRef.collection("notifications").add({
        type: "ebay_order",
        title: "Nuovo ordine eBay",
        message: `Ordine da ${order.buyer?.username || "acquirente"} — €${order.pricingSummary?.total?.value || "0"}`,
        ebayOrderId: data.orderId,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });

      break; // Found the right user
    } catch (err) {
      console.warn(`Could not process webhook for user ${uid}:`, err);
    }
  }
}

// ═══════════════════════════════════════════════════
// Browse API — App-level token (no user OAuth needed)
// ═══════════════════════════════════════════════════

let _appToken: string | null = null;
let _appTokenExpiry = 0;

/**
 * Get an app-level OAuth token (Client Credentials Grant).
 * Used for Browse API (searching items, prices).
 */
export async function getAppToken(): Promise<string> {
  if (_appToken && Date.now() < _appTokenExpiry - 60000) {
    return _appToken;
  }

  const config = getEbayConfig();
  const credentials = Buffer.from(
    `${getEbayClientId()}:${getEbayClientSecret()}`
  ).toString("base64");

  const res = await fetch(config.tokenUrl, {
    method: "POST",
    headers: {
      Authorization: `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "client_credentials",
      scope: "https://api.ebay.com/oauth/api_scope",
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`App token failed: ${res.status} ${err}`);
  }

  const data: any = await res.json();
  _appToken = data.access_token;
  _appTokenExpiry = Date.now() + data.expires_in * 1000;
  return _appToken!;
}

/**
 * Search recently sold items on eBay for price reference.
 * Uses Browse API: /buy/browse/v1/item_summary/search
 * Returns: min, avg, max prices + recent sold items.
 */
export async function searchSoldItems(
  query: string,
  limit: number = 10
): Promise<{
  query: string;
  count: number;
  minPrice: number | null;
  avgPrice: number | null;
  maxPrice: number | null;
  currency: string;
  items: Array<{
    title: string;
    price: number;
    currency: string;
    imageUrl: string | null;
    itemUrl: string;
    soldDate: string | null;
  }>;
}> {
  const token = await getAppToken();
  const config = getEbayConfig();

  // Browse API — filter by SOLD items
  const params = new URLSearchParams({
    q: query,
    limit: limit.toString(),
    sort: "-price", // highest first for better reference
    filter: "buyingOptions:{FIXED_PRICE},conditions:{NEW|LIKE_NEW|VERY_GOOD}",
  });

  // Use /item_summary/search with completed items
  const res = await fetch(
    `${config.apiBase}/buy/browse/v1/item_summary/search?${params}`,
    {
      headers: {
        Authorization: `Bearer ${token}`,
        "X-EBAY-C-MARKETPLACE-ID": "EBAY_IT",
        "X-EBAY-C-ENDUSERCTX": "affiliateCampaignId=0",
      },
    }
  );

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Browse API error: ${res.status} ${err}`);
  }

  const data: any = await res.json();
  const items = (data.itemSummaries || []).map((item: any) => ({
    title: item.title,
    price: parseFloat(item.price?.value || "0"),
    currency: item.price?.currency || "EUR",
    imageUrl: item.thumbnailImages?.[0]?.imageUrl || null,
    itemUrl: item.itemWebUrl || "",
    soldDate: item.itemEndDate || null,
  }));

  const prices = items.map((i: any) => i.price).filter((p: number) => p > 0);
  const minPrice = prices.length > 0 ? Math.min(...prices) : null;
  const maxPrice = prices.length > 0 ? Math.max(...prices) : null;
  const avgPrice =
    prices.length > 0
      ? Math.round((prices.reduce((a: number, b: number) => a + b, 0) / prices.length) * 100) / 100
      : null;

  return {
    query,
    count: items.length,
    minPrice,
    avgPrice,
    maxPrice,
    currency: "EUR",
    items,
  };
}

// ═══════════════════════════════════════════════════
// Business Policies (Fulfillment, Return, Payment) — v2 with auto opt-in
// ═══════════════════════════════════════════════════

interface PolicyConfig {
  fulfillment?: {
    name: string;
    handlingDays: number;
    shippingService: string;
    shippingCost: number;
    freeShipping: boolean;
  };
  return?: {
    name: string;
    returnsAccepted: boolean;
    returnPeriod: string; // DAYS_30, DAYS_60
    shippingCostPaidBy: string; // BUYER, SELLER
  };
  payment?: {
    name: string;
  };
}

/**
 * Get existing business policies for a user.
 */
export async function getPolicies(uid: string): Promise<{
  fulfillment: any[];
  return: any[];
  payment: any[];
  saved: any;
}> {
  const accessToken = await getValidAccessToken(uid);
  if (!accessToken) throw new Error("eBay not connected");

  const result: any = { fulfillment: [], return: [], payment: [], saved: null };

  // Check saved policy IDs from Firestore first
  const saved = await getSavedPolicies(uid);
  result.saved = saved;
  console.log("[getPolicies] saved from Firestore:", JSON.stringify(saved));

  try {
    const fp = await ebayApiFetch(accessToken, "/sell/account/v1/fulfillment_policy?marketplace_id=EBAY_IT");
    result.fulfillment = fp?.fulfillmentPolicies || [];
    console.log("[getPolicies] fulfillment count:", result.fulfillment.length);
  } catch (e: any) {
    console.warn("[getPolicies] fulfillment error:", e.message);
  }

  try {
    const rp = await ebayApiFetch(accessToken, "/sell/account/v1/return_policy?marketplace_id=EBAY_IT");
    result.return = rp?.returnPolicies || [];
    console.log("[getPolicies] return count:", result.return.length);
  } catch (e: any) {
    console.warn("[getPolicies] return error:", e.message);
  }

  try {
    const pp = await ebayApiFetch(accessToken, "/sell/account/v1/payment_policy?marketplace_id=EBAY_IT");
    result.payment = pp?.paymentPolicies || [];
    console.log("[getPolicies] payment count:", result.payment.length);
  } catch (e: any) {
    console.warn("[getPolicies] payment error:", e.message);
  }

  console.log("[getPolicies] final result keys:", Object.keys(result), "hasSaved:", !!saved);
  return result;
}

/**
 * Opt-in to eBay Business Policies (required before creating policies).
 */
export async function optInToBusinessPolicies(uid: string): Promise<void> {
  const accessToken = await getValidAccessToken(uid);
  if (!accessToken) throw new Error("eBay not connected");

  try {
    await ebayApiFetch(accessToken, "/sell/account/v1/program/opt_in", {
      method: "POST",
      body: { programType: "SELLING_POLICY_MANAGEMENT" },
    });
  } catch (err: any) {
    // 409 = already opted in — that's fine
    if (!err.message?.includes("409")) {
      console.warn("Opt-in warning:", err.message);
    }
  }
}

/**
 * Create default business policies for a user (auto-setup).
 */
export async function createDefaultPolicies(uid: string, config?: PolicyConfig): Promise<{
  fulfillmentPolicyId: string;
  returnPolicyId: string;
  paymentPolicyId: string;
}> {
  const accessToken = await getValidAccessToken(uid);
  if (!accessToken) throw new Error("eBay not connected");

  // Auto opt-in to Business Policies
  await optInToBusinessPolicies(uid);

  // Helper: create or reuse existing policy
  async function createOrReuse(
    type: "fulfillment_policy" | "return_policy" | "payment_policy",
    idField: string,
    body: any
  ): Promise<string> {
    try {
      const result = await ebayApiFetch(accessToken!, `/sell/account/v1/${type}`, {
        method: "POST",
        body,
      });
      return result?.[idField];
    } catch (err: any) {
      // If duplicate, extract existing ID from error
      const msg = err.message || "";
      const idMatch = msg.match(/Profile Id["\s:]*["]*(\d+)/i) || msg.match(/"value":"(\d+)"/);
      if (idMatch) return idMatch[1];
      
      // Try to get existing policies
      const listResult = await ebayApiFetch(accessToken!, `/sell/account/v1/${type}?marketplace_id=EBAY_IT`);
      const listKey = type === "fulfillment_policy" ? "fulfillmentPolicies" 
        : type === "return_policy" ? "returnPolicies" : "paymentPolicies";
      const existing = listResult?.[listKey];
      if (existing?.length > 0) return existing[0][idField];
      
      throw err;
    }
  }

  const fulfillmentId = await createOrReuse("fulfillment_policy", "fulfillmentPolicyId", {
    name: config?.fulfillment?.name || "Vault - Spedizione Standard",
    marketplaceId: "EBAY_IT",
    handlingTime: { value: config?.fulfillment?.handlingDays || 2, unit: "DAY" },
    shippingOptions: [{
      optionType: "DOMESTIC",
      costType: "FLAT_RATE",
      shippingServices: [{
        shippingServiceCode: config?.fulfillment?.shippingService || "IT_Posta1",
        shippingCost: {
          value: config?.fulfillment?.freeShipping ? "0.00" : (config?.fulfillment?.shippingCost || 2.50).toFixed(2),
          currency: "EUR",
        },
        sortOrder: 1,
        freeShipping: config?.fulfillment?.freeShipping || false,
      }],
    }],
  });

  const returnId = await createOrReuse("return_policy", "returnPolicyId", {
    name: config?.return?.name || "Vault - Reso 30 giorni",
    marketplaceId: "EBAY_IT",
    returnsAccepted: config?.return?.returnsAccepted !== false,
    returnPeriod: { value: 30, unit: "DAY" },
    returnShippingCostPayer: config?.return?.shippingCostPaidBy || "BUYER",
  });

  let paymentId: string | undefined;
  try {
    paymentId = await createOrReuse("payment_policy", "paymentPolicyId", {
      name: config?.payment?.name || "Vault - Pagamenti gestiti eBay",
      marketplaceId: "EBAY_IT",
      immediatePay: false,
    });
  } catch (err: any) {
    console.warn("Payment policy creation failed (sandbox limitation):", err.message);
    // Payment policy is optional on eBay managed payments
  }

  const policyIds: any = {
    fulfillmentPolicyId: fulfillmentId,
    returnPolicyId: returnId,
  };
  if (paymentId) policyIds.paymentPolicyId = paymentId;

  // Save policy IDs to user profile for reuse
  await db.collection("users").doc(uid).collection("integrations").doc("ebay").update({
    policies: policyIds,
  });

  return policyIds;
}

/**
 * Get saved policy IDs for a user (from Firestore).
 */
export async function getSavedPolicies(uid: string): Promise<{
  fulfillmentPolicyId?: string;
  returnPolicyId?: string;
  paymentPolicyId?: string;
} | null> {
  const doc = await integrationRef(uid).get();
  if (!doc.exists) return null;
  return doc.data()?.policies || null;
}
