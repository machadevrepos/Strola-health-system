import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/**
 * Function #14b. Support-case action (lost device, warranty swap) — not
 * for routine disconnects. Leaves the device in the fleet as available stock.
 *
 * Deliberately does NOT clear `paired_at` — deleteDevice.ts treats a
 * non-null `paired_at` as "this device has pairing history, hard-delete is
 * blocked, use markDeviceReplaced instead." Clearing it here would erase
 * that signal and let a device that was genuinely once paired get
 * hard-deleted after a force-unpair (caught by test-all.js's devices suite).
 */
export const forceUnpairDevice = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { deviceId } = (request.data ?? {}) as { deviceId?: string };
  if (!deviceId) invalidArgument("deviceId is required.");

  const deviceRef = db.collection(Collections.devices).doc(deviceId);
  const snap = await deviceRef.get();
  if (!snap.exists) notFound("Device not found.");

  await deviceRef.update({ owner_user_id: null });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "force_unpair_device",
    target: deviceId,
  });

  return { success: true };
});
