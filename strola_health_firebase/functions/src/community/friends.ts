import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument, notFound, failedPrecondition } from "../lib/auth-helpers";
import { enforceRateLimit, RateLimits } from "../lib/rateLimit";
import { APP_CHECK_ENFORCED } from "../lib/appCheck";
import type { Friendship, UserProfile } from "../lib/types";

/** Deterministic doc id for a pair regardless of who acts first — fixes the
 * Flutter app's name-based blocking bug at the schema level (UID pairs, not
 * display names) and gives friendships a natural single source of truth. */
export function pairId(a: string, b: string): string {
  return [a, b].sort().join("_");
}

/** Function #37a. */
export const sendFriendRequest = onCall({ enforceAppCheck: APP_CHECK_ENFORCED }, async (request) => {
  const uid = requireAuth(request);
  await enforceRateLimit(uid, "sendFriendRequest", RateLimits.sendFriendRequest);
  const { targetUserId } = (request.data ?? {}) as { targetUserId?: string };
  if (!targetUserId || targetUserId === uid) invalidArgument("A valid targetUserId is required.");

  const targetSnap = await db.collection(Collections.users).doc(targetUserId).get();
  if (!targetSnap.exists) notFound("User not found.");
  const target = targetSnap.data() as UserProfile;
  if (!target.privacy.allow_friend_requests) {
    failedPrecondition("This user isn't accepting friend requests.");
  }

  const id = pairId(uid, targetUserId);
  const ref = db.collection(Collections.friendships).doc(id);
  const existing = await ref.get();
  if (existing.exists) failedPrecondition("A friendship or request already exists between these users.");

  await ref.set({
    id,
    uids: [uid, targetUserId].sort(),
    status: "pending",
    requested_by: uid,
    created_at: FieldValue.serverTimestamp(),
    responded_at: null,
  });
  return { success: true };
});

/** Function #37b. */
export const respondFriendRequest = onCall(async (request) => {
  const uid = requireAuth(request);
  const { requesterId, accept } = (request.data ?? {}) as { requesterId?: string; accept?: boolean };
  if (!requesterId || accept === undefined) invalidArgument("requesterId and accept are required.");

  const ref = db.collection(Collections.friendships).doc(pairId(uid, requesterId));
  const snap = await ref.get();
  if (!snap.exists) notFound("No pending request found.");
  const friendship = snap.data() as Friendship;
  if (friendship.requested_by === uid) failedPrecondition("You can't respond to your own request.");

  if (accept) {
    await ref.update({ status: "accepted", responded_at: FieldValue.serverTimestamp() });
  } else {
    await ref.delete();
  }
  return { success: true };
});

/** Function #37c. */
export const removeFriend = onCall(async (request) => {
  const uid = requireAuth(request);
  const { friendUserId } = (request.data ?? {}) as { friendUserId?: string };
  if (!friendUserId) invalidArgument("friendUserId is required.");

  const ref = db.collection(Collections.friendships).doc(pairId(uid, friendUserId));
  const snap = await ref.get();
  if (!snap.exists) notFound("No friendship found.");

  await ref.delete();
  return { success: true };
});
