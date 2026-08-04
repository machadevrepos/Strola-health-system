import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument, notFound, failedPrecondition } from "../lib/auth-helpers";
import type { Device } from "../lib/types";

/**
 * Function #13. Called from the Flutter app when a user pairs their
 * physical tracker over BLE for the first time. Enforces one-device-per-user
 * (Part 4, decision #6): pairing a new device automatically unpairs any
 * device this user already owned.
 */
export const pairDevice = onCall(async (request) => {
  const uid = requireAuth(request);
  const { serialNumber, bleMac, firmwareVersion } = (request.data ?? {}) as {
    serialNumber?: string;
    bleMac?: string;
    firmwareVersion?: string;
  };
  if (!serialNumber?.trim()) invalidArgument("serialNumber is required.");

  const matches = await db
    .collection(Collections.devices)
    .where("serial_number", "==", serialNumber)
    .limit(1)
    .get();
  if (matches.empty) notFound("No device with that serial number is provisioned.");

  const deviceDoc = matches.docs[0];
  const device = deviceDoc.data() as Device;

  if (device.replaced_at) failedPrecondition("This device has been retired and can't be paired.");
  if (device.owner_user_id && device.owner_user_id !== uid) {
    failedPrecondition("This device is already paired to another account.");
  }

  await db.runTransaction(async (tx) => {
    const previouslyOwned = await tx.get(
      db.collection(Collections.devices).where("owner_user_id", "==", uid)
    );
    previouslyOwned.forEach((doc) => {
      if (doc.id !== deviceDoc.id) {
        tx.update(doc.ref, { owner_user_id: null, paired_at: null });
      }
    });

    tx.update(deviceDoc.ref, {
      owner_user_id: uid,
      paired_at: FieldValue.serverTimestamp(),
      ble_mac: bleMac ?? device.ble_mac ?? null,
      firmware_version: firmwareVersion ?? device.firmware_version ?? null,
      last_seen_at: FieldValue.serverTimestamp(),
    });
  });

  return { success: true, deviceId: deviceDoc.id };
});
