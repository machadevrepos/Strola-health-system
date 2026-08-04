import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, getRole, invalidArgument, notFound, failedPrecondition } from "../lib/auth-helpers";
import { enforceRateLimit, RateLimits } from "../lib/rateLimit";
import { APP_CHECK_ENFORCED } from "../lib/appCheck";
import type { CommunityComment, CommunityPost, UserProfile } from "../lib/types";

/** Function #34a. `commentsCount` on the parent post is maintained by
 * onCommentWrite (this file's trigger), not incremented here directly. */
export const addComment = onCall({ enforceAppCheck: APP_CHECK_ENFORCED }, async (request) => {
  const uid = requireAuth(request);
  await enforceRateLimit(uid, "addComment", RateLimits.addComment);
  const { postId, content } = (request.data ?? {}) as { postId?: string; content?: string };
  if (!postId || !content?.trim()) invalidArgument("postId and content are required.");

  const postRef = db.collection(Collections.communityPosts).doc(postId);
  const postSnap = await postRef.get();
  if (!postSnap.exists) notFound("Post not found.");
  const post = postSnap.data() as CommunityPost;
  if (post.comments_locked) failedPrecondition("Comments are locked on this post.");

  const userSnap = await db.collection(Collections.users).doc(uid).get();
  const user = userSnap.data() as UserProfile | undefined;
  if (user?.posting_banned) {
    const stillActive = !user.posting_banned_until || user.posting_banned_until.toMillis() > Date.now();
    if (stillActive) failedPrecondition("Your posting access is currently restricted.");
  }

  const ref = db.collection(Collections.postComments(postId)).doc();
  await ref.set({
    id: ref.id,
    post_id: postId,
    author_id: uid,
    content,
    timestamp: FieldValue.serverTimestamp(),
    hidden: false,
  });

  return { success: true, commentId: ref.id };
});

/** Function #34b. */
export const editComment = onCall(async (request) => {
  const uid = requireAuth(request);
  const { postId, commentId, content } = (request.data ?? {}) as {
    postId?: string;
    commentId?: string;
    content?: string;
  };
  if (!postId || !commentId || !content?.trim()) invalidArgument("postId, commentId, and content are required.");

  const ref = db.collection(Collections.postComments(postId)).doc(commentId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Comment not found.");
  const comment = snap.data() as CommunityComment;
  const role = getRole(request);
  if (comment.author_id !== uid && role !== "admin" && role !== "super_admin") {
    failedPrecondition("Not authorized to edit this comment.");
  }

  await ref.update({ content });
  return { success: true };
});

/** Function #34c. Deleting decrements the parent post's `comments_count`
 * via onCommentWrite. */
export const deleteComment = onCall(async (request) => {
  const uid = requireAuth(request);
  const { postId, commentId } = (request.data ?? {}) as { postId?: string; commentId?: string };
  if (!postId || !commentId) invalidArgument("postId and commentId are required.");

  const ref = db.collection(Collections.postComments(postId)).doc(commentId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Comment not found.");
  const comment = snap.data() as CommunityComment;
  const role = getRole(request);
  if (comment.author_id !== uid && role !== "admin" && role !== "super_admin") {
    failedPrecondition("Not authorized to delete this comment.");
  }

  await ref.delete();
  return { success: true };
});
