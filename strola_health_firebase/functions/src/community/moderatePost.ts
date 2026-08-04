import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/** Function #32c/d/e. Admin-only moderation actions on a post: hide/unhide,
 * pin/unpin, lock/unlock comments — each independent of the others. */
export const hidePost = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { postId, hidden, reason } = (request.data ?? {}) as {
    postId?: string;
    hidden?: boolean;
    reason?: string;
  };
  if (!postId || hidden === undefined) invalidArgument("postId and hidden are required.");

  const ref = db.collection(Collections.communityPosts).doc(postId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Post not found.");

  await ref.update({
    moderation: hidden
      ? { hidden: true, hidden_by: callerUid, hidden_reason: reason ?? null, hidden_at: FieldValue.serverTimestamp() }
      : { hidden: false, hidden_by: null, hidden_reason: null, hidden_at: null },
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: hidden ? "hide_post" : "unhide_post",
    target: postId,
    metadata: { reason: reason ?? null },
  });
  return { success: true };
});

export const pinPost = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { postId, pinned } = (request.data ?? {}) as { postId?: string; pinned?: boolean };
  if (!postId || pinned === undefined) invalidArgument("postId and pinned are required.");

  const ref = db.collection(Collections.communityPosts).doc(postId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Post not found.");

  await ref.update({ pinned });
  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: pinned ? "pin_post" : "unpin_post",
    target: postId,
  });
  return { success: true };
});

export const lockComments = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { postId, locked } = (request.data ?? {}) as { postId?: string; locked?: boolean };
  if (!postId || locked === undefined) invalidArgument("postId and locked are required.");

  const ref = db.collection(Collections.communityPosts).doc(postId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Post not found.");

  await ref.update({ comments_locked: locked });
  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: locked ? "lock_comments" : "unlock_comments",
    target: postId,
  });
  return { success: true };
});
