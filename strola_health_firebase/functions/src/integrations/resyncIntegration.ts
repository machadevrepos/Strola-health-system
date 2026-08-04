import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import { syncProviderConnection } from "./sync";
import { sanitizeConnection } from "./sanitize";
import type { IntegrationConnection } from "../lib/types";
import {
  STRAVA_CLIENT_ID,
  STRAVA_CLIENT_SECRET,
  GARMIN_CLIENT_ID,
  GARMIN_CLIENT_SECRET,
  OURA_CLIENT_ID,
  OURA_CLIENT_SECRET,
  MYFITNESSPAL_CLIENT_ID,
  MYFITNESSPAL_CLIENT_SECRET,
} from "../lib/secrets";

/**
 * Function #57. Admin panel's "Resync" action — also the practical fix for a
 * stuck `error` connection. Performs one real on-demand pull via
 * `syncProviderConnection` (shared with the scheduled job, function #59)
 * rather than just resetting status like the old mock did.
 */
export const resyncIntegration = onCall(
  {
    secrets: [
      STRAVA_CLIENT_ID,
      STRAVA_CLIENT_SECRET,
      GARMIN_CLIENT_ID,
      GARMIN_CLIENT_SECRET,
      OURA_CLIENT_ID,
      OURA_CLIENT_SECRET,
      MYFITNESSPAL_CLIENT_ID,
      MYFITNESSPAL_CLIENT_SECRET,
    ],
  },
  async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { connectionId } = (request.data ?? {}) as { connectionId?: string };
  if (!connectionId) invalidArgument("connectionId is required.");

  const ref = db.collection(Collections.integrationConnections).doc(connectionId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Connection not found.");

  try {
    await syncProviderConnection(connectionId);
    await ref.update({ status: "connected", error_message: null, last_synced_at: FieldValue.serverTimestamp() });
  } catch (err) {
    await ref.update({ status: "error", error_message: (err as Error).message });
    throw err;
  }

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "resync_integration",
    target: connectionId,
  });

    const updated = await ref.get();
    return { success: true, connection: sanitizeConnection(connectionId, updated.data() as IntegrationConnection) };
  }
);
