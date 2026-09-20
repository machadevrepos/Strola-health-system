import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument } from "../lib/auth-helpers";

const COUNTER_FIELD = {
  seen: "seen_count",
  dismissed: "dismissed_count",
  clicked: "clicked_count",
} as const;

type AnnouncementEvent = keyof typeof COUNTER_FIELD;

/**
 * Real seen/dismissed/clicked counts for the admin panel's announcement
 * analytics — replaces `announcementStats`'s old formula, which fabricated
 * all three from a seeded random fraction of the audience size rather than
 * tracking anything a member actually did. Called from
 * announcement_repository.dart: "seen" the moment `getActiveAnnouncement`
 * resolves one to show, "dismissed" on the banner's close tap (alongside
 * the existing local SharedPreferences dismiss, which is a separate
 * per-device "don't show again" concern, not a replacement for this),
 * "clicked" when the banner's own content is tapped and it has a
 * `link_target`.
 *
 * Simple increments, not per-user unique counts — same style as
 * `pushNotifications.delivered_count`/`opened_count`.
 */
export const trackAnnouncementEvent = onCall(async (request) => {
  requireAuth(request);
  const { announcementId, event } = (request.data ?? {}) as {
    announcementId?: string;
    event?: string;
  };
  if (!announcementId) invalidArgument("announcementId is required.");
  if (!event || !(event in COUNTER_FIELD)) invalidArgument("event must be one of: seen, dismissed, clicked.");

  const ref = db.collection(Collections.announcements).doc(announcementId!);
  const snap = await ref.get();
  if (!snap.exists) return { success: true };

  await ref.update({ [COUNTER_FIELD[event as AnnouncementEvent]]: FieldValue.increment(1) });
  return { success: true };
});
