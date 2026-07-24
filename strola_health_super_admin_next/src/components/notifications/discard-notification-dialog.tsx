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

export interface DiscardNotificationTarget {
  id: string;
  title: string;
  mode: "draft" | "scheduled";
}

export function DiscardNotificationDialog({
  target,
  onOpenChange,
  onConfirm,
}: {
  target: DiscardNotificationTarget | null;
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

  const isScheduled = target?.mode === "scheduled";

  return (
    <AlertDialog open={!!target} onOpenChange={(open) => !submitting && onOpenChange(open)}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>{isScheduled ? "Cancel scheduled send?" : "Delete this draft?"}</AlertDialogTitle>
          <AlertDialogDescription>
            {isScheduled
              ? `"${target?.title ?? "This notification"}" will not go out. This can't be undone — you'd need to compose it again.`
              : `"${target?.title ?? "This draft"}" will be removed for good.`}
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={submitting}>Keep it</AlertDialogCancel>
          <AlertDialogAction onClick={handleConfirm} disabled={submitting} className="bg-destructive text-white hover:bg-destructive/90">
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            {isScheduled ? "Cancel send" : "Delete draft"}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
