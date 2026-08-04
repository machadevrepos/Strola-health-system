import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/**
 * Function #50. `key` is what the Flutter app looks up (once it starts
 * fetching remotely — per the audit, it still uses hardcoded strings today,
 * this is the staging library ahead of that client-side wiring).
 */
export const updateAppContent = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { key, category, label, value } = (request.data ?? {}) as {
    key?: string;
    category?: string;
    label?: string;
    value?: string;
  };
  if (!key || value === undefined) invalidArgument("key and value are required.");

  await db
    .collection(Collections.appContent)
    .doc(key!)
    .set(
      {
        key,
        category: category ?? "misc",
        label: label ?? key,
        value,
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "update_app_content",
    target: key,
  });

  return { success: true };
});
