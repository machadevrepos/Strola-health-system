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

export interface LegalConfirmTarget {
  title: string;
  description: string;
  confirmLabel: string;
  destructive?: boolean;
  onConfirm: () => void | Promise<void>;
}

// One generic confirm dialog reused for "discard draft" and "restore an old
// version" — both are a single yes/no with a short explanation, no reason
// for two near-identical files.
export function LegalConfirmDialog({ target, onOpenChange }: { target: LegalConfirmTarget | null; onOpenChange: (open: boolean) => void }) {
  const [submitting, setSubmitting] = React.useState(false);

  async function handleConfirm() {
    if (!target) return;
    setSubmitting(true);
    try {
      await target.onConfirm();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AlertDialog open={!!target} onOpenChange={(open) => !submitting && onOpenChange(open)}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>{target?.title}</AlertDialogTitle>
          <AlertDialogDescription>{target?.description}</AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={submitting}>Cancel</AlertDialogCancel>
          <AlertDialogAction
            onClick={handleConfirm}
            disabled={submitting}
            className={target?.destructive ? "bg-destructive text-white hover:bg-destructive/90" : ""}
          >
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            {target?.confirmLabel}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
