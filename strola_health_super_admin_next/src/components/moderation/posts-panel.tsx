"use client";

import * as React from "react";
import Image from "next/image";
import Link from "next/link";
import {
  DotsThree,
  EyeSlash,
  Eye,
  ImageBroken,
  PencilSimple,
  Trash,
  Heart,
  ChatCircle,
  MagnifyingGlass,
  CircleNotch,
} from "@phosphor-icons/react";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
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
import { HidePostDialog } from "@/components/moderation/hide-post-dialog";
import { EditPostDialog } from "@/components/moderation/edit-post-dialog";
import { userDisplayName } from "@/lib/data/queries";
import { formatRelative, initials } from "@/lib/format";
import type { EnrichedPost } from "@/lib/data/queries";

type Filter = "all" | "visible" | "hidden";

const FILTER_LABEL: Record<Filter, string> = {
  all: "All posts",
  visible: "Visible",
  hidden: "Hidden",
};

const PAGE_SIZE = 8;

export function PostsPanel({
  posts,
  onHide,
  onUnhide,
  onRemovePhoto,
  onEdit,
  onDelete,
}: {
  posts: EnrichedPost[];
  onHide: (postId: string, reason: string) => void | Promise<void>;
  onUnhide: (postId: string) => void;
  onRemovePhoto: (postId: string) => void;
  onEdit: (postId: string, content: string) => void | Promise<void>;
  onDelete: (postId: string) => void | Promise<void>;
}) {
  const [filter, setFilter] = React.useState<Filter>("all");
  const [query, setQuery] = React.useState("");
  const [hideTarget, setHideTarget] = React.useState<EnrichedPost | null>(null);
  const [editTarget, setEditTarget] = React.useState<EnrichedPost | null>(null);
  const [deleteTarget, setDeleteTarget] = React.useState<EnrichedPost | null>(null);
  const [deleting, setDeleting] = React.useState(false);
  const [visibleCount, setVisibleCount] = React.useState(PAGE_SIZE);

  async function confirmDelete() {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await onDelete(deleteTarget.id);
    } finally {
      setDeleting(false);
      setDeleteTarget(null);
    }
  }

  const filtered = posts.filter((p) => {
    if (filter === "visible" && p.moderation.hidden) return false;
    if (filter === "hidden" && !p.moderation.hidden) return false;
    if (query && !`${p.content} ${userDisplayName(p.author)}`.toLowerCase().includes(query.toLowerCase())) return false;
    return true;
  });
  const visible = filtered.slice(0, visibleCount);

  React.useEffect(() => {
    setVisibleCount(PAGE_SIZE);
  }, [filter, query]);

  return (
    <div>
      <div className="mb-3 flex flex-wrap items-center gap-2">
        <div className="relative flex-1 min-w-[220px] max-w-sm">
          <MagnifyingGlass size={14} className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
          <Input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search posts or authors" className="pl-8" />
        </div>
        <Select value={filter} onValueChange={(v) => v && setFilter(v as Filter)}>
          <SelectTrigger className="w-36"><SelectValue>{FILTER_LABEL[filter]}</SelectValue></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All posts</SelectItem>
            <SelectItem value="visible">Visible</SelectItem>
            <SelectItem value="hidden">Hidden</SelectItem>
          </SelectContent>
        </Select>
        <span className="ml-auto text-xs text-muted-foreground">
          Showing {visible.length} of {filtered.length}
        </span>
      </div>

      <div className="space-y-2">
        {filtered.length === 0 && (
          <p className="py-10 text-center text-sm text-muted-foreground">No posts match these filters.</p>
        )}
        {visible.map((post) => (
          <div
            key={post.id}
            className="flex gap-3 rounded-lg border border-border p-3"
            data-hidden={post.moderation.hidden}
          >
            <Avatar className="size-9 shrink-0">
              <AvatarFallback className="text-xs">{initials(userDisplayName(post.author))}</AvatarFallback>
            </Avatar>
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2">
                <Link href={`/users/${post.author_id}`} className="text-sm font-medium text-foreground hover:underline">
                  {userDisplayName(post.author)}
                </Link>
                <span className="text-xs text-muted-foreground">{formatRelative(post.timestamp)}</span>
                {post.moderation.hidden && <Badge variant="destructive">Hidden</Badge>}
              </div>
              <p className="mt-1 text-sm text-foreground">{post.content}</p>
              {post.image_url && (
                <div className="relative mt-2 h-40 w-64 overflow-hidden rounded-md">
                  <Image src={post.image_url} alt="" fill className="object-cover" sizes="256px" />
                </div>
              )}
              {post.moderation.hidden && post.moderation.hidden_reason && (
                <p className="mt-2 text-xs text-muted-foreground">
                  Hidden reason: <span className="text-foreground">{post.moderation.hidden_reason}</span>
                </p>
              )}
              <div className="mt-2 flex items-center gap-4 text-xs text-muted-foreground">
                <span className="flex items-center gap-1"><Heart size={13} /> {post.likes_count}</span>
                <span className="flex items-center gap-1"><ChatCircle size={13} /> {post.comments_count}</span>
              </div>
            </div>
            <DropdownMenu>
              <DropdownMenuTrigger
                render={
                  <button
                    type="button"
                    className="h-fit rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
                    aria-label="Post actions"
                  />
                }
              >
                <DotsThree size={18} weight="bold" />
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={() => setEditTarget(post)}>
                  <PencilSimple size={14} /> Edit content
                </DropdownMenuItem>
                {post.image_url && (
                  <DropdownMenuItem onClick={() => onRemovePhoto(post.id)}>
                    <ImageBroken size={14} /> Remove photo
                  </DropdownMenuItem>
                )}
                {post.moderation.hidden ? (
                  <DropdownMenuItem onClick={() => onUnhide(post.id)}>
                    <Eye size={14} /> Unhide
                  </DropdownMenuItem>
                ) : (
                  <DropdownMenuItem onClick={() => setHideTarget(post)}>
                    <EyeSlash size={14} /> Hide
                  </DropdownMenuItem>
                )}
                <DropdownMenuItem variant="destructive" onClick={() => setDeleteTarget(post)}>
                  <Trash size={14} /> Delete permanently
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        ))}
      </div>

      {visibleCount < filtered.length && (
        <div className="mt-3 flex justify-center">
          <Button variant="outline" size="sm" onClick={() => setVisibleCount((c) => c + PAGE_SIZE)}>
            Load {Math.min(PAGE_SIZE, filtered.length - visibleCount)} more
          </Button>
        </div>
      )}

      <HidePostDialog
        open={!!hideTarget}
        onOpenChange={(open) => !open && setHideTarget(null)}
        onConfirm={async (reason) => {
          if (hideTarget) await onHide(hideTarget.id, reason);
          setHideTarget(null);
        }}
      />
      <EditPostDialog
        post={editTarget}
        onOpenChange={(open) => !open && setEditTarget(null)}
        onSave={async (content) => {
          if (editTarget) await onEdit(editTarget.id, content);
          setEditTarget(null);
        }}
      />

      <AlertDialog open={!!deleteTarget} onOpenChange={(open) => !open && setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete this post permanently?</AlertDialogTitle>
            <AlertDialogDescription>
              Unlike hiding, this can&apos;t be undone — the post, its likes, and comments are gone for good. Hide it
              instead if you might need to restore it later.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleting}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} disabled={deleting} className="bg-destructive text-white hover:bg-destructive/90">
              {deleting && <CircleNotch size={14} className="animate-spin" />}
              Delete permanently
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
