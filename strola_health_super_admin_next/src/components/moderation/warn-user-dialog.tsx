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

export function WarnUserDialog({
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
          <DialogTitle>Warn {target?.userName ?? "this user"}</DialogTitle>
          <DialogDescription>
            Sends a formal warning email referencing the community guidelines. No effect on their account status —
            use Suspend for anything more serious.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-2">
          <Label htmlFor="warn-reason">Reason (included in the email, and visible to other admins)</Label>
          <Textarea
            id="warn-reason"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="e.g. Unsubstantiated accusation against staff in community comments."
            rows={3}
            autoFocus
          />
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button disabled={reason.trim().length === 0 || submitting} onClick={handleConfirm}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Send warning
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
