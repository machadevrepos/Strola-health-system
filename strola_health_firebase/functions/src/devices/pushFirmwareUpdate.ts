import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/**
 * Function #15. As the audit notes, there's no real OTA channel yet — this
 * only sets the target firmware_version string a paired device would poll
 * for. Real device-side OTA delivery is out of scope for Cloud Functions.
 */
export const pushFirmwareUpdate = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { deviceId, version } = (request.data ?? {}) as { deviceId?: string; version?: string };
  if (!deviceId || !version?.trim()) invalidArgument("deviceId and version are required.");

  const deviceRef = db.collection(Collections.devices).doc(deviceId);
  const snap = await deviceRef.get();
  if (!snap.exists) notFound("Device not found.");

  await deviceRef.update({ firmware_version: version });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "push_firmware_update",
    target: deviceId,
    metadata: { version },
  });

  return { success: true };
});
