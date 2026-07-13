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

export function BanFromPostingDialog({
  target,
  onOpenChange,
  onConfirm,
}: {
  target: { userId: string; userName: string } | null;
  onOpenChange: (open: boolean) => void;
  onConfirm: (reason: string) => void | Promise<void>;
}) {
  const [reason, setReason] = React.useState("");
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (target) setReason("");
  }, [target]);

  async function handleConfirm() {
    setSubmitting(true);
    try {
      await onConfirm(reason.trim());
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Dialog open={!!target} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Ban {target?.userName ?? "this user"} from posting</DialogTitle>
          <DialogDescription>
            Their account stays active — steps, challenges, and everything else keep working — but they can&apos;t
            create new posts or comments until unbanned. Reversible from their profile.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-2">
          <Label htmlFor="posting-ban-reason">Reason (visible to other admins)</Label>
          <Textarea
            id="posting-ban-reason"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="e.g. Repeated spam links across multiple posts."
            rows={3}
            autoFocus
          />
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button variant="destructive" disabled={reason.trim().length === 0 || submitting} onClick={handleConfirm}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Ban from posting
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
