import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument } from "../lib/auth-helpers";
import { enforceRateLimit, RateLimits } from "../lib/rateLimit";
import { APP_CHECK_ENFORCED } from "../lib/appCheck";
import { pairId } from "./friends";

/** Function #38a. UID-based (fixes the Flutter app's name-based blocking
 * bug — see friends.ts::pairId). Also dissolves any existing friendship. */
export const blockUser = onCall({ enforceAppCheck: APP_CHECK_ENFORCED }, async (request) => {
  const uid = requireAuth(request);
  await enforceRateLimit(uid, "blockUser", RateLimits.blockUser);
  const { blockedUserId } = (request.data ?? {}) as { blockedUserId?: string };
  if (!blockedUserId || blockedUserId === uid) invalidArgument("A valid blockedUserId is required.");

  await db
    .collection(Collections.blockedUsers)
    .doc(`${uid}_${blockedUserId}`)
    .set({
      blocker_id: uid,
      blocked_id: blockedUserId,
      created_at: FieldValue.serverTimestamp(),
    });

  await db
    .collection(Collections.friendships)
    .doc(pairId(uid, blockedUserId))
    .delete()
    .catch(() => undefined);

  return { success: true };
});

/** Function #38b. */
export const unblockUser = onCall(async (request) => {
  const uid = requireAuth(request);
  const { blockedUserId } = (request.data ?? {}) as { blockedUserId?: string };
  if (!blockedUserId) invalidArgument("blockedUserId is required.");

  await db.collection(Collections.blockedUsers).doc(`${uid}_${blockedUserId}`).delete();
  return { success: true };
});
