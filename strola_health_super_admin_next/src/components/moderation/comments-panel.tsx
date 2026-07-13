"use client";

import * as React from "react";
import Link from "next/link";
import { Trash, PencilSimple, CheckCircle, MagnifyingGlass, CircleNotch } from "@phosphor-icons/react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
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
import { userDisplayName } from "@/lib/data/queries";
import { formatRelative, initials } from "@/lib/format";
import type { EnrichedComment } from "@/lib/data/queries";

const PAGE_SIZE = 10;

export function CommentsPanel({
  comments,
  onEdit,
  onDelete,
}: {
  comments: EnrichedComment[];
  onEdit: (commentId: string, content: string) => void | Promise<void>;
  onDelete: (commentId: string) => void | Promise<void>;
}) {
  const [query, setQuery] = React.useState("");
  const [deleteTarget, setDeleteTarget] = React.useState<EnrichedComment | null>(null);
  const [deleting, setDeleting] = React.useState(false);
  const [visibleCount, setVisibleCount] = React.useState(PAGE_SIZE);

  const filtered = comments.filter((c) => {
    if (!query) return true;
    const haystack = `${c.content} ${userDisplayName(c.author)} ${c.post?.content ?? ""}`.toLowerCase();
    return haystack.includes(query.toLowerCase());
  });
  const visible = filtered.slice(0, visibleCount);

  React.useEffect(() => setVisibleCount(PAGE_SIZE), [query]);

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

  return (
    <div>
      <div className="mb-3 flex items-center gap-2">
        <div className="relative flex-1 min-w-[220px] max-w-sm">
          <MagnifyingGlass size={14} className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
          <Input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search comments or authors" className="pl-8" />
        </div>
        <span className="ml-auto text-xs text-muted-foreground">
          Showing {visible.length} of {filtered.length}
        </span>
      </div>

      <div className="space-y-2">
        {filtered.length === 0 && (
          <p className="py-10 text-center text-sm text-muted-foreground">No comments match this search.</p>
        )}
        {visible.map((c) => (
          <CommentRow key={c.id} comment={c} onEdit={onEdit} onDeleteClick={() => setDeleteTarget(c)} />
        ))}
      </div>

      {visibleCount < filtered.length && (
        <div className="mt-3 flex justify-center">
          <Button variant="outline" size="sm" onClick={() => setVisibleCount((n) => n + PAGE_SIZE)}>
            Load {Math.min(PAGE_SIZE, filtered.length - visibleCount)} more
          </Button>
        </div>
      )}

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
    </div>
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
    <div className="flex gap-3 rounded-lg border border-border p-3">
      <Avatar className="size-8 shrink-0">
        {c.author?.photo_url && <AvatarImage src={c.author.photo_url} alt={userDisplayName(c.author)} />}
        <AvatarFallback className="text-xs">{initials(userDisplayName(c.author))}</AvatarFallback>
      </Avatar>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <Link href={`/users/${c.author_id}`} className="text-sm font-medium text-foreground hover:underline">
            {userDisplayName(c.author)}
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
                {saving ? <CircleNotch size={14} className="animate-spin" /> : <CheckCircle size={14} />}
                Save
              </Button>
            </div>
          </div>
        ) : (
          <p className="mt-1 text-sm text-foreground">{c.content}</p>
        )}

        {c.post && (
          <p className="mt-1.5 truncate text-xs text-muted-foreground">
            On:{" "}
            <span className="text-foreground">
              &quot;{c.post.content.length > 60 ? `${c.post.content.slice(0, 60)}…` : c.post.content}&quot;
            </span>
          </p>
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
