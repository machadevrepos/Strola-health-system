"use client";

import * as React from "react";
import { CircleNotch } from "@phosphor-icons/react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { userDisplayName } from "@/lib/data/queries";
import type { UserProfile } from "@/lib/types";

export function BanUserDialog({
  user,
  onOpenChange,
  onConfirm,
}: {
  user: UserProfile | null;
  onOpenChange: (open: boolean) => void;
  onConfirm: (reason: string) => void | Promise<void>;
}) {
  const [reason, setReason] = React.useState("");
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (user) setReason("");
  }, [user]);

  async function handleConfirm() {
    setSubmitting(true);
    try {
      await onConfirm(reason.trim());
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Dialog open={!!user} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Ban {user ? userDisplayName(user) : "this user"}</DialogTitle>
          <DialogDescription>
            They&apos;ll be signed out immediately and blocked from signing back in. This is reversible from the
            user&apos;s profile.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-2">
          <Label htmlFor="ban-reason">Reason (visible to other admins)</Label>
          <Textarea
            id="ban-reason"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="e.g. Repeated harassment in community comments after two prior warnings."
            rows={3}
            autoFocus
          />
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button
            variant="destructive"
            disabled={reason.trim().length === 0 || submitting}
            onClick={handleConfirm}
          >
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Ban user
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
