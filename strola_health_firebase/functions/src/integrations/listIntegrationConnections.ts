import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin } from "../lib/auth-helpers";
import { sanitizeConnection } from "./sanitize";
import type { IntegrationConnection } from "../lib/types";

/**
 * `integrationConnections` is entirely Functions-only in firestore.rules
 * (`allow read: if false`, even for admins) because it holds OAuth
 * access/refresh tokens. This is the admin panel's only way to see the
 * collection at all — a sanitized projection with the token fields
 * stripped, added while wiring the Connected Apps page (the original build
 * didn't include a listing function since every other collection is
 * either directly admin-readable or doesn't need a dedicated list callable).
 */
export const listIntegrationConnections = onCall(async (request) => {
  requireAdmin(request);

  const snap = await db.collection(Collections.integrationConnections).get();
  const connections = snap.docs.map((doc) => sanitizeConnection(doc.id, doc.data() as IntegrationConnection));

  return { connections };
});
