import { onCall } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import type { Announcement, AnnouncementAudience } from "../lib/types";

/**
 * Announcements CRUD — the admin panel's Announcements section didn't get
 * explicit numbered functions in the original Part 3 plan (an oversight
 * caught during implementation); added here alongside Legal/Settings since
 * it's the same "admin-editable content" shape.
 */
export const createAnnouncement = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const {
    emoji,
    message,
    linkTarget,
    audience,
    audienceAppVersion,
    audienceAppVersionMode,
    startsAtMillis,
    endsAtMillis,
  } = (request.data ?? {}) as {
    emoji?: string;
    message?: string;
    linkTarget?: string;
    audience?: AnnouncementAudience;
    audienceAppVersion?: string;
    audienceAppVersionMode?: "exact" | "at_or_below";
    startsAtMillis?: number;
    endsAtMillis?: number;
  };
  if (!message?.trim() || !audience) invalidArgument("message and audience are required.");

  const ref = db.collection(Collections.announcements).doc();
  await ref.set({
    id: ref.id,
    emoji: emoji ?? "📣",
    message,
    link_target: linkTarget ?? null,
    audience,
    audience_app_version: audienceAppVersion ?? null,
    audience_app_version_mode: audienceAppVersionMode ?? null,
    active: false,
    starts_at: startsAtMillis ? Timestamp.fromMillis(startsAtMillis) : FieldValue.serverTimestamp(),
    ends_at: endsAtMillis ? Timestamp.fromMillis(endsAtMillis) : null,
    created_by: callerUid,
    created_at: FieldValue.serverTimestamp(),
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "create_announcement",
    target: ref.id,
  });
  return { success: true, announcementId: ref.id };
});

export const updateAnnouncement = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { announcementId, ...updates } = (request.data ?? {}) as {
    announcementId?: string;
    emoji?: string;
    message?: string;
    linkTarget?: string;
    audience?: AnnouncementAudience;
    audienceAppVersion?: string;
    audienceAppVersionMode?: "exact" | "at_or_below";
    startsAtMillis?: number;
    endsAtMillis?: number;
  };
  if (!announcementId) invalidArgument("announcementId is required.");

  const ref = db.collection(Collections.announcements).doc(announcementId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Announcement not found.");

  const patch: Record<string, unknown> = {};
  if (updates.emoji !== undefined) patch.emoji = updates.emoji;
  if (updates.message !== undefined) patch.message = updates.message;
  if (updates.linkTarget !== undefined) patch.link_target = updates.linkTarget;
  if (updates.audience !== undefined) patch.audience = updates.audience;
  if (updates.audienceAppVersion !== undefined) patch.audience_app_version = updates.audienceAppVersion;
  if (updates.audienceAppVersionMode !== undefined) patch.audience_app_version_mode = updates.audienceAppVersionMode;
  if (updates.startsAtMillis !== undefined) patch.starts_at = Timestamp.fromMillis(updates.startsAtMillis);
  if (updates.endsAtMillis !== undefined) patch.ends_at = Timestamp.fromMillis(updates.endsAtMillis);
  await ref.update(patch);

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "update_announcement",
    target: announcementId,
  });
  return { success: true };
});

export const duplicateAnnouncement = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { announcementId } = (request.data ?? {}) as { announcementId?: string };
  if (!announcementId) invalidArgument("announcementId is required.");

  const snap = await db.collection(Collections.announcements).doc(announcementId).get();
  if (!snap.exists) notFound("Announcement not found.");
  const source = snap.data() as Announcement;

  const ref = db.collection(Collections.announcements).doc();
  await ref.set({
    ...source,
    id: ref.id,
    active: false,
    created_by: callerUid,
    created_at: FieldValue.serverTimestamp(),
    starts_at: FieldValue.serverTimestamp(),
    ends_at: null,
  });

  return { success: true, announcementId: ref.id };
});

export const toggleAnnouncement = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { announcementId, active } = (request.data ?? {}) as {
    announcementId?: string;
    active?: boolean;
  };
  if (!announcementId || active === undefined) invalidArgument("announcementId and active are required.");

  const ref = db.collection(Collections.announcements).doc(announcementId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Announcement not found.");

  await ref.update({ active });
  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: active ? "activate_announcement" : "deactivate_announcement",
    target: announcementId,
  });
  return { success: true };
});

export const deleteAnnouncement = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { announcementId } = (request.data ?? {}) as { announcementId?: string };
  if (!announcementId) invalidArgument("announcementId is required.");

  const ref = db.collection(Collections.announcements).doc(announcementId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Announcement not found.");

  await ref.delete();
  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "delete_announcement",
    target: announcementId,
  });
  return { success: true };
});
