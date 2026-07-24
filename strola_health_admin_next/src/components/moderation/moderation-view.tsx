"use client";

import * as React from "react";
import { toast } from "sonner";
import { ReportsPanel } from "@/components/moderation/reports-panel";
import { logAction } from "@/lib/audit-log-store";
import { useAuth } from "@/lib/auth-context";
import { ApiError } from "@/lib/api-client";
import {
  banUser as apiBanUser,
  banUserFromPosting,
  deletePost as apiDeletePost,
  deleteUser as apiDeleteUser,
  hidePost as apiHidePost,
  resolveReport as apiResolveReport,
  sendUserEmail,
  warnUser as apiWarnUser,
} from "@/lib/data/api";
import type { EnrichedPost, EnrichedReport } from "@/lib/data/queries";
import type { ModerationAction, ReportStatus } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

// Canned messages sent to a user whenever an action is taken against their
// content or account — the client's own example ("Your post was removed
// because it violated our Community Guidelines.") set the tone for these.
const GUIDELINES_NOTICE: Record<ModerationAction, { subject: string; body: (detail?: string) => string }> = {
  post_removed: {
    subject: "Your post was removed",
    body: () => "Your post was removed because it violated our Community Guidelines.",
  },
  warned: {
    subject: "You've received a warning",
    body: (detail) => `You've received a warning for violating our Community Guidelines.${detail ? ` Reason: ${detail}` : ""}`,
  },
  muted: {
    subject: "Your posting privileges have been paused",
    body: (detail) => `Your ability to post and comment has been paused ${detail} for violating our Community Guidelines.`,
  },
  banned: {
    subject: "Your account has been suspended",
    body: () => "Your account has been suspended for violating our Community Guidelines.",
  },
  account_deleted: {
    subject: "Your account has been deleted",
    body: () => "Your Strolla Health account has been deleted for violating our Community Guidelines.",
  },
  posts_deleted: {
    subject: "Your posts have been removed",
    body: () => "All of your posts have been removed for violating our Community Guidelines.",
  },
};

