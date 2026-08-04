import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireSuperAdmin, actorLabelFromRequest, invalidArgument, failedPrecondition } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/**
 * Function #12. super_admin only (Part 4, decision #7 — fleet
 * provisioning/delete are elevated actions, matching the super-admin app's
 * all-or-nothing layout gate). Enforces the unique-serial-number constraint
 * the mock UI only ever checked client-side.
 */
export const provisionDevice = onCall(async (request) => {
  const { uid: callerUid } = requireSuperAdmin(request);
  const { serialNumber, manufacturingBatch } = (request.data ?? {}) as {
    serialNumber?: string;
    manufacturingBatch?: string;
  };
  if (!serialNumber?.trim()) invalidArgument("serialNumber is required.");

  const existing = await db
    .collection(Collections.devices)
    .where("serial_number", "==", serialNumber)
    .limit(1)
    .get();
  if (!existing.empty) {
    failedPrecondition(`Serial number ${serialNumber} is already provisioned.`);
  }

  const ref = db.collection(Collections.devices).doc();
  const now = FieldValue.serverTimestamp();
  await ref.set({
    id: ref.id,
    serial_number: serialNumber,
    device_type: "strolla_nrf7002",
    ble_mac: null,
    firmware_version: null,
    manufacturing_batch: manufacturingBatch ?? null,
    owner_user_id: null,
    paired_at: null,
    last_seen_at: null,
    battery_level: null,
    last_synced_at: null,
    created_at: now,
    replaced_at: null,
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "provision_device",
    target: ref.id,
    metadata: { serial_number: serialNumber },
  });

  return { success: true, deviceId: ref.id };
});
