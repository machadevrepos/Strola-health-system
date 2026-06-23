"use client";

import * as React from "react";
import { toast } from "sonner";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { PostsPanel } from "@/components/moderation/posts-panel";
import { ReportsPanel } from "@/components/moderation/reports-panel";
import { logAction } from "@/lib/audit-log-store";
import { useAuth } from "@/lib/auth-context";
import { ApiError } from "@/lib/api-client";
import {
  deletePost as apiDeletePost,
  hidePost as apiHidePost,
  removePostPhoto,
  resolveReport as apiResolveReport,
  unhidePost as apiUnhidePost,
  updatePost,
} from "@/lib/data/api";
import type { EnrichedPost, EnrichedReport } from "@/lib/data/queries";
import type { ReportStatus } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

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

  async function editPost(postId: string, content: string) {
    try {
      await updatePost(postId, { content });
      setPosts((prev) => prev.map((p) => (p.id === postId ? { ...p, content } : p)));
      toast.success("Post updated");
      logAction("Edited post content", postId);
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

  return (
    <Tabs defaultValue="reports">
      <TabsList>
        <TabsTrigger value="reports">Reports {openReportsCount > 0 && `(${openReportsCount})`}</TabsTrigger>
        <TabsTrigger value="posts">All posts ({posts.length})</TabsTrigger>
      </TabsList>
      <TabsContent value="reports" className="mt-4">
        <ReportsPanel reports={reports} posts={posts} onResolve={resolveReport} />
      </TabsContent>
      <TabsContent value="posts" className="mt-4">
        <PostsPanel
          posts={posts}
          onHide={hidePost}
          onUnhide={unhidePost}
          onRemovePhoto={removePhoto}
          onEdit={editPost}
          onDelete={deletePost}
        />
      </TabsContent>
    </Tabs>
  );
}
