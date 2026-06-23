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
import { formatDate } from "@/lib/format";

export interface PendingGrant {
  userName: string;
  until: Date;
  reason: string;
}

export function GrantPremiumConfirmDialog({
  pending,
  onOpenChange,
  onConfirm,
}: {
  pending: PendingGrant | null;
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
    <AlertDialog open={!!pending} onOpenChange={onOpenChange}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Grant premium to {pending?.userName}?</AlertDialogTitle>
          <AlertDialogDescription>
            They&apos;ll get full premium access (widget, private challenges, activity insights) free of charge,
            until <strong>{pending ? formatDate(pending.until.toISOString()) : ""}</strong>. This doesn&apos;t affect
            a real subscription if they already have one.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={submitting}>Cancel</AlertDialogCancel>
          <AlertDialogAction onClick={handleConfirm} disabled={submitting}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Grant premium
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
