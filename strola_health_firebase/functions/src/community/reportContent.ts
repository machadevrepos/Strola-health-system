import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument } from "../lib/auth-helpers";
import { enforceRateLimit, RateLimits } from "../lib/rateLimit";
import { APP_CHECK_ENFORCED } from "../lib/appCheck";
import type { ReportTargetType } from "../lib/types";

/** Function #35. Wires up the Flutter app's report sheet, which previously
 * submitted to nothing per the audit. */
export const reportContent = onCall({ enforceAppCheck: APP_CHECK_ENFORCED }, async (request) => {
  const uid = requireAuth(request);
  await enforceRateLimit(uid, "reportContent", RateLimits.reportContent);
  const { targetType, targetId, category, reason } = (request.data ?? {}) as {
    targetType?: ReportTargetType;
    targetId?: string;
    category?: string;
    reason?: string;
  };
  if (!targetType || !targetId || !reason?.trim()) {
    invalidArgument("targetType, targetId, and reason are required.");
  }

  const ref = db.collection(Collections.reports).doc();
  await ref.set({
    id: ref.id,
    reporter_id: uid,
    target_type: targetType,
    target_id: targetId,
    category: category ?? "other",
    reason,
    status: "open",
    action_taken: null,
    resolved_by: null,
    resolved_at: null,
    resolution_note: null,
    created_at: FieldValue.serverTimestamp(),
  });

  return { success: true, reportId: ref.id };
});
