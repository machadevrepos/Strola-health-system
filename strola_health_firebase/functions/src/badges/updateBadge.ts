import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import type { BadgeRequirementMetric } from "../lib/types";

/** Function #29b. Raising a threshold (e.g. "100k Steps" -> "150k Steps")
 * is just a number edit here, no app release needed. */
export const updateBadge = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { badgeId, ...updates } = (request.data ?? {}) as {
    badgeId?: string;
    name?: string;
    description?: string;
    emoji?: string;
    requirementMetric?: BadgeRequirementMetric;
    requirementValue?: number;
    enabled?: boolean;
    visible?: boolean;
  };
  if (!badgeId) invalidArgument("badgeId is required.");

  const ref = db.collection(Collections.badges).doc(badgeId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Badge not found.");

  const patch: Record<string, unknown> = {};
  if (updates.name !== undefined) patch.name = updates.name;
  if (updates.description !== undefined) patch.description = updates.description;
  if (updates.emoji !== undefined) patch.emoji = updates.emoji;
  if (updates.requirementMetric !== undefined) patch.requirement_metric = updates.requirementMetric;
  if (updates.requirementValue !== undefined) patch.requirement_value = updates.requirementValue;
  if (updates.enabled !== undefined) patch.enabled = updates.enabled;
  if (updates.visible !== undefined) patch.visible = updates.visible;

  await ref.update(patch);

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "update_badge",
    target: badgeId,
    metadata: patch,
  });

  return { success: true };
});
