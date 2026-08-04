import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, getRole, invalidArgument, failedPrecondition } from "../lib/auth-helpers";
import { enforceRateLimit, RateLimits } from "../lib/rateLimit";
import { APP_CHECK_ENFORCED } from "../lib/appCheck";
import type { UserProfile } from "../lib/types";

const MAX_POST_LENGTH = 1000; // falls back to this if appSettings singleton is missing

/**
 * Function #31. Regular users post as themselves. Admins/super_admins may
 * pass `authorId` to post as another account (the admin panel's "post as
 * Strolla Health" official-brand-account action) — gated to elevated roles.
 */
export const createPost = onCall({ enforceAppCheck: APP_CHECK_ENFORCED }, async (request) => {
  const uid = requireAuth(request);
  await enforceRateLimit(uid, "createPost", RateLimits.createPost);
  const { content, stepCount, imageUrl, badgeEmoji, authorId } = (request.data ?? {}) as {
    content?: string;
    stepCount?: number;
    imageUrl?: string;
    badgeEmoji?: string;
    authorId?: string;
  };
  if (!content?.trim()) invalidArgument("content is required.");
  if (content!.length > MAX_POST_LENGTH) invalidArgument(`content must be ${MAX_POST_LENGTH} characters or fewer.`);

  let effectiveAuthorId = uid;
  if (authorId && authorId !== uid) {
    const role = getRole(request);
    if (role !== "admin" && role !== "super_admin") {
      failedPrecondition("Only admins can post as another account.");
    }
    effectiveAuthorId = authorId;
  } else {
    const userSnap = await db.collection(Collections.users).doc(uid).get();
    const user = userSnap.data() as UserProfile | undefined;
    if (user?.posting_banned) {
      const stillActive = !user.posting_banned_until || user.posting_banned_until.toMillis() > Date.now();
      if (stillActive) failedPrecondition("Your posting access is currently restricted.");
    }
  }

  const ref = db.collection(Collections.communityPosts).doc();
  await ref.set({
    id: ref.id,
    author_id: effectiveAuthorId,
    content,
    timestamp: FieldValue.serverTimestamp(),
    likes_count: 0,
    comments_count: 0,
    step_count: stepCount ?? null,
    badge_emoji: badgeEmoji ?? null,
    image_url: imageUrl ?? null,
    moderation: { hidden: false, hidden_by: null, hidden_reason: null, hidden_at: null },
    pinned: false,
    comments_locked: false,
  });

  return { success: true, postId: ref.id };
});
