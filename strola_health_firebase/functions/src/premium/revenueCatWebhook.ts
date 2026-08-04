import { onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { REVENUECAT_WEBHOOK_SECRET } from "../lib/secrets";

interface RevenueCatEvent {
  type: string;
  app_user_id: string;
  expiration_at_ms?: number;
  event_timestamp_ms: number;
  product_id?: string;
}

const ACTIVE_EVENT_TYPES = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "UNCANCELLATION",
  "PRODUCT_CHANGE",
  "NON_RENEWING_PURCHASE",
]);
const CANCEL_EVENT_TYPES = new Set(["CANCELLATION"]);
const EXPIRE_EVENT_TYPES = new Set(["EXPIRATION"]);

/**
 * Function #44. Keeps `subscription.{tier,status,renews_at,cancelled_at,
 * revenuecat_app_user_id}` in sync — deliberately never touches
 * `comp_until`/`comp_reason` (the fully independent admin-grant path, see
 * grantExtendRevokePremium.ts). `app_user_id` is expected to be the Firebase
 * uid (set via `Purchases.logIn(firebaseUid)` client-side).
 */
export const revenueCatWebhook = onRequest(
  { secrets: [REVENUECAT_WEBHOOK_SECRET] },
  async (req, res) => {
    const authHeader = req.headers.authorization;
    if (authHeader !== `Bearer ${REVENUECAT_WEBHOOK_SECRET.value()}`) {
      res.status(401).send("Unauthorized");
      return;
    }

    const event = (req.body?.event ?? {}) as RevenueCatEvent;
    if (!event.app_user_id || !event.type) {
      res.status(400).send("Missing event.app_user_id or event.type");
      return;
    }

    await db.collection(Collections.revenueCatEvents).add({
      ...event,
      received_at: FieldValue.serverTimestamp(),
    });

    const userRef = db.collection(Collections.users).doc(event.app_user_id);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
      logger.warn(`RevenueCat event for unknown user ${event.app_user_id}`, event);
      res.status(200).send("OK"); // ack so RevenueCat doesn't retry forever
      return;
    }

    const patch: Record<string, unknown> = {
      "subscription.revenuecat_app_user_id": event.app_user_id,
    };

    if (ACTIVE_EVENT_TYPES.has(event.type)) {
      patch["subscription.tier"] = "premium";
      patch["subscription.status"] = "active";
      patch["subscription.cancelled_at"] = null;
      if (event.expiration_at_ms) {
        patch["subscription.renews_at"] = Timestamp.fromMillis(event.expiration_at_ms);
      }
    } else if (CANCEL_EVENT_TYPES.has(event.type)) {
      patch["subscription.status"] = "cancelled";
      patch["subscription.cancelled_at"] = Timestamp.fromMillis(event.event_timestamp_ms);
    } else if (EXPIRE_EVENT_TYPES.has(event.type)) {
      patch["subscription.tier"] = "free";
      patch["subscription.status"] = "expired";
    }

    await userRef.update(patch);
    res.status(200).send("OK");
  }
);
