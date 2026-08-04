import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import type { SubscriptionTier } from "../lib/types";

/** Function #52. Literally the free/premium split control, runtime-editable
 * instead of an app release. */
export const updateFeatureFlag = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { key, requiredTier, description } = (request.data ?? {}) as {
    key?: string;
    requiredTier?: SubscriptionTier;
    description?: string;
  };
  if (!key || !requiredTier) invalidArgument("key and requiredTier are required.");

  await db
    .collection(Collections.featureFlags)
    .doc(key!)
    .set(
      {
        key,
        required_tier: requiredTier,
        description: description ?? null,
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "update_feature_flag",
    target: key,
    metadata: { required_tier: requiredTier },
  });

  return { success: true };
});
