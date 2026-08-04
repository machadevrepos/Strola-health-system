import { onSchedule } from "firebase-functions/v2/scheduler";
import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { syncProviderConnection } from "./sync";
import {
  STRAVA_CLIENT_ID,
  STRAVA_CLIENT_SECRET,
  GARMIN_CLIENT_ID,
  GARMIN_CLIENT_SECRET,
  OURA_CLIENT_ID,
  OURA_CLIENT_SECRET,
  MYFITNESSPAL_CLIENT_ID,
  MYFITNESSPAL_CLIENT_SECRET,
} from "../lib/secrets";

/** Function #59. Pulls fresh data for every connected OAuth integration
 * (Strava/Oura; Garmin and MyFitnessPal skipped until API access is
 * approved for each — see sync.ts). */
export const syncOAuthProviderData = onSchedule(
  {
    schedule: "every 6 hours",
    secrets: [
      STRAVA_CLIENT_ID,
      STRAVA_CLIENT_SECRET,
      GARMIN_CLIENT_ID,
      GARMIN_CLIENT_SECRET,
      OURA_CLIENT_ID,
      OURA_CLIENT_SECRET,
      MYFITNESSPAL_CLIENT_ID,
      MYFITNESSPAL_CLIENT_SECRET,
    ],
  },
  async () => {
    const connections = await db
      .collection(Collections.integrationConnections)
      .where("status", "==", "connected")
      .where("provider", "in", ["strava", "oura", "garmin", "myfitnesspal"])
      .get();

    for (const doc of connections.docs) {
      try {
        await syncProviderConnection(doc.id);
        await doc.ref.update({ last_synced_at: FieldValue.serverTimestamp(), error_message: null });
      } catch (err) {
        logger.error(`syncOAuthProviderData failed for ${doc.id}`, err as Error);
        await doc.ref.update({ status: "error", error_message: (err as Error).message });
      }
    }
  }
);
