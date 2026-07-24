"use client";

import * as React from "react";
import { toast } from "sonner";
import { Plus } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { PostsPanel } from "@/components/moderation/posts-panel";
import type { EditPostValues } from "@/components/moderation/edit-post-dialog";
import { CommentsPanel } from "@/components/moderation/comments-panel";
import { PhotosPanel } from "@/components/moderation/photos-panel";
import { CreatePostDialog, type NewPostValues } from "@/components/community/create-post-dialog";
import { logAction } from "@/lib/audit-log-store";
import { ApiError } from "@/lib/api-client";
import {
  banUserFromPosting,
  createPost as apiCreatePost,
  deleteComment as apiDeleteComment,
  deletePost as apiDeletePost,
  hidePost as apiHidePost,
  removePostPhoto,
  unhidePost as apiUnhidePost,
  updateComment as apiUpdateComment,
  updatePost,
} from "@/lib/data/api";
import { findUserById } from "@/lib/data/queries";
import type { EnrichedComment, EnrichedPost } from "@/lib/data/queries";
import type { UserProfile } from "@/lib/types";

// The official brand account posts made from this section's composer are
// attributed to — see mock-data.ts's `usr_024` seed comment for why this
// exists as a real (admin-role) account rather than a synthetic label.
const STROLLA_HEALTH_ACCOUNT_ID = "usr_024";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

export function CommunityView({
  posts: initialPosts,
  comments: initialComments,
  users,
}: {
  posts: EnrichedPost[];
  comments: EnrichedComment[];
  users: UserProfile[];
}) {
  const [posts, setPosts] = React.useState(initialPosts);
  const [comments, setComments] = React.useState(initialComments);
  const [createOpen, setCreateOpen] = React.useState(false);

  async function createPost(values: NewPostValues) {
    try {
      const created = await apiCreatePost({ author_id: STROLLA_HEALTH_ACCOUNT_ID, content: values.content, image_url: values.imageUrl });
      setPosts((prev) => [{ ...created, author: findUserById(users, STROLLA_HEALTH_ACCOUNT_ID) }, ...prev]);
      toast.success("Post published as Strolla Health");
      logAction("Published post as Strolla Health", created.id);
      setCreateOpen(false);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't publish this post"));
    }
  }

  async function hidePost(postId: string, reason: string) {
    try {
      await apiHidePost(postId, reason);
      setPosts((prev) =>
        prev.map((p) =>
          p.id === postId
            ? { ...p, moderation: { hidden: true, hidden_by: null, hidden_reason: reason, hidden_at: new Date().toISOString() } }
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
        prev.map((p) => (p.id === postId ? { ...p, moderation: { hidden: false, hidden_by: null, hidden_reason: null, hidden_at: null } } : p))
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
        setPosts((prev) => prev.map((p) => (p.id === removed.post_id ? { ...p, comments_count: Math.max(0, p.comments_count - 1) } : p)));
      }
      toast.success("Comment deleted");
      logAction("Deleted comment", commentId);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't delete this comment"));
    }
  }

  return (
    <Tabs defaultValue="posts">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <TabsList>
          <TabsTrigger value="posts">Posts ({posts.length})</TabsTrigger>
          <TabsTrigger value="comments">Comments ({comments.length})</TabsTrigger>
          <TabsTrigger value="photos">Photos ({posts.filter((p) => p.image_url).length})</TabsTrigger>
        </TabsList>
        <Button size="sm" onClick={() => setCreateOpen(true)}>
          <Plus size={14} /> Post as Strolla Health
        </Button>
      </div>
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

      <CreatePostDialog open={createOpen} onOpenChange={setCreateOpen} onConfirm={createPost} />
    </Tabs>
  );
}
