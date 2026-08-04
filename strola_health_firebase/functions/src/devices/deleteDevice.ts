import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireSuperAdmin, actorLabelFromRequest, invalidArgument, notFound, failedPrecondition } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import type { Device } from "../lib/types";

/**
 * Function #14d. super_admin only (Part 4, decision #7). Enforced server-side
 * (not just hidden client-side, as in the mock): a device that has EVER been
 * paired cannot be hard-deleted, only marked replaced — no ownership/warranty
 * history to lose only applies to never-paired stock.
 */
export const deleteDevice = onCall(async (request) => {
  const { uid: callerUid } = requireSuperAdmin(request);
  const { deviceId } = (request.data ?? {}) as { deviceId?: string };
  if (!deviceId) invalidArgument("deviceId is required.");

  const deviceRef = db.collection(Collections.devices).doc(deviceId);
  const snap = await deviceRef.get();
  if (!snap.exists) notFound("Device not found.");
  const device = snap.data() as Device;

  if (device.owner_user_id || device.paired_at) {
    failedPrecondition("This device has pairing history — use markDeviceReplaced instead.");
  }

  await deviceRef.delete();

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "delete_device",
    target: deviceId,
    metadata: { serial_number: device.serial_number },
  });

  return { success: true };
});
