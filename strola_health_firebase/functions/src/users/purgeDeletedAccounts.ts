import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { writeAuditLog } from "../lib/audit";
import { purgeUserData } from "./purgeUserData";

export const RETENTION_DAYS = 90;

/**
 * Function #? — retention policy for `deleteAccount.ts`'s soft-delete:
 * scrubbed accounts keep their (now-anonymous) workout/community history
 * for 90 days, then everything is hard-deleted. Same pattern as
 * dispatchScheduledPush.ts (a daily `onSchedule`, not a queue).
 */
export const purgeDeletedAccounts = onSchedule("every 24 hours", async () => {
  const cutoff = Timestamp.fromMillis(Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000);
  const dueSnap = await db
    .collection(Collections.users)
    .where("deleted", "==", true)
    .where("deleted_at", "<=", cutoff)
    .get();

  for (const doc of dueSnap.docs) {
    const uid = doc.id;
    try {
      await purgeUserData(uid);
      await writeAuditLog({
        actorUid: "system",
        actor: "purgeDeletedAccounts (scheduled)",
        action: "purge_account",
        target: uid,
      });
    } catch (err) {
      logger.error(`purgeDeletedAccounts failed for ${uid}`, err as Error);
    }
  }
});
