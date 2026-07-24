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

export interface MuteTarget {
  userId: string;
  userName: string;
  hours: 24 | 168;
}

const DURATION_LABEL: Record<MuteTarget["hours"], string> = { 24: "24 hours", 168: "7 days" };

export function MuteUserDialog({
  target,
  onOpenChange,
  onConfirm,
}: {
  target: MuteTarget | null;
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
          <DialogTitle>
            Mute {target?.userName ?? "this user"} for {target ? DURATION_LABEL[target.hours] : ""}
          </DialogTitle>
          <DialogDescription>
            Blocks new posts and comments until the mute expires. The account itself stays active — this is
            reversible early from their profile.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-2">
          <Label htmlFor="mute-reason">Reason (visible to other admins, included in the notification)</Label>
          <Textarea
            id="mute-reason"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="e.g. Repeated off-topic self-promotion in comments."
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
            Mute for {target ? DURATION_LABEL[target.hours] : ""}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
