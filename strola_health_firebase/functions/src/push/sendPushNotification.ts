import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import { resolveSegmentUserIds } from "./segments";
import { getTokensForUsers, sendPushToTokens } from "../lib/fcm";
import type { PushNotification } from "../lib/types";

/** Internal, reused by both the callable below and dispatchScheduledPush. */
export async function deliverPushNotification(notificationId: string): Promise<void> {
  const ref = db.collection(Collections.pushNotifications).doc(notificationId);
  const snap = await ref.get();
  if (!snap.exists) throw new Error("Notification not found.");
  const notification = snap.data() as PushNotification;

  const userIds = await resolveSegmentUserIds(notification.segment, {
    challengeId: notification.link_challenge_id ?? undefined,
  });
  const tokens = await getTokensForUsers(userIds);
  const { successCount } = await sendPushToTokens(tokens, {
    title: notification.title,
    body: notification.body,
    data: {
      link_target: notification.link_target ?? "",
      link_challenge_id: notification.link_challenge_id ?? "",
      link_custom_path: notification.link_custom_path ?? "",
    },
  });

  await ref.update({
    status: "sent",
    recipient_count: userIds.length,
    delivered_count: successCount,
    sent_at: FieldValue.serverTimestamp(),
  });
}

/** Function #40. Sends a brand-new notification immediately (segment
 * resolved and saved in the same call) OR an existing draft/scheduled one
 * by id — either shape the admin panel's composer needs ("Send now" on a
 * fresh compose vs. "Send now" on a saved draft). */
export const sendPushNotification = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { notificationId, ...draft } = (request.data ?? {}) as {
    notificationId?: string;
    segment?: PushNotification["segment"];
    title?: string;
    body?: string;
    linkTarget?: string;
    linkChallengeId?: string;
    linkCustomPath?: string;
  };

  let targetId = notificationId;
  if (!targetId) {
    if (!draft.segment || !draft.title?.trim() || !draft.body?.trim()) {
      invalidArgument("segment, title, and body are required when sending a new notification.");
    }
    const ref = db.collection(Collections.pushNotifications).doc();
    await ref.set({
      id: ref.id,
      segment: draft.segment,
      title: draft.title,
      body: draft.body,
      link_target: draft.linkTarget ?? null,
      link_challenge_id: draft.linkChallengeId ?? null,
      link_custom_path: draft.linkCustomPath ?? null,
      status: "draft",
      scheduled_at: null,
      recipient_count: 0,
      delivered_count: 0,
      opened_count: 0,
      sent_by: callerUid,
      created_at: FieldValue.serverTimestamp(),
      sent_at: null,
    });
    targetId = ref.id;
  } else {
    const snap = await db.collection(Collections.pushNotifications).doc(targetId).get();
    if (!snap.exists) notFound("Notification not found.");
  }

  await deliverPushNotification(targetId!);

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "send_push_notification",
    target: targetId,
  });

  return { success: true, notificationId: targetId };
});
