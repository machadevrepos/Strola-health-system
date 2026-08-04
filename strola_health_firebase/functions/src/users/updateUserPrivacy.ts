import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
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

/** Admin toggling one of a user's 7 privacy settings from their profile page. */
export const updateUserPrivacy = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { userId, ...updates } = (request.data ?? {}) as {
    userId?: string;
  } & Partial<Record<(typeof PRIVACY_FIELDS)[number], boolean>>;
  if (!userId) invalidArgument("userId is required.");

  const ref = db.collection(Collections.users).doc(userId);
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
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "update_user_privacy",
    target: userId,
    metadata: patch,
  });

  return { success: true };
});
