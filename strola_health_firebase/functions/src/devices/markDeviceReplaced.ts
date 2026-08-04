import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/**
 * Function #14c. Permanent retirement (lost/warranty swap) — a single
 * transaction combining unpair + retire, per the audit's explicit note that
 * the mock UI did these as two separate writes (a partial-failure risk this
 * version removes). No "un-replace" exists by design — dead end in the fleet.
 *
 * paired_at is deliberately left untouched — same reasoning as
 * forceUnpairDevice: it's the device's permanent "was this ever paired"
 * record, not a "currently paired" flag (owner_user_id is that). deleteDevice
 * relies on paired_at staying set to refuse hard-deleting a device with real
 * pairing history; nulling it here would let that check be bypassed simply
 * by replacing a device before trying to delete it.
 */
export const markDeviceReplaced = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { deviceId } = (request.data ?? {}) as { deviceId?: string };
  if (!deviceId) invalidArgument("deviceId is required.");

  const deviceRef = db.collection(Collections.devices).doc(deviceId);
  const snap = await deviceRef.get();
  if (!snap.exists) notFound("Device not found.");

  await deviceRef.update({
    owner_user_id: null,
    replaced_at: FieldValue.serverTimestamp(),
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "mark_device_replaced",
    target: deviceId,
  });

  return { success: true };
});
