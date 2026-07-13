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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { userDisplayName } from "@/lib/data/queries";
import type { UserProfile } from "@/lib/types";

const PRESETS = [
  { label: "7 days", days: 7 },
  { label: "30 days", days: 30 },
  { label: "90 days", days: 90 },
  { label: "6 months (Kickstarter)", days: 182 },
];

export function GrantPremiumToUserDialog({
  open,
  onOpenChange,
  candidates,
  onGrant,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  candidates: UserProfile[];
  onGrant: (userId: string, until: Date, reason: string) => void | Promise<void>;
}) {
  const [userId, setUserId] = React.useState("");
  const [days, setDays] = React.useState(30);
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (open) {
      setUserId("");
      setDays(30);
    }
  }, [open]);

  async function handleGrant() {
    if (!userId) return;
    setSubmitting(true);
    const until = new Date();
    until.setDate(until.getDate() + days);
    const reason = days === 182 ? "kickstarter_backer" : "admin_grant";
    try {
      await onGrant(userId, until, reason);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Grant premium to a user</DialogTitle>
          <DialogDescription>Free comp access — doesn&apos;t touch a real subscription if they already have one.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-3">
          <div className="grid gap-2">
            <Label htmlFor="grant-user">User</Label>
            <Select value={userId} onValueChange={(v) => v && setUserId(v)}>
              <SelectTrigger id="grant-user">
                <SelectValue placeholder="Choose a user">
                  {userId ? userDisplayName(candidates.find((u) => u.id === userId)) : "Choose a user"}
                </SelectValue>
              </SelectTrigger>
              <SelectContent>
                {candidates.map((u) => (
                  <SelectItem key={u.id} value={u.id}>
                    {userDisplayName(u)} — {u.email ?? `@${u.username}`}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="grant-period">Comp period</Label>
            <Select value={String(days)} onValueChange={(v) => v && setDays(Number(v))}>
              <SelectTrigger id="grant-period">
                <SelectValue>{PRESETS.find((p) => p.days === days)?.label}</SelectValue>
              </SelectTrigger>
              <SelectContent>
                {PRESETS.map((p) => (
                  <SelectItem key={p.days} value={String(p.days)}>
                    {p.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button disabled={!userId || submitting} onClick={handleGrant}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Grant premium
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
