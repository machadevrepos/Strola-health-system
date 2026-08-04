import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import type { Badge, BadgeRequirementMetric } from "../lib/types";

/**
 * The auto-award engine the admin-panel audit flagged as missing entirely
 * (badges were manual-only). Called from wherever a metric changes —
 * dailyActivity writes (total_steps, streak_days), workout ingestion
 * (session_steps), challenge completion (challenges_completed) — with just
 * the metrics that changed; only badges keyed to those metrics are checked.
 * Idempotent: re-checking an already-awarded badge is a no-op.
 */
export async function evaluateBadgesForUser(
  userId: string,
  metrics: Partial<Record<BadgeRequirementMetric, number>>
): Promise<string[]> {
  const metricKeys = Object.keys(metrics) as BadgeRequirementMetric[];
  if (metricKeys.length === 0) return [];

  const badgesSnap = await db
    .collection(Collections.badges)
    .where("enabled", "==", true)
    .where("requirement_metric", "in", metricKeys)
    .get();

  const awarded: string[] = [];
  for (const badgeDoc of badgesSnap.docs) {
    const badge = badgeDoc.data() as Badge;
    const value = metrics[badge.requirement_metric];
    if (value == null || value < badge.requirement_value) continue;

    const userBadgeId = `${userId}_${badge.id}`;
    const ref = db.collection(Collections.userBadges).doc(userBadgeId);
    const existing = await ref.get();
    if (existing.exists) continue;

    await ref.set({
      id: userBadgeId,
      user_id: userId,
      badge_id: badge.id,
      awarded_at: FieldValue.serverTimestamp(),
      awarded_by: null,
    });
    awarded.push(badge.id);
  }
  return awarded;
}
