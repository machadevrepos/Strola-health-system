"use client";

import * as React from "react";
import { toast } from "sonner";
import { Plus, DotsThree, PencilSimple, Trash, CircleNotch } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
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
import { BadgeFormDialog, type BadgeFormValues } from "@/components/challenges/badge-form-dialog";
import { logAction } from "@/lib/audit-log-store";
import { ApiError } from "@/lib/api-client";
import { createBadge as apiCreateBadge, deleteBadge as apiDeleteBadge, updateBadge } from "@/lib/data/api";
import type { Badge as BadgeT } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

export function BadgesGrid({
  badges: initialBadges,
  awardCounts,
}: {
  badges: BadgeT[];
  awardCounts: Record<string, number>;
}) {
  const [badges, setBadges] = React.useState(initialBadges);
  const [formOpen, setFormOpen] = React.useState(false);
  const [editTarget, setEditTarget] = React.useState<BadgeT | null>(null);
  const [deleteTarget, setDeleteTarget] = React.useState<BadgeT | null>(null);
  const [deleting, setDeleting] = React.useState(false);

  React.useEffect(() => setBadges(initialBadges), [initialBadges]);

  async function createBadge(values: BadgeFormValues) {
    try {
      const created = await apiCreateBadge(values);
      setBadges((prev) => [created, ...prev]);
      toast.success("Badge created");
      logAction("Created badge", values.name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't create badge"));
    }
  }

  async function saveBadge(values: BadgeFormValues) {
    if (!editTarget) return;
    try {
      const updated = await updateBadge(editTarget.id, values);
      setBadges((prev) => prev.map((b) => (b.id === editTarget.id ? updated : b)));
      toast.success("Badge updated");
      logAction("Edited badge", values.name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't update badge"));
    } finally {
      setEditTarget(null);
    }
  }

  async function deleteBadge() {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await apiDeleteBadge(deleteTarget.id);
      setBadges((prev) => prev.filter((b) => b.id !== deleteTarget.id));
      toast.success("Badge deleted");
      logAction("Deleted badge", deleteTarget.name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't delete badge"));
    } finally {
      setDeleting(false);
      setDeleteTarget(null);
    }
  }

  return (
    <div>
      <div className="mb-3 flex justify-end">
        <Button size="sm" onClick={() => setFormOpen(true)}>
          <Plus size={14} /> Create badge
        </Button>
      </div>

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {badges.map((b) => (
          <Card key={b.id} className="border-border shadow-none">
            <CardContent>
              <div className="flex items-start justify-between gap-2">
                <div className="flex items-center gap-2.5">
                  <span className="text-2xl">{b.emoji}</span>
                  <div>
                    <p className="text-sm font-medium text-foreground">{b.name}</p>
                    <p className="text-xs text-muted-foreground">{awardCounts[b.id] ?? 0} awarded</p>
                  </div>
                </div>
                <DropdownMenu>
                  <DropdownMenuTrigger
                    render={<button type="button" className="rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-foreground" aria-label="Badge actions" />}
                  >
                    <DotsThree size={18} weight="bold" />
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem onClick={() => setEditTarget(b)}>
                      <PencilSimple size={14} /> Edit
                    </DropdownMenuItem>
                    <DropdownMenuItem variant="destructive" onClick={() => setDeleteTarget(b)}>
                      <Trash size={14} /> Delete
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
              <p className="mt-2 text-sm text-muted-foreground">{b.description}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <BadgeFormDialog open={formOpen} onOpenChange={setFormOpen} onSave={async (v) => { await createBadge(v); setFormOpen(false); }} />
      <BadgeFormDialog open={!!editTarget} onOpenChange={(open) => !open && setEditTarget(null)} badge={editTarget} onSave={saveBadge} />

      <AlertDialog open={!!deleteTarget} onOpenChange={(open) => !open && setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete &quot;{deleteTarget?.name}&quot;?</AlertDialogTitle>
            <AlertDialogDescription>
              This removes the badge and every award of it from users&apos; profiles. This cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleting}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={deleteBadge} disabled={deleting} className="bg-destructive text-white hover:bg-destructive/90">
              {deleting && <CircleNotch size={14} className="animate-spin" />}
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
