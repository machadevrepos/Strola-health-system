import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument } from "../lib/auth-helpers";

/** Function #39. Token itself is the doc id — re-registering the same
 * token (app reinstall, token refresh callback firing twice) is a no-op
 * upsert rather than a duplicate. */
export const registerDeviceToken = onCall(async (request) => {
  const uid = requireAuth(request);
  const { token, platform } = (request.data ?? {}) as { token?: string; platform?: string };
  if (!token) invalidArgument("token is required.");

  await db
    .collection(Collections.deviceTokens(uid))
    .doc(token)
    .set({ token, platform: platform ?? null, updated_at: FieldValue.serverTimestamp() });

  return { success: true };
});

export const unregisterDeviceToken = onCall(async (request) => {
  const uid = requireAuth(request);
  const { token } = (request.data ?? {}) as { token?: string };
  if (!token) invalidArgument("token is required.");

  await db.collection(Collections.deviceTokens(uid)).doc(token).delete();
  return { success: true };
});
