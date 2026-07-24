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
import { Input } from "@/components/ui/input";
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

// `days: null` means lifetime — no expiry to compute.
const PRESETS = [
  { label: "7 days", days: 7, reason: "admin_grant" },
  { label: "30 days", days: 30, reason: "admin_grant" },
  { label: "90 days", days: 90, reason: "admin_grant" },
  { label: "6 months (Kickstarter)", days: 182, reason: "kickstarter_backer" },
  { label: "1 year (beta tester)", days: 365, reason: "beta_tester" },
  { label: "Lifetime", days: null, reason: "lifetime_grant" },
] as const;

export function GrantPremiumToUserDialog({
  open,
  onOpenChange,
  candidates,
  onGrant,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  candidates: UserProfile[];
  onGrant: (userId: string, until: Date | null, reason: string) => void | Promise<void>;
}) {
  const [userId, setUserId] = React.useState("");
  const [presetIndex, setPresetIndex] = React.useState(1);
  const [reason, setReason] = React.useState<string>(PRESETS[1].reason);
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (open) {
      setUserId("");
      setPresetIndex(1);
      setReason(PRESETS[1].reason);
    }
  }, [open]);

  function selectPreset(index: number) {
    setPresetIndex(index);
    setReason(PRESETS[index].reason);
  }

  async function handleGrant() {
    if (!userId || reason.trim().length === 0) return;
    setSubmitting(true);
    const days = PRESETS[presetIndex].days;
    const until = days === null ? null : new Date(Date.now() + days * 86_400_000);
    try {
      await onGrant(userId, until, reason.trim());
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
            <Select value={String(presetIndex)} onValueChange={(v) => v && selectPreset(Number(v))}>
              <SelectTrigger id="grant-period">
                <SelectValue>{PRESETS[presetIndex].label}</SelectValue>
              </SelectTrigger>
              <SelectContent>
                {PRESETS.map((p, i) => (
                  <SelectItem key={p.label} value={String(i)}>
                    {p.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="grant-reason">Reason (visible to other admins, and on their profile)</Label>
            <Input
              id="grant-reason"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="e.g. beta_tester, kickstarter_backer, customer support goodwill..."
            />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button disabled={!userId || reason.trim().length === 0 || submitting} onClick={handleGrant}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Grant premium
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
