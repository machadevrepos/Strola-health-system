import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import type { BetaTargetType } from "../lib/types";

/** Function #53a. `target_type: "ambassador"` applies dynamically to every
 * is_ambassador=true user (including future ones) — no per-user overrides
 * needed for that case. */
export const grantBetaOverride = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { featureKey, targetType, targetValue } = (request.data ?? {}) as {
    featureKey?: string;
    targetType?: BetaTargetType;
    targetValue?: string;
  };
  if (!featureKey || !targetType || !targetValue) {
    invalidArgument("featureKey, targetType, and targetValue are required.");
  }

  const ref = db.collection(Collections.betaOverrides).doc();
  await ref.set({
    id: ref.id,
    feature_key: featureKey,
    target_type: targetType,
    target_value: targetValue,
    created_by: callerUid,
    created_at: FieldValue.serverTimestamp(),
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "grant_beta_override",
    target: ref.id,
    metadata: { feature_key: featureKey, target_type: targetType, target_value: targetValue },
  });

  return { success: true, overrideId: ref.id };
});

/** Function #53b. */
export const revokeBetaOverride = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { overrideId } = (request.data ?? {}) as { overrideId?: string };
  if (!overrideId) invalidArgument("overrideId is required.");

  const ref = db.collection(Collections.betaOverrides).doc(overrideId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Beta override not found.");

  await ref.delete();

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "revoke_beta_override",
    target: overrideId,
  });

  return { success: true };
});
