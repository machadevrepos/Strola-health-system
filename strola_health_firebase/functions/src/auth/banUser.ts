import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, authAdmin } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/** Function #3. Suspends an account and immediately revokes its sessions
 * (a banned user is locked out right away, not just hidden in the UI). */
export const banUser = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { userId, reason } = (request.data ?? {}) as { userId?: string; reason?: string };
  if (!userId) invalidArgument("userId is required.");

  const userRef = db.collection(Collections.users).doc(userId);
  const snap = await userRef.get();
  if (!snap.exists) notFound("User not found.");

  await userRef.update({
    banned: true,
    ban_reason: reason ?? null,
    updated_at: FieldValue.serverTimestamp(),
  });
  await authAdmin.revokeRefreshTokens(userId);

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "ban_user",
    target: userId,
    metadata: { reason: reason ?? null },
  });

  return { success: true };
});

export const unbanUser = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { userId } = (request.data ?? {}) as { userId?: string };
  if (!userId) invalidArgument("userId is required.");

  const userRef = db.collection(Collections.users).doc(userId);
  const snap = await userRef.get();
  if (!snap.exists) notFound("User not found.");

  await userRef.update({
    banned: false,
    ban_reason: null,
    updated_at: FieldValue.serverTimestamp(),
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "unban_user",
    target: userId,
  });

  return { success: true };
});
