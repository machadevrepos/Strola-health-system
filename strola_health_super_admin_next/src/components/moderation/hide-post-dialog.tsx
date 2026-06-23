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

export function HidePostDialog({
  open,
  onOpenChange,
  onConfirm,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: (reason: string) => void | Promise<void>;
}) {
  const [reason, setReason] = React.useState("");
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (open) setReason("");
  }, [open]);

  async function handleConfirm() {
    setSubmitting(true);
    try {
      await onConfirm(reason.trim());
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Hide post</DialogTitle>
          <DialogDescription>
            The post disappears from the public feed immediately. You can restore it any time from here.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-2">
          <Label htmlFor="hide-reason">Reason</Label>
          <Textarea
            id="hide-reason"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="e.g. Spam / scam link impersonating an official promotion."
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
            Hide post
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
