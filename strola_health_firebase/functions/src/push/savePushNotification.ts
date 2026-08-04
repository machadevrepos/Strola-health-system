import { onCall } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import { resolveSegmentUserIds } from "./segments";
import type { PushSegment } from "../lib/types";

/**
 * Backs the composer's "Save as draft" / "Schedule" / "Edit existing draft"
 * actions from the admin panel's Push Notifications page — one upsert,
 * status derives from whether `scheduledAtMillis` was supplied.
 */
export const savePushNotification = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const {
    notificationId,
    segment,
    title,
    body,
    linkTarget,
    linkChallengeId,
    linkCustomPath,
    scheduledAtMillis,
  } = (request.data ?? {}) as {
    notificationId?: string;
    segment?: PushSegment;
    title?: string;
    body?: string;
    linkTarget?: string;
    linkChallengeId?: string;
    linkCustomPath?: string;
    scheduledAtMillis?: number;
  };
  if (!segment || !title?.trim() || !body?.trim()) {
    invalidArgument("segment, title, and body are required.");
  }
  if (title!.length > 65) invalidArgument("title must be 65 characters or fewer.");
  if (body!.length > 178) invalidArgument("body must be 178 characters or fewer.");

  const recipientCount = (await resolveSegmentUserIds(segment!, { challengeId: linkChallengeId })).length;

  const ref = notificationId
    ? db.collection(Collections.pushNotifications).doc(notificationId)
    : db.collection(Collections.pushNotifications).doc();

  if (notificationId) {
    const existing = await ref.get();
    if (!existing.exists) notFound("Notification not found.");
  }

  await ref.set(
    {
      id: ref.id,
      segment,
      title,
      body,
      link_target: linkTarget ?? null,
      link_challenge_id: linkChallengeId ?? null,
      link_custom_path: linkCustomPath ?? null,
      status: scheduledAtMillis ? "scheduled" : "draft",
      scheduled_at: scheduledAtMillis ? Timestamp.fromMillis(scheduledAtMillis) : null,
      recipient_count: recipientCount,
      delivered_count: 0,
      opened_count: 0,
      sent_by: callerUid,
      created_at: FieldValue.serverTimestamp(),
      sent_at: null,
    },
    { merge: true }
  );

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: notificationId ? "update_push_notification" : "draft_push_notification",
    target: ref.id,
  });

  return { success: true, notificationId: ref.id, recipientCount };
});
