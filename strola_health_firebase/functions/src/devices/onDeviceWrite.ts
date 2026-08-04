import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import type { Device } from "../lib/types";

/** Function #16. Firestore trigger — logs a pairing/unpairing event
 * whenever `owner_user_id` transitions, independent of which callable
 * caused it (reassign, force-unpair, mark-replaced, or a user's own pair). */
export const onDeviceWrite = onDocumentWritten(
  `${Collections.devices}/{deviceId}`,
  async (event) => {
    const before = event.data?.before.data() as Device | undefined;
    const after = event.data?.after.data() as Device | undefined;
    const deviceId = event.params.deviceId;

    const beforeOwner = before?.owner_user_id ?? null;
    const afterOwner = after?.owner_user_id ?? null;
    if (beforeOwner === afterOwner) return;

    const ref = db.collection(Collections.devicePairingEvents).doc();

    if (afterOwner && afterOwner !== beforeOwner) {
      await ref.set({
        id: ref.id,
        device_id: deviceId,
        user_id: afterOwner,
        event: "paired",
        at: FieldValue.serverTimestamp(),
        reason: beforeOwner ? "reassigned" : null,
      });
    } else if (!afterOwner && beforeOwner) {
      await ref.set({
        id: ref.id,
        device_id: deviceId,
        user_id: beforeOwner,
        event: "unpaired",
        at: FieldValue.serverTimestamp(),
        reason: after?.replaced_at ? "warranty_swap" : "user_unpaired",
      });
    }
  }
);
