import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/**
 * Function #14a. Support-desk shortcut: reassigns directly, no explicit
 * unpair step required first. Still enforces one-device-per-user by
 * unpairing anything the target user already owned (Part 4, decision #6).
 */
export const reassignDevice = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { deviceId, userId } = (request.data ?? {}) as { deviceId?: string; userId?: string };
  if (!deviceId || !userId) invalidArgument("deviceId and userId are required.");

  const deviceRef = db.collection(Collections.devices).doc(deviceId);

  await db.runTransaction(async (tx) => {
    const deviceSnap = await tx.get(deviceRef);
    if (!deviceSnap.exists) notFound("Device not found.");

    const previouslyOwned = await tx.get(
      db.collection(Collections.devices).where("owner_user_id", "==", userId)
    );
    previouslyOwned.forEach((doc) => {
      if (doc.id !== deviceId) {
        tx.update(doc.ref, { owner_user_id: null, paired_at: null });
      }
    });

    tx.update(deviceRef, {
      owner_user_id: userId,
      paired_at: FieldValue.serverTimestamp(),
    });
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "reassign_device",
    target: deviceId,
    metadata: { new_owner: userId },
  });

  return { success: true };
});
