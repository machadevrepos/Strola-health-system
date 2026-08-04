import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/** Function #30a. Manual award, always done from a user's profile —
 * distinct from evaluateBadgesForUser's automatic path (awarded_by is set
 * here, null there). */
export const awardBadge = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { userId, badgeId } = (request.data ?? {}) as { userId?: string; badgeId?: string };
  if (!userId || !badgeId) invalidArgument("userId and badgeId are required.");

  const badgeSnap = await db.collection(Collections.badges).doc(badgeId).get();
  if (!badgeSnap.exists) notFound("Badge not found.");

  const userBadgeId = `${userId}_${badgeId}`;
  await db
    .collection(Collections.userBadges)
    .doc(userBadgeId)
    .set({
      id: userBadgeId,
      user_id: userId,
      badge_id: badgeId,
      awarded_at: FieldValue.serverTimestamp(),
      awarded_by: callerUid,
    });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "award_badge",
    target: userId,
    metadata: { badge_id: badgeId },
  });

  return { success: true };
});

/** Function #30b. */
export const revokeBadge = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { userId, badgeId } = (request.data ?? {}) as { userId?: string; badgeId?: string };
  if (!userId || !badgeId) invalidArgument("userId and badgeId are required.");

  const userBadgeId = `${userId}_${badgeId}`;
  const ref = db.collection(Collections.userBadges).doc(userBadgeId);
  const snap = await ref.get();
  if (!snap.exists) notFound("This user doesn't have that badge.");

  await ref.delete();

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "revoke_badge",
    target: userId,
    metadata: { badge_id: badgeId },
  });

  return { success: true };
});
