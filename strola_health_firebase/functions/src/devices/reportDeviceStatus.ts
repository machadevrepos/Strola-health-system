import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument, notFound } from "../lib/auth-helpers";
import type { Device } from "../lib/types";

/**
 * Called from the Flutter app while a BLE session is live — a heartbeat so
 * `last_seen_at` (and, once the firmware exposes real characteristics for
 * them, `battery_level` / `firmware_version`) reflect the device's actual
 * live state on the admin dashboard, not just a snapshot frozen at the
 * moment it was first paired.
 */
export const reportDeviceStatus = onCall(async (request) => {
  const uid = requireAuth(request);
  const { batteryLevel, firmwareVersion } = (request.data ?? {}) as {
    batteryLevel?: number;
    firmwareVersion?: string;
  };
  if (batteryLevel !== undefined && (typeof batteryLevel !== "number" || batteryLevel < 0 || batteryLevel > 100)) {
    invalidArgument("batteryLevel must be a number between 0 and 100.");
  }

  const owned = await db
    .collection(Collections.devices)
    .where("owner_user_id", "==", uid)
    .limit(1)
    .get();
  if (owned.empty) notFound("No device paired to this account.");

  const deviceRef = owned.docs[0].ref;
  const device = owned.docs[0].data() as Device;

  await deviceRef.update({
    last_seen_at: FieldValue.serverTimestamp(),
    last_synced_at: FieldValue.serverTimestamp(),
    battery_level: batteryLevel ?? device.battery_level ?? null,
    firmware_version: firmwareVersion ?? device.firmware_version ?? null,
  });

  return { success: true };
});
