import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument } from "../lib/auth-helpers";

/**
 * Called by push_message_listener.dart's tap handler (both the
 * already-running and cold-launch paths) the moment a member actually opens
 * a push — the other half of the admin panel's Delivered/Opened/CTR
 * numbers. `delivered_count` is set at send time from FCM's own
 * accepted-for-delivery count; this is the only thing that ever moves
 * `opened_count`, which otherwise stays permanently 0.
 *
 * Simple increment, not a per-user unique count — same style as
 * `delivered_count`, and consistent with how this admin panel already
 * treats these as aggregate campaign metrics rather than per-recipient
 * tracking. A no-op (not an error) for a notification id that doesn't
 * exist, since a stale/deleted notification's tray entry can still be
 * tapped after the fact.
 */
export const trackPushOpened = onCall(async (request) => {
  requireAuth(request);
  const { notificationId } = (request.data ?? {}) as { notificationId?: string };
  if (!notificationId) invalidArgument("notificationId is required.");

  const ref = db.collection(Collections.pushNotifications).doc(notificationId!);
  const snap = await ref.get();
  if (!snap.exists) return { success: true };

  await ref.update({ opened_count: FieldValue.increment(1) });
  return { success: true };
});
