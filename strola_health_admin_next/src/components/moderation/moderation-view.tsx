"use client";

import * as React from "react";
import { toast } from "sonner";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { PostsPanel } from "@/components/moderation/posts-panel";
import type { EditPostValues } from "@/components/moderation/edit-post-dialog";
import { ReportsPanel } from "@/components/moderation/reports-panel";
import { CommentsPanel } from "@/components/moderation/comments-panel";
import { PhotosPanel } from "@/components/moderation/photos-panel";
import { logAction } from "@/lib/audit-log-store";
import { useAuth } from "@/lib/auth-context";
import { ApiError } from "@/lib/api-client";
import {
  banUser as apiBanUser,
  banUserFromPosting,
  deleteComment as apiDeleteComment,
  deletePost as apiDeletePost,
  hidePost as apiHidePost,
  removePostPhoto,
  resolveReport as apiResolveReport,
  unhidePost as apiUnhidePost,
  updateComment as apiUpdateComment,
  updatePost,
  warnUser as apiWarnUser,
} from "@/lib/data/api";
import type { EnrichedComment, EnrichedPost, EnrichedReport } from "@/lib/data/queries";
import type { ReportStatus, UserProfile } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

export function ModerationView({
  posts: initialPosts,
  reports: initialReports,
  comments: initialComments,
  users,
}: {
  posts: EnrichedPost[];
  reports: EnrichedReport[];
  comments: EnrichedComment[];
  users: UserProfile[];
}) {
  const { user } = useAuth();
  const adminId = user?.uid ?? "";
  const [posts, setPosts] = React.useState(initialPosts);
  const [reports, setReports] = React.useState(initialReports);
  const [comments, setComments] = React.useState(initialComments);

  const openReportsCount = reports.filter((r) => r.status === "open").length;

  async function hidePost(postId: string, reason: string) {
    try {
      await apiHidePost(postId, reason);
      setPosts((prev) =>
        prev.map((p) =>
          p.id === postId
            ? { ...p, moderation: { hidden: true, hidden_by: adminId, hidden_reason: reason, hidden_at: new Date().toISOString() } }
            : p
        )
      );
      toast.success("Post hidden");
      logAction("Hid post", reason);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't hide post"));
    }
  }

  async function unhidePost(postId: string) {
    try {
      await apiUnhidePost(postId);
      setPosts((prev) =>
        prev.map((p) =>
          p.id === postId ? { ...p, moderation: { hidden: false, hidden_by: null, hidden_reason: null, hidden_at: null } } : p
        )
      );
      toast.success("Post restored");
      logAction("Restored post", postId);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't restore post"));
    }
  }

  async function removePhoto(postId: string) {
    try {
      await removePostPhoto(postId);
      setPosts((prev) => prev.map((p) => (p.id === postId ? { ...p, image_url: null } : p)));
      toast.success("Photo removed");
      logAction("Removed photo from post", postId);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't remove photo"));
    }
  }

  async function editPost(postId: string, values: EditPostValues) {
    try {
      await updatePost(postId, values);
      setPosts((prev) => prev.map((p) => (p.id === postId ? { ...p, ...values } : p)));
      toast.success("Post updated");
      logAction("Edited post", postId);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't update post"));
    }
  }

  async function deletePost(postId: string) {
    try {
      await apiDeletePost(postId);
      setPosts((prev) => prev.filter((p) => p.id !== postId));
      toast.success("Post deleted");
      logAction("Deleted post", postId);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't delete post"));
    }
  }

  async function togglePin(postId: string, pinned: boolean) {
    try {
      await updatePost(postId, { pinned });
      setPosts((prev) => prev.map((p) => (p.id === postId ? { ...p, pinned } : p)));
      toast.success(pinned ? "Post pinned" : "Post unpinned");
      logAction(pinned ? "Pinned post" : "Unpinned post", postId);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't update this post"));
    }
  }

  async function toggleCommentsLocked(postId: string, locked: boolean) {
    try {
      await updatePost(postId, { comments_locked: locked });
      setPosts((prev) => prev.map((p) => (p.id === postId ? { ...p, comments_locked: locked } : p)));
      toast.success(locked ? "Comments locked" : "Comments unlocked");
      logAction(locked ? "Locked comments" : "Unlocked comments", postId);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't update this post"));
    }
  }

  async function banFromPosting(userId: string, reason: string) {
    try {
      await banUserFromPosting(userId, reason);
      toast.success("User banned from posting");
      logAction("Banned user from posting", `${userId} — ${reason}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't ban this user from posting"));
    }
  }

  async function editComment(commentId: string, content: string) {
    try {
      await apiUpdateComment(commentId, content);
      setComments((prev) => prev.map((c) => (c.id === commentId ? { ...c, content } : c)));
      toast.success("Comment updated");
      logAction("Edited comment", commentId);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't update this comment"));
    }
  }

  async function deleteComment(commentId: string) {
    const removed = comments.find((c) => c.id === commentId);
    try {
      await apiDeleteComment(commentId);
      setComments((prev) => prev.filter((c) => c.id !== commentId));
      if (removed) {
        setPosts((prev) =>
          prev.map((p) => (p.id === removed.post_id ? { ...p, comments_count: Math.max(0, p.comments_count - 1) } : p))
        );
      }
      toast.success("Comment deleted");
      logAction("Deleted comment", commentId);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't delete this comment"));
    }
  }

  async function resolveReport(reportId: string, status: ReportStatus, note: string) {
    try {
      await apiResolveReport(reportId, status, note);
      setReports((prev) =>
        prev.map((r) =>
          r.id === reportId
            ? { ...r, status, resolved_by: adminId, resolved_at: new Date().toISOString(), resolution_note: note }
            : r
        )
      );
      toast.success(status === "resolved" ? "Report resolved" : "Report dismissed");
      logAction(status === "resolved" ? "Resolved report" : "Dismissed report", note);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't resolve report"));
    }
  }

  // "Remove" from a report: hides the reported post (same effect as the
  // Posts tab's own Hide action) and closes out the report in one step,
  // rather than making the admin do both separately.
  async function removeReportedContent(reportId: string) {
    const report = reports.find((r) => r.id === reportId);
    if (!report || report.target_type !== "post") return;
    try {
      await apiHidePost(report.target_id, report.reason);
      setPosts((prev) =>
        prev.map((p) =>
          p.id === report.target_id
            ? { ...p, moderation: { hidden: true, hidden_by: adminId, hidden_reason: report.reason, hidden_at: new Date().toISOString() } }
            : p
        )
      );
      await resolveReport(reportId, "resolved", `Removed reported post — ${report.reason}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't remove this post"));
    }
  }

  async function warnReportedUser(reportId: string, userId: string, reason: string) {
    try {
      await apiWarnUser(userId, reason);
      await resolveReport(reportId, "resolved", `Warned user — ${reason}`);
      toast.success("Warning sent");
      logAction("Warned user from a report", `${userId} — ${reason}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't send this warning"));
    }
  }

  async function suspendReportedUser(reportId: string, userId: string, reason: string) {
    try {
      await apiBanUser(userId, reason);
      await resolveReport(reportId, "resolved", `Suspended account — ${reason}`);
      toast.success("Account suspended");
      logAction("Suspended account from a report", `${userId} — ${reason}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't suspend this account"));
    }
  }

  return (
    <Tabs defaultValue="reports">
      <TabsList>
        <TabsTrigger value="reports">Reports {openReportsCount > 0 && `(${openReportsCount})`}</TabsTrigger>
        <TabsTrigger value="posts">Posts ({posts.length})</TabsTrigger>
        <TabsTrigger value="comments">Comments ({comments.length})</TabsTrigger>
        <TabsTrigger value="photos">Photos ({posts.filter((p) => p.image_url).length})</TabsTrigger>
      </TabsList>
      <TabsContent value="reports" className="mt-4">
        <ReportsPanel
          reports={reports}
          posts={posts}
          users={users}
          onResolve={resolveReport}
          onRemove={removeReportedContent}
          onWarnUser={warnReportedUser}
          onSuspendUser={suspendReportedUser}
        />
      </TabsContent>
      <TabsContent value="posts" className="mt-4">
        <PostsPanel
          posts={posts}
          onHide={hidePost}
          onUnhide={unhidePost}
          onRemovePhoto={removePhoto}
          onEdit={editPost}
          onDelete={deletePost}
          onTogglePin={togglePin}
          onToggleCommentsLocked={toggleCommentsLocked}
          onBanFromPosting={banFromPosting}
        />
      </TabsContent>
      <TabsContent value="comments" className="mt-4">
        <CommentsPanel comments={comments} onEdit={editComment} onDelete={deleteComment} />
      </TabsContent>
      <TabsContent value="photos" className="mt-4">
        <PhotosPanel posts={posts} onRemovePhoto={removePhoto} />
      </TabsContent>
    </Tabs>
  );
}
