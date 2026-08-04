import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, getRole, invalidArgument, notFound, failedPrecondition } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import { actorLabelFromRequest } from "../lib/auth-helpers";
import { sanitizeConnection } from "./sanitize";
import type { IntegrationConnection } from "../lib/types";

/**
 * Function #58. Self (from the app's Connected Apps screen) or admin
 * (admin panel's Connected Apps page). Existing synced workout/daily-activity
 * data is left untouched — only the connection itself, and any tokens, go away.
 */
export const disconnectIntegration = onCall(async (request) => {
  const callerUid = requireAuth(request);
  const { connectionId, userId } = (request.data ?? {}) as {
    connectionId?: string;
    userId?: string;
  };
  if (!connectionId) invalidArgument("connectionId is required.");

  const ref = db.collection(Collections.integrationConnections).doc(connectionId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Connection not found.");
  const ownerId = (snap.data() as { user_id: string }).user_id;

  const isAdminInitiated = ownerId !== callerUid;
  if (isAdminInitiated) {
    const role = getRole(request);
    if (role !== "admin" && role !== "super_admin") {
      failedPrecondition("Not authorized to disconnect another user's integration.");
    }
  } else if (userId && userId !== callerUid) {
    invalidArgument("userId must match the caller unless you're an admin.");
  }

  await ref.update({
    status: "disconnected",
    access_token: null,
    refresh_token: null,
    error_message: null,
  });

  if (isAdminInitiated) {
    await writeAuditLog({
      actorUid: callerUid,
      actor: actorLabelFromRequest(request),
      action: "disconnect_integration",
      target: connectionId,
    });
  }

  const updated = await ref.get();
  return { success: true, connection: sanitizeConnection(connectionId, updated.data() as IntegrationConnection) };
});
