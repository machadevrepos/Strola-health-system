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

export function DeleteAccountDialog({
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
          <AlertDialogTitle>Delete {userDisplayName(user)}&apos;s account</AlertDialogTitle>
          <AlertDialogDescription>
            Profile info (name, email, DOB, photo, bio, location) is scrubbed and the account is shown as
            &quot;Deleted User&quot; everywhere. Workout history, GPS routes, and past community posts are{" "}
            <strong>kept</strong>, per policy — only personal info is removed. This cannot be undone from here.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <div className="grid gap-2">
          <Label htmlFor="confirm-delete">
            Type <span className="font-mono font-medium text-foreground">{expected}</span> to confirm
          </Label>
          <Input id="confirm-delete" value={confirmText} onChange={(e) => setConfirmText(e.target.value)} autoFocus />
        </div>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={submitting}>Cancel</AlertDialogCancel>
          <AlertDialogAction
            disabled={confirmText !== expected || submitting}
            onClick={handleConfirm}
            className="bg-destructive text-white hover:bg-destructive/90"
          >
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Delete account
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
