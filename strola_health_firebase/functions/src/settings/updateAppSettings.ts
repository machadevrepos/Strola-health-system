import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections, APP_SETTINGS_DOC_ID } from "../lib/constants";
import { requireSuperAdmin, actorLabelFromRequest } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import type { AppSettings } from "../lib/types";

/**
 * Function #51. super_admin only (Part 4, decision #7 — pricing/trial
 * length/minimum-app-version are elevated fields). Single-document
 * partial-update form save, same shape as the admin panel's App Settings tab.
 */
export const updateAppSettings = onCall(async (request) => {
  const { uid: callerUid } = requireSuperAdmin(request);
  const updates = (request.data ?? {}) as Partial<Omit<AppSettings, "updated_at">>;

  await db
    .collection(Collections.appSettings)
    .doc(APP_SETTINGS_DOC_ID)
    .set({ ...updates, updated_at: FieldValue.serverTimestamp() }, { merge: true });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "update_app_settings",
    metadata: updates,
  });

  return { success: true };
});
