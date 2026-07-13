"use client";

import * as React from "react";
import { toast } from "sonner";
import { Plus, DotsThree, PencilSimple, Trash, CircleNotch } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
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
import { AnnouncementFormDialog, type AnnouncementFormValues } from "@/components/announcements/announcement-form-dialog";
import { createAnnouncement, deleteAnnouncement, updateAnnouncement } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { useAuth } from "@/lib/auth-context";
import { logAction } from "@/lib/audit-log-store";
import { findUserById, userDisplayName } from "@/lib/data/queries";
import { formatDate } from "@/lib/format";
import type { Announcement, UserProfile } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

export function AnnouncementsView({
  announcements: initialAnnouncements,
  users,
}: {
  announcements: Announcement[];
  users: UserProfile[];
}) {
  const { user: currentUser } = useAuth();
  const [announcements, setAnnouncements] = React.useState(initialAnnouncements);
  const [formOpen, setFormOpen] = React.useState(false);
  const [editTarget, setEditTarget] = React.useState<Announcement | null>(null);
  const [deleteTarget, setDeleteTarget] = React.useState<Announcement | null>(null);
  const [deleting, setDeleting] = React.useState(false);

  function toPayload(values: AnnouncementFormValues) {
    return {
      emoji: values.emoji,
      message: values.message.trim(),
      link_target: values.link_target.trim() || null,
      starts_at: new Date(values.starts_at).toISOString(),
      ends_at: values.ends_at ? new Date(values.ends_at).toISOString() : null,
    };
  }

  async function create(values: AnnouncementFormValues) {
    try {
      const created = await createAnnouncement({ ...toPayload(values), created_by: currentUser?.uid ?? null });
      setAnnouncements((prev) => [created, ...prev]);
      toast.success("Announcement created");
      logAction("Created announcement", values.message);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't create announcement"));
    }
  }

  async function save(values: AnnouncementFormValues) {
    if (!editTarget) return;
    try {
      const updated = await updateAnnouncement(editTarget.id, toPayload(values));
      setAnnouncements((prev) => prev.map((a) => (a.id === editTarget.id ? updated : a)));
      toast.success("Announcement updated");
      logAction("Edited announcement", values.message);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't update announcement"));
    } finally {
      setEditTarget(null);
    }
  }

  async function toggleActive(announcement: Announcement, active: boolean) {
    try {
      const updated = await updateAnnouncement(announcement.id, { active });
      setAnnouncements((prev) => prev.map((a) => (a.id === announcement.id ? updated : a)));
      toast.success(active ? "Announcement activated" : "Announcement deactivated");
      logAction(active ? "Activated announcement" : "Deactivated announcement", announcement.message);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't update announcement"));
    }
  }

  async function confirmDelete() {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await deleteAnnouncement(deleteTarget.id);
      setAnnouncements((prev) => prev.filter((a) => a.id !== deleteTarget.id));
      toast.success("Announcement deleted");
      logAction("Deleted announcement", deleteTarget.message);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't delete announcement"));
    } finally {
      setDeleting(false);
      setDeleteTarget(null);
    }
  }

  return (
    <div>
      <div className="mb-3 flex justify-end">
        <Button size="sm" onClick={() => setFormOpen(true)}>
          <Plus size={14} /> New announcement
        </Button>
      </div>

      <div className="space-y-2">
        {announcements.length === 0 && (
          <p className="py-10 text-center text-sm text-muted-foreground">No announcements yet.</p>
        )}
        {announcements.map((a) => (
          <Card key={a.id} className="border-border shadow-none">
            <CardContent className="flex items-start gap-3">
              <span className="text-2xl">{a.emoji}</span>
              <div className="min-w-0 flex-1">
                <p className="text-sm text-foreground">{a.message}</p>
                <div className="mt-2 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                  <Badge className={a.active ? "bg-success/15 text-success" : "bg-secondary text-foreground"}>
                    {a.active ? "Active" : "Inactive"}
                  </Badge>
                  {a.link_target && (
                    <Badge variant="outline" className="font-mono text-[11px]">
                      → {a.link_target}
                    </Badge>
                  )}
                  <span>
                    {formatDate(a.starts_at)} {a.ends_at ? `– ${formatDate(a.ends_at)}` : "– indefinite"}
                  </span>
                  {a.created_by && <span>· created by {userDisplayName(findUserById(users, a.created_by))}</span>}
                </div>
              </div>
              <div className="flex shrink-0 items-center gap-2">
                <Switch checked={a.active} onCheckedChange={(v) => toggleActive(a, !!v)} />
                <DropdownMenu>
                  <DropdownMenuTrigger
                    render={<button type="button" className="rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-foreground" aria-label="Announcement actions" />}
                  >
                    <DotsThree size={18} weight="bold" />
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem onClick={() => setEditTarget(a)}>
                      <PencilSimple size={14} /> Edit
                    </DropdownMenuItem>
                    <DropdownMenuItem variant="destructive" onClick={() => setDeleteTarget(a)}>
                      <Trash size={14} /> Delete
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <AnnouncementFormDialog open={formOpen} onOpenChange={setFormOpen} onSave={async (v) => { await create(v); setFormOpen(false); }} />
      <AnnouncementFormDialog
        open={!!editTarget}
        onOpenChange={(open) => !open && setEditTarget(null)}
        announcement={editTarget}
        onSave={save}
      />

      <AlertDialog open={!!deleteTarget} onOpenChange={(open) => !open && setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete this announcement?</AlertDialogTitle>
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
