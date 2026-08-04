import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, getRole, invalidArgument, notFound, failedPrecondition } from "../lib/auth-helpers";
import type { CommunityPost } from "../lib/types";

function assertOwnerOrAdmin(post: CommunityPost, uid: string, role: string): void {
  if (post.author_id !== uid && role !== "admin" && role !== "super_admin") {
    failedPrecondition("Not authorized to modify this post.");
  }
}

/** Function #32a. Owner (their own content) or admin (correction —
 * distinct from moderation, which changes visibility not content). */
export const editPost = onCall(async (request) => {
  const uid = requireAuth(request);
  const { postId, content, stepCount, badgeEmoji, imageUrl } = (request.data ?? {}) as {
    postId?: string;
    content?: string;
    stepCount?: number;
    badgeEmoji?: string;
    imageUrl?: string | null;
  };
  if (!postId) invalidArgument("postId is required.");

  const ref = db.collection(Collections.communityPosts).doc(postId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Post not found.");
  const post = snap.data() as CommunityPost;
  assertOwnerOrAdmin(post, uid, getRole(request));

  const patch: Record<string, unknown> = {};
  if (content !== undefined) patch.content = content;
  if (stepCount !== undefined) patch.step_count = stepCount;
  if (badgeEmoji !== undefined) patch.badge_emoji = badgeEmoji;
  // imageUrl: null is a valid, meaningful value (removePostPhoto), so check
  // the key's presence rather than truthiness.
  if (imageUrl !== undefined) patch.image_url = imageUrl;
  await ref.update(patch);

  return { success: true };
});

/** Function #32b. Permanent, irreversible — distinct from hidePost. */
export const deletePost = onCall(async (request) => {
  const uid = requireAuth(request);
  const { postId } = (request.data ?? {}) as { postId?: string };
  if (!postId) invalidArgument("postId is required.");

  const ref = db.collection(Collections.communityPosts).doc(postId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Post not found.");
  const post = snap.data() as CommunityPost;
  assertOwnerOrAdmin(post, uid, getRole(request));

  await ref.delete();
  return { success: true };
});
