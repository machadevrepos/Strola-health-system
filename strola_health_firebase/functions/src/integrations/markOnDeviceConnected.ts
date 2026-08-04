import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument } from "../lib/auth-helpers";
import { isOnDeviceProvider } from "./providerConfig";

/**
 * Function #56. HealthKit/Health Connect never go through an OAuth
 * redirect — the OS permission dialog is the entire "connect" step, so the
 * app just confirms it here. Matches `POST /integrations/{provider}/connected`.
 */
export const markOnDeviceConnected = onCall(async (request) => {
  const uid = requireAuth(request);
  const { provider } = (request.data ?? {}) as { provider?: string };
  if (!provider || !isOnDeviceProvider(provider)) {
    invalidArgument("provider must be healthkit or health_connect.");
  }

  const ref = db.collection(Collections.integrationConnections).doc(`${uid}_${provider}`);
  await ref.set(
    {
      id: `${uid}_${provider}`,
      user_id: uid,
      provider,
      status: "connected",
      access_token: null,
      refresh_token: null,
      expires_at: null,
      scopes: [],
      external_athlete_id: null,
      connected_at: FieldValue.serverTimestamp(),
      error_message: null,
    },
    { merge: true }
  );

  return { success: true };
});
