import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, authAdmin } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, requireAdmin, actorLabelFromRequest, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/**
 * Function #5. Scrubs PII but deliberately KEEPS workout history, GPS
 * routes, and community posts (per the admin panel's existing
 * DeleteAccountDialog policy) — sets deleted=true and blanks
 * name/email/bio/photo/location/DOB, everything else (sessions, posts,
 * badges) stays exactly as-is and still renders correctly via
 * PublicUserProfile's "Deleted User" fallback.
 *
 * Callable with no `userId` = self-delete (the Flutter app's Settings flow).
 * Callable with `userId` set by an admin/super_admin = admin-initiated
 * delete (the admin panel's Users page flow).
 */
export const deleteAccount = onCall(async (request) => {
  const callerUid = requireAuth(request);
  const { userId } = (request.data ?? {}) as { userId?: string };
  const targetId = userId ?? callerUid;
  const isAdminInitiated = targetId !== callerUid;

  if (isAdminInitiated) {
    requireAdmin(request);
  }

  const userRef = db.collection(Collections.users).doc(targetId);
  const snap = await userRef.get();
  if (!snap.exists) notFound("User not found.");

  await userRef.update({
    deleted: true,
    deleted_at: FieldValue.serverTimestamp(),
    name: "Deleted User",
    username: `deleted_${targetId}`,
    email: null,
    bio: null,
    photo_url: null,
    location: null,
    date_of_birth: null,
    updated_at: FieldValue.serverTimestamp(),
  });

  // Cascade: any device this user owned goes back to available stock.
  const ownedDevices = await db
    .collection(Collections.devices)
    .where("owner_user_id", "==", targetId)
    .get();
  if (!ownedDevices.empty) {
    const batch = db.batch();
    ownedDevices.forEach((doc) =>
      batch.update(doc.ref, { owner_user_id: null, paired_at: null })
    );
    await batch.commit();
  }

  // Best-effort: the Auth user may already be gone if this was triggered
  // right after the client's own `user.delete()` call.
  await authAdmin.deleteUser(targetId).catch(() => undefined);

  if (isAdminInitiated) {
    await writeAuditLog({
      actorUid: callerUid,
      actor: actorLabelFromRequest(request),
      action: "delete_account",
      target: targetId,
    });
  }

  return { success: true };
});
