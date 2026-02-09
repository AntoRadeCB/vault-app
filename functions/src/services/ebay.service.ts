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
// TCG cards (183454, 183456, 183457): eBay uses Condition Descriptors system
// conditionId 4000 = USED_VERY_GOOD = "Ungraded" for TCG
// conditionId 2750 = LIKE_NEW = "Graded" for TCG (requires grader descriptor)
// Condition Descriptor 40001 = "Card Condition" (Near Mint, Lightly Played, etc.)
function mapTcgCondition(condition: string): string {
  // For ungraded cards, always use USED_VERY_GOOD (4000)
  // For NEW cards in original packaging, also use USED_VERY_GOOD since
  // eBay TCG categories require condition descriptors
  return "USED_VERY_GOOD";
}

// Map card condition text to eBay condition descriptor numeric value IDs
// Descriptor 40001 = Card Condition for category 183454 (CCG Individual Cards)
const CARD_CONDITION_DESCRIPTOR_MAP: Record<string, string> = {
  "Near Mint o migliore": "400010",       // Near Mint or Better
  "Near Mint or Better": "400010",
  "Lightly Played (Excellent)": "400011", // Excellent
  "Excellent": "400011",
  "Moderately Played (Very Good)": "400012", // Very Good
  "Very Good": "400012",
  "Heavily Played (Poor)": "400013",      // Poor
  "Poor": "400013",
};

function mapCardConditionDescriptor(cardCondition?: string): string {
  if (!cardCondition) return "400010"; // default: Near Mint or Better
  return CARD_CONDITION_DESCRIPTOR_MAP[cardCondition] || "400010";
}

function mapCondition(condition: string, categoryId?: string): string {
  const map: Record<string, string> = {
    "NEW": "NEW",
    "NEW_OTHER": "NEW_OTHER",
    "LIKE_NEW": "LIKE_NEW",
    "USED_EXCELLENT": "USED_EXCELLENT",
    "USED_VERY_GOOD": "USED_VERY_GOOD",
    "USED_GOOD": "USED_GOOD",
    "USED_ACCEPTABLE": "USED_ACCEPTABLE",
  };
  return map[condition] || "NEW";
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
    cardCondition?: string;
    categoryId: string;
    imageUrls: string[];
    shippingProfileId?: string;
    returnProfileId?: string;
    paymentProfileId?: string;
    aspects?: Record<string, string[]>;
  }
): Promise<{ success: boolean; listingId?: string; ebayItemId?: string }> {
  // Validate minimum price (eBay requires >= 1.00)
  if (!productData.price || productData.price < 1) {
    throw new Error("Il prezzo deve essere almeno €1,00");
  }

  const accessToken = await getValidAccessToken(uid);
  if (!accessToken) throw new Error("eBay not connected");

  // Check available quantity: inventoryQty - already listed
  const productDoc = await db
    .collection("users").doc(uid)
    .collection("products").doc(productData.productId).get();
  
  if (productDoc.exists) {
    const pData = productDoc.data()!;
    const totalQty = (pData.quantity as number) || 0;
    const invQty = (pData.inventoryQty as number) || 0;
    const availablePool = Math.max(invQty, 0);

    // Get already listed quantity for this product
    const existingListings = await db
      .collection("users").doc(uid)
      .collection("ebayListings")
      .where("productId", "==", productData.productId)
      .get();
    
    let alreadyListed = 0;
    let existingActiveListing: any = null;
    
    for (const doc of existingListings.docs) {
      const lData = doc.data();
      if (lData.status !== "ended") {
        alreadyListed += (lData.quantity as number) || 0;
        if ((lData.status === "active" || lData.status === "draft") && lData.offerId) {
          existingActiveListing = { id: doc.id, ...lData };
        }
      }
    }

    const requestedQty = productData.quantity || 1;
    const maxAvailable = availablePool - alreadyListed;

    if (requestedQty > maxAvailable) {
      throw new Error(
        `Quantità non disponibile: hai ${availablePool} da vendere, ${alreadyListed} già listat${alreadyListed === 1 ? "o" : "i"}. Puoi listare al massimo ${Math.max(0, maxAvailable)}.`
      );
    }

    // If there's already an active listing for this product, update quantity instead of creating new
    if (existingActiveListing) {
      const newQty = (existingActiveListing.quantity || 0) + requestedQty;
      
      // Update offer quantity on eBay
      if (existingActiveListing.offerId) {
        await ebayApiFetch(
          accessToken,
          `/sell/inventory/v1/offer/${existingActiveListing.offerId}`,
          {
            method: "PUT",
            body: {
              marketplaceId: "EBAY_IT",
              sku: existingActiveListing.sku,
              format: "FIXED_PRICE",
              categoryId: existingActiveListing.categoryId,
              availableQuantity: newQty,
              pricingSummary: {
                price: {
                  value: (productData.price || existingActiveListing.price).toFixed(2),
                  currency: existingActiveListing.currency || "EUR",
                },
              },
            },
          }
        );
      }

      // Update Firestore listing
      await db
        .collection("users").doc(uid)
        .collection("ebayListings").doc(existingActiveListing.id)
        .update({
          quantity: newQty,
          price: productData.price || existingActiveListing.price,
          updatedAt: FieldValue.serverTimestamp(),
        });

      return {
        success: true,
        listingId: existingActiveListing.id,
        ebayItemId: existingActiveListing.ebayItemId,
      };
    }
  }

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
            // "Condizione della carta" required when condition is USED (3000)
            ...(productData.condition === "USED" && productData.cardCondition
              ? { "Condizione della carta": [productData.cardCondition] }
              : {}),
            ...(productData.aspects || {}),
          },
        } : {}),
      },
      // TCG (183454): uses Condition Descriptors — conditionId 4000 (ungraded)
      condition: isTcgCategory
        ? mapTcgCondition(productData.condition)
        : mapCondition(productData.condition, productData.categoryId),
      // Condition Descriptors for TCG cards (required for conditionId 4000)
      ...(isTcgCategory ? {
        conditionDescriptors: [
          {
            name: "40001", // Card Condition descriptor
            values: [mapCardConditionDescriptor(productData.cardCondition)],
          },
        ],
      } : {}),
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
  updates: { title?: string; price?: number; quantity?: number; description?: string }
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

  // Update inventory item (title, description on product level)
  if (listing.sku && (updates.title || updates.description)) {
    const inventoryUpdate: any = { product: {} };
    if (updates.title) inventoryUpdate.product.title = updates.title;
    if (updates.description) inventoryUpdate.product.description = updates.description;

    await ebayApiFetch(
      accessToken,
      `/sell/inventory/v1/inventory_item/${listing.sku}`,
      { method: "PUT", body: inventoryUpdate }
    );
  }

  // Update offer (price, quantity, description on offer level)
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

    if (Object.keys(offerUpdate).length > 0) {
      await ebayApiFetch(
        accessToken,
        `/sell/inventory/v1/offer/${listing.offerId}`,
        { method: "PUT", body: { ...offerUpdate, marketplaceId: "EBAY_IT", sku: listing.sku, format: "FIXED_PRICE", categoryId: listing.categoryId } }
      );
    }
  }

  // Update Firestore
  const firestoreUpdates: any = { updatedAt: FieldValue.serverTimestamp() };
  if (updates.title !== undefined) firestoreUpdates.title = updates.title;
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

