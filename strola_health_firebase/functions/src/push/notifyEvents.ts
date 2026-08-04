import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { getTokensForUsers, sendPushToTokens } from "../lib/fcm";
import type { CommunityComment, CommunityPost } from "../lib/types";

/**
 * Function #43. Replaces the Flutter app's community-notification
 * simulator — `Timer.periodic(90s)` picking a random fake event, explicitly
 * flagged in its own source comment as "no real multi-user backend yet".
 * These triggers are that backend: real comments/likes from real other
 * users, not a random generator.
 */
export const notifyOnCommunityComment = onDocumentCreated(
  `${Collections.communityPosts}/{postId}/comments/{commentId}`,
  async (event) => {
    const comment = event.data?.data() as CommunityComment | undefined;
    if (!comment) return;

    const postSnap = await db.collection(Collections.communityPosts).doc(event.params.postId).get();
    if (!postSnap.exists) return;
    const post = postSnap.data() as CommunityPost;
    if (post.author_id === comment.author_id) return; // don't notify yourself

    const tokens = await getTokensForUsers([post.author_id]);
    await sendPushToTokens(tokens, {
      title: "New comment",
      body: "Someone commented on your post.",
      data: { link_target: "community", post_id: event.params.postId },
    });
  }
);

export const notifyOnPostLike = onDocumentCreated(
  `${Collections.communityPosts}/{postId}/likes/{userId}`,
  async (event) => {
    const likerId = event.params.userId;
    const postSnap = await db.collection(Collections.communityPosts).doc(event.params.postId).get();
    if (!postSnap.exists) return;
    const post = postSnap.data() as CommunityPost;
    if (post.author_id === likerId) return;

    const tokens = await getTokensForUsers([post.author_id]);
    await sendPushToTokens(tokens, {
      title: "New like",
      body: "Someone liked your post.",
      data: { link_target: "community", post_id: event.params.postId },
    });
  }
);

/** A joined challenge's welcome push — real signal (an actual join),
 * unlike the app's fake "challenge started" simulator. */
export const notifyOnChallengeJoin = onDocumentCreated(
  `${Collections.challenges}/{challengeId}/participants/{userId}`,
  async (event) => {
    const userId = event.params.userId;
    const challengeSnap = await db.collection(Collections.challenges).doc(event.params.challengeId).get();
    if (!challengeSnap.exists) return;
    const title = (challengeSnap.data() as { title?: string }).title ?? "a challenge";

    const tokens = await getTokensForUsers([userId]);
    await sendPushToTokens(tokens, {
      title: "Challenge joined",
      body: `You're in — good luck in ${title}!`,
      data: { link_target: "challenge", challenge_id: event.params.challengeId },
    });
  }
);
