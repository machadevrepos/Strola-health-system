import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { deliverPushNotification } from "./sendPushNotification";

/** Function #41. Cloud Scheduler's replacement for the mock's `scheduled`
 * status having no real dispatcher behind it. */
export const dispatchScheduledPush = onSchedule("every 5 minutes", async () => {
  const now = new Date();
  const dueSnap = await db
    .collection(Collections.pushNotifications)
    .where("status", "==", "scheduled")
    .where("scheduled_at", "<=", now)
    .get();

  for (const doc of dueSnap.docs) {
    try {
      await deliverPushNotification(doc.id);
    } catch (err) {
      logger.error(`dispatchScheduledPush failed for ${doc.id}`, err as Error);
    }
  }
});
