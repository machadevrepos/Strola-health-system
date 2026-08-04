import { onCall } from "firebase-functions/v2/https";
import { authAdmin, db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import { queueEmail } from "../lib/mailer";
import type { UserProfile } from "../lib/types";

/**
 * Function #7. The admin panel's row-menu "Reset password" action. The
 * Admin SDK can only generate the reset link, not send Firebase's built-in
 * reset email (that's a client-only operation) — so we generate the link
 * and deliver it ourselves via the Trigger Email extension queue.
 */
export const sendPasswordResetForUser = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { userId } = (request.data ?? {}) as { userId?: string };
  if (!userId) invalidArgument("userId is required.");

  const userSnap = await db.collection(Collections.users).doc(userId).get();
  if (!userSnap.exists) notFound("User not found.");
  const user = userSnap.data() as UserProfile;
  if (!user.email) invalidArgument("This user has no email on file.");

  const link = await authAdmin.generatePasswordResetLink(user.email);
  await queueEmail({
    to: user.email,
    subject: "Reset your Strolla Health password",
    html: `<p>Hi ${user.name || user.username || "there"},</p><p>An admin requested a password reset for your account. Click the link below to choose a new password:</p><p><a href="${link}">${link}</a></p><p>If you didn't expect this, you can ignore this email.</p>`,
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "send_password_reset",
    target: userId,
  });

  return { success: true };
});
