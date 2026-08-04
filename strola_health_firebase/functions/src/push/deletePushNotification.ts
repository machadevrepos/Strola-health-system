import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound, failedPrecondition } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import type { PushNotification } from "../lib/types";

/** Discard a draft or cancel a scheduled send — not for already-sent history. */
export const deletePushNotification = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { notificationId } = (request.data ?? {}) as { notificationId?: string };
  if (!notificationId) invalidArgument("notificationId is required.");

  const ref = db.collection(Collections.pushNotifications).doc(notificationId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Notification not found.");
  const notification = snap.data() as PushNotification;
  if (notification.status === "sent") failedPrecondition("Can't delete a notification that's already sent.");

  await ref.delete();

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "delete_push_notification",
    target: notificationId,
  });
  return { success: true };
});
