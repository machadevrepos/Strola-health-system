import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import { queueEmail } from "../lib/mailer";
import type { UserProfile } from "../lib/types";

/** Function #8. The Users page's one-off "Send email" action. */
export const sendAdminEmail = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { userId, subject, body } = (request.data ?? {}) as {
    userId?: string;
    subject?: string;
    body?: string;
  };
  if (!userId || !subject || !body) invalidArgument("userId, subject, and body are required.");

  const userSnap = await db.collection(Collections.users).doc(userId).get();
  if (!userSnap.exists) notFound("User not found.");
  const user = userSnap.data() as UserProfile;
  if (!user.email) invalidArgument("This user has no email on file.");

  await queueEmail({ to: user.email, subject, html: body });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "send_admin_email",
    target: userId,
    metadata: { subject },
  });

  return { success: true };
});
