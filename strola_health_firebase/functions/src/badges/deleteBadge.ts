import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/** Function #29c. Cascades: removes every UserBadge award referencing it. */
export const deleteBadge = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { badgeId } = (request.data ?? {}) as { badgeId?: string };
  if (!badgeId) invalidArgument("badgeId is required.");

  const ref = db.collection(Collections.badges).doc(badgeId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Badge not found.");

  const awardsSnap = await db.collection(Collections.userBadges).where("badge_id", "==", badgeId).get();
  if (!awardsSnap.empty) {
    const batch = db.batch();
    awardsSnap.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
  await ref.delete();

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "delete_badge",
    target: badgeId,
    metadata: { awards_removed: awardsSnap.size },
  });

  return { success: true };
});
