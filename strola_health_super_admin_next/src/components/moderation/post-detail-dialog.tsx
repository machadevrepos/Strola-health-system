"use client";

import * as React from "react";
import Link from "next/link";
import { Heart, ChatCircle, PencilSimple, Trash, CircleNotch } from "@phosphor-icons/react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";
import { CommunityAuthorBadge } from "@/components/shell/status-badges";
import { fetchPostLikes } from "@/lib/data/api";
import { communityDisplayName, findUserById, userDisplayName } from "@/lib/data/queries";
import type { EnrichedComment, EnrichedPost } from "@/lib/data/queries";
import { formatRelative, initials } from "@/lib/format";
import type { PostLike, UserProfile } from "@/lib/types";

export function PostDetailDialog({
  post,
  initialTab = "comments",
  comments,
  users,
  onOpenChange,
  onReply,
  onEditComment,
  onDeleteComment,
}: {
  post: EnrichedPost | null;
  initialTab?: "comments" | "likes";
  comments: EnrichedComment[];
  users: UserProfile[];
  onOpenChange: (open: boolean) => void;
  onReply: (postId: string, content: string) => void | Promise<void>;
  onEditComment: (commentId: string, content: string) => void | Promise<void>;
  onDeleteComment: (commentId: string) => void | Promise<void>;
}) {
  const [likes, setLikes] = React.useState<PostLike[]>([]);
  const [likesLoading, setLikesLoading] = React.useState(false);
  const [reply, setReply] = React.useState("");
  const [replying, setReplying] = React.useState(false);
  const [deleteTarget, setDeleteTarget] = React.useState<EnrichedComment | null>(null);
  const [deleting, setDeleting] = React.useState(false);

  const postId = post?.id ?? null;
  React.useEffect(() => {
    if (!postId) return;
    let cancelled = false;
    setLikesLoading(true);
    fetchPostLikes(postId)
      .then((result) => {
        if (!cancelled) setLikes(result);
      })
      .finally(() => {
        if (!cancelled) setLikesLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [postId]);

  React.useEffect(() => {
    if (!post) setReply("");
  }, [post]);

  const postComments = React.useMemo(
    () => comments.filter((c) => c.post_id === postId).sort((a, b) => +new Date(a.timestamp) - +new Date(b.timestamp)),
    [comments, postId]
  );

  async function handleReply() {
    if (!post || !reply.trim()) return;
    setReplying(true);
    try {
      await onReply(post.id, reply.trim());
      setReply("");
    } finally {
      setReplying(false);
    }
  }

  async function confirmDelete() {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await onDeleteComment(deleteTarget.id);
    } finally {
      setDeleting(false);
      setDeleteTarget(null);
    }
  }

  return (
    <>
      <Dialog open={!!post} onOpenChange={onOpenChange}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>{post ? userDisplayName(post.author) : ""}&apos;s post</DialogTitle>
            <DialogDescription>Who liked this, who commented, and reply as an admin.</DialogDescription>
          </DialogHeader>

          {post && (
            <Tabs defaultValue={initialTab}>
              <TabsList>
                <TabsTrigger value="comments">
                  <ChatCircle size={14} /> Comments ({postComments.length})
                </TabsTrigger>
                <TabsTrigger value="likes">
                  <Heart size={14} /> Likes ({post.likes_count})
                </TabsTrigger>
              </TabsList>

              <TabsContent value="comments" className="mt-3 space-y-3">
                <div className="max-h-80 space-y-2 overflow-y-auto">
                  {postComments.length === 0 && (
                    <p className="py-6 text-center text-sm text-muted-foreground">No comments on this post yet.</p>
                  )}
                  {postComments.map((c) => (
                    <CommentRow
                      key={c.id}
                      comment={c}
                      onEdit={onEditComment}
                      onDeleteClick={() => setDeleteTarget(c)}
                    />
                  ))}
                </div>
                <div className="flex gap-2 border-t border-border pt-3">
                  <Textarea
                    value={reply}
                    onChange={(e) => setReply(e.target.value)}
                    placeholder="Reply as an admin…"
                    rows={2}
                    className="flex-1"
                  />
                  <Button
                    size="sm"
                    className="self-end"
                    disabled={!reply.trim() || replying}
                    onClick={handleReply}
                  >
                    {replying && <CircleNotch size={14} className="animate-spin" />}
                    Reply
                  </Button>
                </div>
              </TabsContent>

              <TabsContent value="likes" className="mt-3">
                <div className="max-h-80 space-y-1 overflow-y-auto">
                  {likesLoading && <p className="py-6 text-center text-sm text-muted-foreground">Loading…</p>}
                  {!likesLoading && likes.length === 0 && (
                    <p className="py-6 text-center text-sm text-muted-foreground">No likes on this post yet.</p>
                  )}
                  {!likesLoading &&
                    likes.map((like) => {
                      const user = findUserById(users, like.user_id);
                      return (
                        <Link
                          key={like.user_id}
                          href={`/users/${like.user_id}`}
                          className="flex items-center gap-2 rounded-md p-2 transition-colors hover:bg-muted"
                        >
                          <Avatar className="size-7 shrink-0">
                            {user?.photo_url && <AvatarImage src={user.photo_url} alt={userDisplayName(user)} />}
                            <AvatarFallback className="text-xs">{initials(userDisplayName(user))}</AvatarFallback>
                          </Avatar>
                          <span className="text-sm font-medium text-foreground">{userDisplayName(user)}</span>
                        </Link>
                      );
                    })}
                </div>
              </TabsContent>
            </Tabs>
          )}
        </DialogContent>
      </Dialog>

      <AlertDialog open={!!deleteTarget} onOpenChange={(open) => !open && setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete this comment?</AlertDialogTitle>
            <AlertDialogDescription>This can&apos;t be undone.</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleting}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} disabled={deleting} className="bg-destructive text-white hover:bg-destructive/90">
              {deleting && <CircleNotch size={14} className="animate-spin" />}
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}

function CommentRow({
  comment: c,
  onEdit,
  onDeleteClick,
}: {
  comment: EnrichedComment;
  onEdit: (commentId: string, content: string) => void | Promise<void>;
  onDeleteClick: () => void;
}) {
  const [editing, setEditing] = React.useState(false);
  const [content, setContent] = React.useState(c.content);
  const [saving, setSaving] = React.useState(false);

  React.useEffect(() => {
    if (!editing) setContent(c.content);
  }, [c.content, editing]);

  async function handleSave() {
    setSaving(true);
    try {
      await onEdit(c.id, content);
      setEditing(false);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="flex gap-2 rounded-lg border border-border p-2.5">
      <Avatar className="size-7 shrink-0">
        {c.author?.photo_url && <AvatarImage src={c.author.photo_url} alt={communityDisplayName(c.author)} />}
        <AvatarFallback className="text-xs">{initials(communityDisplayName(c.author))}</AvatarFallback>
      </Avatar>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <Link href={`/users/${c.author_id}`} className="flex items-center gap-1 text-xs font-medium text-foreground hover:underline">
            {communityDisplayName(c.author)}
            <CommunityAuthorBadge role={c.author?.role} />
          </Link>
          <span className="text-xs text-muted-foreground">{formatRelative(c.timestamp)}</span>
          {c.hidden && <Badge variant="destructive">Hidden</Badge>}
        </div>

        {editing ? (
          <div className="mt-1.5 space-y-2">
            <Textarea value={content} onChange={(e) => setContent(e.target.value)} rows={2} autoFocus />
            <div className="flex justify-end gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  setContent(c.content);
                  setEditing(false);
                }}
                disabled={saving}
              >
                Cancel
              </Button>
              <Button size="sm" onClick={handleSave} disabled={content.trim().length === 0 || saving}>
                {saving ? <CircleNotch size={14} className="animate-spin" /> : null}
                Save
              </Button>
            </div>
          </div>
        ) : (
          <p className="mt-1 text-sm text-foreground">{c.content}</p>
        )}
      </div>
      {!editing && (
        <div className="flex h-fit shrink-0 gap-1">
          <Button variant="ghost" size="icon-sm" aria-label="Edit comment" onClick={() => setEditing(true)}>
            <PencilSimple size={14} />
          </Button>
          <Button variant="ghost" size="icon-sm" aria-label="Delete comment" onClick={onDeleteClick}>
            <Trash size={14} />
          </Button>
        </div>
      )}
    </div>
  );
}
