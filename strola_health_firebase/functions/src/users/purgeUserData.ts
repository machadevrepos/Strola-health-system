import type { DocumentReference } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";

const BATCH_SIZE = 450; // Firestore's batch limit is 500; leave headroom.

async function deleteRefs(refs: DocumentReference[]): Promise<void> {
  for (let i = 0; i < refs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    for (const ref of refs.slice(i, i + BATCH_SIZE)) batch.delete(ref);
    await batch.commit();
  }
}

/**
 * Hard-deletes every trace of [uid]'s activity, then the user doc itself.
 * Shared by the scheduled 90-day purge (purgeDeletedAccounts.ts) and the
 * admin-triggered "Purge now" callable (purgeAccountNow.ts) — same
 * operation either way, just a different trigger and a different audit
 * actor.
 *
 * Deliberately NOT gated on `deleted === true` here — that check belongs to
 * each caller (the scheduler's query, the callable's own precondition), not
 * this shared primitive.
 */
export async function purgeUserData(uid: string): Promise<void> {
  // Community posts this user authored — recursiveDelete also removes each
  // post's comments/likes subcollections, not just the post doc.
  const ownPosts = await db.collection(Collections.communityPosts).where("author_id", "==", uid).get();
  for (const doc of ownPosts.docs) {
    await db.recursiveDelete(doc.ref);
  }

  // Comments/likes this user left on OTHER users' posts (not caught above).
  const comments = await db.collectionGroup("comments").where("author_id", "==", uid).get();
  await deleteRefs(comments.docs.map((d) => d.ref));

  const likes = await db.collectionGroup("likes").where("user_id", "==", uid).get();
  await deleteRefs(likes.docs.map((d) => d.ref));

  // Workout/activity history.
  const sessions = await db.collection(Collections.workoutSessions).where("user_id", "==", uid).get();
  await deleteRefs(sessions.docs.map((d) => d.ref));

  const dailyActivity = await db.collection(Collections.dailyActivity).where("user_id", "==", uid).get();
  await deleteRefs(dailyActivity.docs.map((d) => d.ref));

  await db.collection(Collections.personalRecords).doc(uid).delete();

  const badges = await db.collection(Collections.userBadges).where("user_id", "==", uid).get();
  await deleteRefs(badges.docs.map((d) => d.ref));

  // Friendships (either party) and blocks (either direction).
  const friendships = await db.collection(Collections.friendships).where("uids", "array-contains", uid).get();
  await deleteRefs(friendships.docs.map((d) => d.ref));

  const blockedAsBlocker = await db.collection(Collections.blockedUsers).where("blocker_id", "==", uid).get();
  const blockedAsTarget = await db.collection(Collections.blockedUsers).where("blocked_id", "==", uid).get();
  await deleteRefs([...blockedAsBlocker.docs, ...blockedAsTarget.docs].map((d) => d.ref));

  // Challenge participation, in every challenge this user ever joined.
  const participations = await db.collectionGroup("participants").where("user_id", "==", uid).get();
  await deleteRefs(participations.docs.map((d) => d.ref));

  // Device tokens and admin notes live under users/{uid} as subcollections —
  // recursiveDelete removes those along with the user doc itself.
  await db.recursiveDelete(db.collection(Collections.users).doc(uid));
}
