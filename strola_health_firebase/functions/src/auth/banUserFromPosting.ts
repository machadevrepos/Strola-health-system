import { onCall } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/** Function #4. Distinct from a full account ban — posting_banned only
 * blocks community writes (posts/comments), optionally for a fixed window
 * (used by the moderation "mute 24h / 7d" quick actions). */
export const banUserFromPosting = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { userId, reason, untilMillis } = (request.data ?? {}) as {
    userId?: string;
    reason?: string;
    untilMillis?: number;
  };
  if (!userId) invalidArgument("userId is required.");

  const userRef = db.collection(Collections.users).doc(userId);
  const snap = await userRef.get();
  if (!snap.exists) notFound("User not found.");

  await userRef.update({
    posting_banned: true,
    posting_ban_reason: reason ?? null,
    posting_banned_until: untilMillis ? Timestamp.fromMillis(untilMillis) : null,
    updated_at: FieldValue.serverTimestamp(),
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "ban_user_from_posting",
    target: userId,
    metadata: { reason: reason ?? null, until: untilMillis ?? null },
  });

  return { success: true };
});

export const unbanUserFromPosting = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { userId } = (request.data ?? {}) as { userId?: string };
  if (!userId) invalidArgument("userId is required.");

  const userRef = db.collection(Collections.users).doc(userId);
  const snap = await userRef.get();
  if (!snap.exists) notFound("User not found.");

  await userRef.update({
    posting_banned: false,
    posting_ban_reason: null,
    posting_banned_until: null,
    updated_at: FieldValue.serverTimestamp(),
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "unban_user_from_posting",
    target: userId,
  });

  return { success: true };
});
