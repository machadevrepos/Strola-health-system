"use client";

import * as React from "react";
import { CircleNotch } from "@phosphor-icons/react";
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
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { userDisplayName } from "@/lib/data/queries";
import type { UserProfile } from "@/lib/types";

/** For a compliance request that can't wait out the normal 90-day
 * retention window — see purgeDeletedAccounts.ts. Only ever shown for an
 * account already soft-deleted; this skips the wait, not the soft-delete
 * step itself. */
export function PurgeAccountDialog({
  user,
  open,
  onOpenChange,
  onConfirm,
}: {
  user: UserProfile;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void | Promise<void>;
}) {
  const [confirmText, setConfirmText] = React.useState("");
  const [submitting, setSubmitting] = React.useState(false);
  const expected = user.username;

  React.useEffect(() => {
    if (open) setConfirmText("");
  }, [open]);

  async function handleConfirm() {
    setSubmitting(true);
    try {
      await onConfirm();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Permanently purge {userDisplayName(user)}&apos;s data</AlertDialogTitle>
          <AlertDialogDescription>
            Hard-deletes everything this account still has — workout sessions, community posts, comments, likes,
            friendships, blocks, challenge participation, and device tokens — then removes the account itself. This
            is what would normally happen automatically 90 days after deletion; this does it now instead.{" "}
            <strong>This cannot be undone.</strong>
          </AlertDialogDescription>
        </AlertDialogHeader>
        <div className="grid gap-2">
          <Label htmlFor="confirm-purge">
            Type <span className="font-mono font-medium text-foreground">{expected}</span> to confirm
          </Label>
          <Input id="confirm-purge" value={confirmText} onChange={(e) => setConfirmText(e.target.value)} autoFocus />
        </div>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={submitting}>Cancel</AlertDialogCancel>
          <AlertDialogAction
            disabled={confirmText !== expected || submitting}
            onClick={handleConfirm}
            className="bg-destructive text-white hover:bg-destructive/90"
          >
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Purge now
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
