import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

const PRIVACY_FIELDS = [
  "public_profile",
  "share_activity",
  "show_in_leaderboards",
  "allow_friend_requests",
  "hide_activity_data",
  "hide_achievements",
  "hide_recent_activity",
  "hide_location",
] as const;

/**
 * Self-service counterpart to updateUserPrivacy (admin-only). The mobile
 * app's Privacy Settings screen currently only writes to SharedPreferences
 * and never calls anything — found during the Flutter migration audit.
 * Always operates on the caller's own uid.
 */
export const updateMyPrivacy = onCall(async (request) => {
  const uid = requireAuth(request);
  const updates = (request.data ?? {}) as Partial<Record<(typeof PRIVACY_FIELDS)[number], boolean>>;

  const ref = db.collection(Collections.users).doc(uid);
  const snap = await ref.get();
  if (!snap.exists) notFound("User not found.");

  const patch: Record<string, unknown> = {};
  for (const field of PRIVACY_FIELDS) {
    if (updates[field] !== undefined) patch[`privacy.${field}`] = updates[field];
  }
  if (Object.keys(patch).length === 0) invalidArgument("At least one privacy field is required.");
  patch.updated_at = FieldValue.serverTimestamp();

  await ref.update(patch);

  await writeAuditLog({
    actorUid: uid,
    actor: "self",
    action: "update_my_privacy",
    target: uid,
    metadata: patch,
  });

  return { success: true };
});