export function ModerationView({
  posts: initialPosts,
  reports: initialReports,
}: {
  posts: EnrichedPost[];
  reports: EnrichedReport[];
}) {
  const { user } = useAuth();
  const adminId = user?.uid ?? "";
  const [posts, setPosts] = React.useState(initialPosts);
  const [reports, setReports] = React.useState(initialReports);

  async function notifyUser(userId: string, action: ModerationAction, detail?: string) {
    const notice = GUIDELINES_NOTICE[action];
    try {
      await sendUserEmail(userId, { subject: notice.subject, body: notice.body(detail) });
    } catch {
      // Best-effort — a failed notification shouldn't block the moderation action itself.
    }
  }

  function markResolved(reportIds: string[], status: ReportStatus, note: string, actionTaken: ModerationAction | null) {
    setReports((prev) =>
      prev.map((r) =>
        reportIds.includes(r.id)
          ? { ...r, status, action_taken: actionTaken, resolved_by: adminId, resolved_at: new Date().toISOString(), resolution_note: note }
          : r
      )
    );
  }

  async function dismiss(reportIds: string[], note: string) {
    try {
      await Promise.all(reportIds.map((id) => apiResolveReport(id, "dismissed", note)));
      markResolved(reportIds, "dismissed", note, null);
      toast.success(reportIds.length === 1 ? "Report dismissed" : `${reportIds.length} reports dismissed`);
      logAction("Dismissed report", note);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't dismiss this report"));
    }
  }

  async function removePost(reportIds: string[], postId: string) {
    const post = posts.find((p) => p.id === postId);
    try {
      await apiHidePost(postId, "Removed via report");
      setPosts((prev) =>
        prev.map((p) =>
          p.id === postId
            ? { ...p, moderation: { hidden: true, hidden_by: adminId, hidden_reason: "Removed via report", hidden_at: new Date().toISOString() } }
            : p
        )
      );
      const note = "Post removed";
      await Promise.all(reportIds.map((id) => apiResolveReport(id, "resolved", note, "post_removed")));
      markResolved(reportIds, "resolved", note, "post_removed");
      if (post) await notifyUser(post.author_id, "post_removed");
      toast.success("Post removed and the author notified");
      logAction("Removed reported post", postId);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't remove this post"));
    }
  }

  async function warnUser(reportIds: string[], userId: string, reason: string) {
    try {
      await apiWarnUser(userId, reason);
      const note = `Warned user — ${reason}`;
      await Promise.all(reportIds.map((id) => apiResolveReport(id, "resolved", note, "warned")));
      markResolved(reportIds, "resolved", note, "warned");
      await notifyUser(userId, "warned", reason);
      toast.success("Warning sent");
      logAction("Warned user from a report", `${userId} — ${reason}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't send this warning"));
    }
  }

  async function muteUser(reportIds: string[], userId: string, hours: number, reason: string) {
    const durationLabel = hours === 24 ? "24 hours" : "7 days";
    const until = new Date(Date.now() + hours * 3_600_000).toISOString();
    try {
      await banUserFromPosting(userId, reason, until);
      const note = `Muted ${durationLabel} — ${reason}`;
      await Promise.all(reportIds.map((id) => apiResolveReport(id, "resolved", note, "muted")));
      markResolved(reportIds, "resolved", note, "muted");
      await notifyUser(userId, "muted", `for ${durationLabel}`);
      toast.success(`Muted for ${durationLabel}`);
      logAction(`Muted user for ${durationLabel}`, `${userId} — ${reason}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't mute this user"));
    }
  }

  async function banUser(reportIds: string[], userId: string, reason: string) {
    try {
      await apiBanUser(userId, reason);
      const note = `Suspended account — ${reason}`;
      await Promise.all(reportIds.map((id) => apiResolveReport(id, "resolved", note, "banned")));
      markResolved(reportIds, "resolved", note, "banned");
      await notifyUser(userId, "banned");
      toast.success("Account suspended");
      logAction("Suspended account from a report", `${userId} — ${reason}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't suspend this account"));
    }
  }

  async function deleteAccount(reportIds: string[], userId: string) {
    try {
      await notifyUser(userId, "account_deleted");
      await apiDeleteUser(userId);
      const note = "Account deleted";
      await Promise.all(reportIds.map((id) => apiResolveReport(id, "resolved", note, "account_deleted")));
      markResolved(reportIds, "resolved", note, "account_deleted");
      toast.success("Account deleted");
      logAction("Deleted account from a report", userId);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't delete this account"));
    }
  }

  async function deleteAllPosts(reportIds: string[], userId: string) {
    const targets = posts.filter((p) => p.author_id === userId);
    try {
      const results = await Promise.allSettled(targets.map((p) => apiDeletePost(p.id)));
      const removedIds = new Set(targets.filter((_, i) => results[i].status === "fulfilled").map((p) => p.id));
      setPosts((prev) => prev.filter((p) => !removedIds.has(p.id)));
      const note = `Removed ${removedIds.size} post${removedIds.size === 1 ? "" : "s"}`;
      await Promise.all(reportIds.map((id) => apiResolveReport(id, "resolved", note, "posts_deleted")));
      markResolved(reportIds, "resolved", note, "posts_deleted");
      await notifyUser(userId, "posts_deleted");
      toast.success(`Deleted ${removedIds.size} post${removedIds.size === 1 ? "" : "s"}`);
      logAction("Deleted all posts from a report", userId);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't delete all posts"));
    }
  }

  return (
    <ReportsPanel
      reports={reports}
      posts={posts}
      onDismiss={dismiss}
      onRemovePost={removePost}
      onWarnUser={warnUser}
      onMuteUser={muteUser}
      onBanUser={banUser}
      onDeleteAccount={deleteAccount}
      onDeleteAllPosts={deleteAllPosts}
    />
  );
}
