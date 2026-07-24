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

export interface DeleteAllPostsTarget {
  userId: string;
  userName: string;
  postCount: number;
}

export function DeleteAllPostsDialog({
  target,
  onOpenChange,
  onConfirm,
}: {
  target: DeleteAllPostsTarget | null;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void | Promise<void>;
}) {
  const [submitting, setSubmitting] = React.useState(false);

  async function handleConfirm() {
    setSubmitting(true);
    try {
      await onConfirm();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AlertDialog open={!!target} onOpenChange={(open) => !submitting && onOpenChange(open)}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>
            Delete all {target?.postCount ?? 0} post{target?.postCount === 1 ? "" : "s"} from {target?.userName ?? "this user"}?
          </AlertDialogTitle>
          <AlertDialogDescription>
            Every post this account has published is removed, along with their comments and photos. This cannot be
            undone. The account itself is not affected.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={submitting}>Cancel</AlertDialogCancel>
          <AlertDialogAction onClick={handleConfirm} disabled={submitting} className="bg-destructive text-white hover:bg-destructive/90">
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Delete all posts
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
