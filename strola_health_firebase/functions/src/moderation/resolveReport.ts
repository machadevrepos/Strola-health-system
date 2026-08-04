import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, authAdmin } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import { queueEmail } from "../lib/mailer";
import type { CommunityPost, ReportActionTaken, ReportTargetType, UserProfile } from "../lib/types";

type ResolveAction =
  | "dismiss"
  | "remove_post"
  | "warn"
  | "mute_24h"
  | "mute_7d"
  | "ban"
  | "delete_account"
  | "delete_all_posts";

const ACTION_TAKEN: Record<ResolveAction, ReportActionTaken> = {
  dismiss: null,
  remove_post: "post_removed",
  warn: "warned",
  mute_24h: "muted",
  mute_7d: "muted",
  ban: "banned",
  delete_account: "account_deleted",
  delete_all_posts: "posts_deleted",
};

const GUIDELINES_NOTICE: Partial<Record<ResolveAction, { subject: string; html: string }>> = {
  remove_post: {
    subject: "A post you made was removed",
    html: "<p>A post you made was removed for not following our community guidelines.</p>",
  },
  warn: {
    subject: "Community guidelines reminder",
    html: "<p>We received a report about your recent activity. Please review our community guidelines — no other action has been taken.</p>",
  },
  mute_24h: {
    subject: "Your posting access has been temporarily paused",
    html: "<p>Your ability to post and comment has been paused for 24 hours following a community guidelines report.</p>",
  },
  mute_7d: {
    subject: "Your posting access has been temporarily paused",
    html: "<p>Your ability to post and comment has been paused for 7 days following a community guidelines report.</p>",
  },
  ban: {
    subject: "Your account has been suspended",
    html: "<p>Your Strolla Health account has been suspended following a community guidelines report.</p>",
  },
  delete_account: {
    subject: "Your account has been deleted",
    html: "<p>Your Strolla Health account has been deleted following a community guidelines report.</p>",
  },
  delete_all_posts: {
    subject: "Your posts have been removed",
    html: "<p>All of your community posts have been removed following a community guidelines report.</p>",
  },
};

/**
 * Function #36. The single compound atomic moderation action the audit
 * flagged as the most important gap to fix — mutate target, resolve every
 * open report on it, and notify the affected user, all in one call instead
 * of the mock's client-orchestrated `Promise.all`.
 */
export const resolveReport = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { reportIds, action, note, targetType, targetId } = (request.data ?? {}) as {
    reportIds?: string[];
    action?: ResolveAction;
    note?: string;
    targetType?: ReportTargetType;
    targetId?: string;
  };
  if (!reportIds?.length || !action || !targetType || !targetId) {
    invalidArgument("reportIds, action, targetType, and targetId are required.");
  }
  if (!(action! in ACTION_TAKEN)) invalidArgument("Unknown action.");

  let targetUserId = targetId!;
  if (targetType === "post") {
    const postSnap = await db.collection(Collections.communityPosts).doc(targetId!).get();
    if (!postSnap.exists) notFound("Post not found.");
    targetUserId = (postSnap.data() as CommunityPost).author_id;
  }

  switch (action) {
    case "remove_post":
      await db.collection(Collections.communityPosts).doc(targetId!).update({
        moderation: {
          hidden: true,
          hidden_by: callerUid,
          hidden_reason: "Removed via report",
          hidden_at: FieldValue.serverTimestamp(),
        },
      });
      break;

    case "mute_24h":
    case "mute_7d": {
      const hours = action === "mute_24h" ? 24 : 24 * 7;
      await db
        .collection(Collections.users)
        .doc(targetUserId)
        .update({
          posting_banned: true,
          posting_ban_reason: "Reported content",
          posting_banned_until: new Date(Date.now() + hours * 3600 * 1000),
        });
      break;
    }

    case "ban":
      await db.collection(Collections.users).doc(targetUserId).update({
        banned: true,
        ban_reason: "Reported content",
      });
      await authAdmin.revokeRefreshTokens(targetUserId);
      break;

    case "delete_account":
      await db.collection(Collections.users).doc(targetUserId).update({
        deleted: true,
        deleted_at: FieldValue.serverTimestamp(),
        name: "Deleted User",
        username: `deleted_${targetUserId}`,
        email: null,
        bio: null,
        photo_url: null,
        location: null,
        date_of_birth: null,
      });
      await authAdmin.deleteUser(targetUserId).catch(() => undefined);
      break;

    case "delete_all_posts": {
      const postsSnap = await db
        .collection(Collections.communityPosts)
        .where("author_id", "==", targetUserId)
        .get();
      if (!postsSnap.empty) {
        const deleteBatch = db.batch();
        postsSnap.forEach((doc) => deleteBatch.delete(doc.ref));
        await deleteBatch.commit();
      }
      break;
    }

    case "warn":
    case "dismiss":
      break;
  }

  const resolveBatch = db.batch();
  for (const id of reportIds!) {
    resolveBatch.update(db.collection(Collections.reports).doc(id), {
      status: action === "dismiss" ? "dismissed" : "resolved",
      action_taken: ACTION_TAKEN[action!],
      resolved_by: callerUid,
      resolved_at: FieldValue.serverTimestamp(),
      resolution_note: note ?? null,
    });
  }
  await resolveBatch.commit();

  const notice = GUIDELINES_NOTICE[action!];
  if (notice) {
    const userSnap = await db.collection(Collections.users).doc(targetUserId).get();
    const email = (userSnap.data() as UserProfile | undefined)?.email;
    if (email) {
      await queueEmail({ to: email, subject: notice.subject, html: notice.html }).catch(() => undefined);
    }
  }

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: `resolve_report_${action}`,
    target: targetId,
    metadata: { report_ids: reportIds, target_type: targetType, target_user_id: targetUserId },
  });

  return { success: true };
});
