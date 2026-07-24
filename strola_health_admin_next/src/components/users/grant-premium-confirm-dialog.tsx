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
import { formatDate } from "@/lib/format";

export interface PendingGrant {
  userName: string;
  // null means lifetime — no expiry.
  until: Date | null;
  reason: string;
}

export function GrantPremiumConfirmDialog({
  pending,
  onOpenChange,
  onConfirm,
}: {
  pending: PendingGrant | null;
  onOpenChange: (open: boolean) => void;
  onConfirm: (reason: string) => void | Promise<void>;
}) {
  const [reason, setReason] = React.useState("");
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (pending) setReason(pending.reason);
  }, [pending]);

  async function handleConfirm() {
    setSubmitting(true);
    try {
      await onConfirm(reason.trim());
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
            {pending?.until ? (
              <>
                {" "}
                until <strong>{formatDate(pending.until.toISOString())}</strong>
              </>
            ) : (
              <strong> forever (lifetime)</strong>
            )}
            . This doesn&apos;t affect a real subscription if they already have one.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <div className="grid gap-2">
          <Label htmlFor="grant-confirm-reason">Reason (visible to other admins, and on their profile)</Label>
          <Input id="grant-confirm-reason" value={reason} onChange={(e) => setReason(e.target.value)} />
        </div>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={submitting}>Cancel</AlertDialogCancel>
          <AlertDialogAction onClick={handleConfirm} disabled={submitting || reason.trim().length === 0}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Grant premium
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
