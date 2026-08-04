import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth } from "../lib/auth-helpers";
import { sanitizeConnection } from "./sanitize";
import type { IntegrationConnection } from "../lib/types";

/**
 * Self-service counterpart to listIntegrationConnections (admin-only, lists
 * every user's connections for the admin panel). The mobile app's own
 * Connected Apps screen needs this — found missing during the Flutter
 * migration: `integrationConnections` is entirely Functions-only in
 * firestore.rules (`allow read: if false`, even for the owning user), so
 * there was no way for a signed-in user to see their own connection status
 * at all until now. Scoped to the caller's own uid only.
 */
export const listMyIntegrationConnections = onCall(async (request) => {
  const uid = requireAuth(request);

  const snap = await db
    .collection(Collections.integrationConnections)
    .where("user_id", "==", uid)
    .get();
  const connections = snap.docs.map((doc) => sanitizeConnection(doc.id, doc.data() as IntegrationConnection));

  return { connections };
});