// ── Inventory adjustment on sale ──

async function _adjustInventoryForSales(
  uid: string,
  soldItems: { sku: string; quantity: number }[]
) {
  // SKU format: vault-{productId}-{timestamp}
  for (const item of soldItems) {
    const parts = item.sku.split("-");
    if (parts.length < 3 || parts[0] !== "vault") continue;

    // Extract productId (everything between first "vault-" and last "-timestamp")
    const productId = parts.slice(1, -1).join("-");
    if (!productId) continue;

    const productRef = db
      .collection("users")
      .doc(uid)
      .collection("products")
      .doc(productId);

    const productDoc = await productRef.get();
    if (!productDoc.exists) continue;

    const data = productDoc.data()!;
    const currentInventoryQty = (data.inventoryQty as number) || 0;
    const currentQty = (data.quantity as number) || 0;
    const isSingleCard = data.kind === "singleCard";

    if (isSingleCard) {
      // Decrement inventoryQty first, then quantity
      const newInvQty = Math.max(0, currentInventoryQty - item.quantity);
      const invDecrement = currentInventoryQty - newInvQty;
      const remainingDecrement = item.quantity - invDecrement;
      const newQty = Math.max(0, currentQty - remainingDecrement);

      await productRef.update({
        inventoryQty: newInvQty,
        quantity: newQty,
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else {
      // Sealed products: decrement quantity directly
      const newQty = Math.max(0, currentQty - item.quantity);
      await productRef.update({
        quantity: newQty,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    // Also update the listing status if quantity hits 0
    const listingSnap = await db
      .collection("users")
      .doc(uid)
      .collection("ebayListings")
      .where("sku", "==", item.sku)
      .limit(1)
      .get();

    if (!listingSnap.empty) {
      await listingSnap.docs[0].ref.update({
        status: "ended",
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  }
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

  // Sync to Firestore + auto-decrement inventory for new orders
  const batch = db.batch();
  const newOrderSkus: { sku: string; quantity: number }[] = [];

  for (const order of orders) {
    const orderRef = db
      .collection("users")
      .doc(uid)
      .collection("ebayOrders")
      .doc(order.orderId);

    // Check if order already exists (to avoid double-decrementing)
    const existingOrder = await orderRef.get();
    const isNewOrder = !existingOrder.exists;
    const wasNotStarted = existingOrder.data()?.inventoryAdjusted !== true;

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
        inventoryAdjusted: true,
      },
      { merge: true }
    );

    // Collect SKUs from new orders to decrement inventory
    if ((isNewOrder || !wasNotStarted) && order.lineItems) {
      for (const li of order.lineItems) {
        if (li.sku) {
          newOrderSkus.push({ sku: li.sku, quantity: li.quantity || 1 });
        }
      }
    }
  }
  await batch.commit();

  // Decrement inventory for sold items
  if (newOrderSkus.length > 0) {
    await _adjustInventoryForSales(uid, newOrderSkus);
  }

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

  // Update Firestore order
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

  // Auto-create shipment in shipments collection for tracking
  const itemTitle = (order.lineItems || [])
    .map((li: any) => li.title)
    .join(", ") || "Ordine eBay";
  const buyerName = order.buyer?.username || "acquirente";

  // Detect carrier name from code
  const carrierNames: Record<string, string> = {
    "Poste_Italiane": "Poste Italiane",
    "BRT": "BRT",
    "DHL": "DHL",
    "UPS": "UPS",
    "FedEx": "FedEx",
    "GLS": "GLS",
    "SDA": "SDA",
    "TNT": "TNT",
    "Mondial_Relay": "Mondial Relay",
    "Amazon_Logistics": "Amazon Logistics",
  };
  const carrierSlug = carrier.toLowerCase().replace(/[\s_-]+/g, "_");
  const carrierDisplayName = carrierNames[carrier] || carrier;

  await db
    .collection("users")
    .doc(uid)
    .collection("shipments")
    .add({
      trackingCode: trackingNumber,
      carrier: carrierSlug,
      carrierName: carrierDisplayName,
      type: "sale",
      productName: `${itemTitle} → ${buyerName}`,
      status: "inTransit",
      createdAt: FieldValue.serverTimestamp(),
      lastUpdate: FieldValue.serverTimestamp(),
      ebayOrderId: orderId,
    });

  // Auto-create Sale records for dashboard revenue tracking
  for (const li of (order.lineItems || [])) {
    const salePrice = parseFloat(li.lineItemCost?.value || li.total?.value || "0");
    let purchasePrice = 0;

    // Look up original product purchase price via SKU
    if (li.sku) {
      const parts = (li.sku as string).split("-");
      if (parts.length >= 3 && parts[0] === "vault") {
        const productId = parts.slice(1, -1).join("-");
        const productDoc = await db
          .collection("users").doc(uid)
          .collection("products").doc(productId).get();
        if (productDoc.exists) {
          purchasePrice = (productDoc.data()?.price as number) || 0;
        }
      }
    }

    // Try to get real eBay fees from order, fallback to 13% estimate
    // eBay provides totalFeeBasisAmount or totalMarketplaceFee on order level
    const orderTotal = parseFloat(order.pricingSummary?.total?.value || "0");
    const totalFees = parseFloat(order.totalFeeBasisAmount?.value || "0")
      || parseFloat(order.totalMarketplaceFee?.value || "0");
    
    let itemFees: number;
    if (totalFees > 0 && orderTotal > 0) {
      // Distribute fees proportionally across line items
      itemFees = Math.round((salePrice / orderTotal) * totalFees * 100) / 100;
    } else {
      // Fallback: estimate ~13% (10.3% final value + ~3% payment processing)
      itemFees = Math.round(salePrice * 0.13 * 100) / 100;
    }

    await db
      .collection("users")
      .doc(uid)
      .collection("sales")
      .add({
        productName: li.title || itemTitle,
        salePrice,
        purchasePrice,
        fees: itemFees,
        feesEstimated: totalFees <= 0, // flag if fees are estimated vs real
        date: FieldValue.serverTimestamp(),
        source: "ebay",
        ebayOrderId: orderId,
        sku: li.sku || null,
        quantity: li.quantity || 1,
      });
  }

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

  // Reverse Sale records for this order
  const salesSnap = await db
    .collection("users").doc(uid)
    .collection("sales")
    .where("ebayOrderId", "==", orderId)
    .get();

  for (const saleDoc of salesSnap.docs) {
    await saleDoc.ref.delete();
  }

  // Restore inventory quantities
  for (const li of (order.lineItems || [])) {
    if (!li.sku) continue;
    const parts = (li.sku as string).split("-");
    if (parts.length < 3 || parts[0] !== "vault") continue;
    const productId = parts.slice(1, -1).join("-");

    const productRef = db.collection("users").doc(uid).collection("products").doc(productId);
    const productDoc = await productRef.get();
    if (!productDoc.exists) continue;

    const data = productDoc.data()!;
    const qty = li.quantity || 1;

    if (data.kind === "singleCard") {
      await productRef.update({
        inventoryQty: ((data.inventoryQty as number) || 0) + qty,
        quantity: ((data.quantity as number) || 0) + qty,
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else {
      await productRef.update({
        quantity: ((data.quantity as number) || 0) + qty,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  }

  // Mark order as inventory-reversed so webhook doesn't re-adjust
  await db
    .collection("users").doc(uid)
    .collection("ebayOrders").doc(orderId)
    .update({ inventoryAdjusted: false });

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

      const orderStatus = order.orderFulfillmentStatus || "";
      const cancelStatus = order.cancelStatus?.cancelState || "";
      const isCancelled = cancelStatus === "CANCELED" || orderStatus === "CANCELLED";

      const orderDoc = await db
        .collection("users").doc(uid)
        .collection("ebayOrders").doc(data.orderId).get();

      if (isCancelled && orderDoc.data()?.inventoryAdjusted) {
        // ORDER CANCELLED — restore inventory + delete sales
        const itemsToRestore = (order.lineItems || [])
          .filter((li: any) => li.sku)
          .map((li: any) => ({ sku: li.sku, quantity: li.quantity || 1 }));

        for (const item of itemsToRestore) {
          const parts = (item.sku as string).split("-");
          if (parts.length < 3 || parts[0] !== "vault") continue;
          const productId = parts.slice(1, -1).join("-");
          const productRef = db.collection("users").doc(uid).collection("products").doc(productId);
          const productSnap = await productRef.get();
          if (!productSnap.exists) continue;
          const pData = productSnap.data()!;
          if (pData.kind === "singleCard") {
            await productRef.update({
              inventoryQty: ((pData.inventoryQty as number) || 0) + item.quantity,
              quantity: ((pData.quantity as number) || 0) + item.quantity,
              updatedAt: FieldValue.serverTimestamp(),
            });
          } else {
            await productRef.update({
              quantity: ((pData.quantity as number) || 0) + item.quantity,
              updatedAt: FieldValue.serverTimestamp(),
            });
          }
        }

        // Delete any sales for this order
        const salesToDelete = await db
          .collection("users").doc(uid).collection("sales")
          .where("ebayOrderId", "==", data.orderId).get();
        for (const s of salesToDelete.docs) await s.ref.delete();

        await db.collection("users").doc(uid)
          .collection("ebayOrders").doc(data.orderId)
          .update({ inventoryAdjusted: false, status: "CANCELLED" });

        // Notify cancellation
        await userDocRef.collection("notifications").add({
          type: "ebay_order_cancelled",
          title: "Ordine annullato",
          message: `Ordine ${data.orderId} annullato — inventario ripristinato`,
          ebayOrderId: data.orderId,
          read: false,
          createdAt: FieldValue.serverTimestamp(),
        });

      } else if (!isCancelled && !orderDoc.data()?.inventoryAdjusted) {
        // NEW ORDER — decrement inventory
        const soldItems = (order.lineItems || [])
          .filter((li: any) => li.sku)
          .map((li: any) => ({ sku: li.sku, quantity: li.quantity || 1 }));
        
        if (soldItems.length > 0) {
          await _adjustInventoryForSales(uid, soldItems);
        }

        await db
          .collection("users").doc(uid)
          .collection("ebayOrders").doc(data.orderId)
          .update({ inventoryAdjusted: true });

        // Notify new order
        await userDocRef.collection("notifications").add({
          type: "ebay_order",
          title: "Nuovo ordine eBay",
          message: `Ordine da ${order.buyer?.username || "acquirente"} — €${order.pricingSummary?.total?.value || "0"}`,
          ebayOrderId: data.orderId,
          read: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      }

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
