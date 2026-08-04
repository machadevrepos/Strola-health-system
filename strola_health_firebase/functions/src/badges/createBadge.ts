import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import type { BadgeRequirementMetric } from "../lib/types";

const VALID_METRICS: BadgeRequirementMetric[] = [
  "total_steps",
  "session_steps",
  "streak_days",
  "challenges_completed",
];

/** Function #29a. */
export const createBadge = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { name, description, emoji, requirementMetric, requirementValue, enabled, visible } =
    (request.data ?? {}) as {
      name?: string;
      description?: string;
      emoji?: string;
      requirementMetric?: BadgeRequirementMetric;
      requirementValue?: number;
      enabled?: boolean;
      visible?: boolean;
    };

  if (!name?.trim() || !requirementMetric || requirementValue == null) {
    invalidArgument("name, requirementMetric, and requirementValue are required.");
  }
  if (!VALID_METRICS.includes(requirementMetric!)) {
    invalidArgument(`requirementMetric must be one of: ${VALID_METRICS.join(", ")}.`);
  }

  const ref = db.collection(Collections.badges).doc();
  await ref.set({
    id: ref.id,
    name,
    description: description ?? "",
    emoji: emoji ?? "🏅",
    requirement_metric: requirementMetric,
    requirement_value: requirementValue,
    enabled: enabled ?? true,
    visible: visible ?? true,
    created_at: FieldValue.serverTimestamp(),
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "create_badge",
    target: ref.id,
  });

  return { success: true, badgeId: ref.id };
});
