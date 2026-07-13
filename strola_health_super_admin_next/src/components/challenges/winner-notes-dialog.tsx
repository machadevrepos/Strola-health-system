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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { userDisplayName } from "@/lib/data/queries";
import { formatNumber } from "@/lib/format";
import type { EnrichedParticipant } from "@/lib/data/queries";
import type { Challenge } from "@/lib/types";

export interface WinnerNotesValues {
  winner_user_id: string | null;
  admin_notes: string;
}

export function WinnerNotesDialog({
  challenge,
  participants,
  onOpenChange,
  onSave,
}: {
  challenge: Challenge | null;
  participants: EnrichedParticipant[];
  onOpenChange: (open: boolean) => void;
  onSave: (values: WinnerNotesValues) => void | Promise<void>;
}) {
  const [winnerId, setWinnerId] = React.useState<string>("");
  const [notes, setNotes] = React.useState("");
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (!challenge) return;
    setWinnerId(challenge.winner_user_id ?? "");
    setNotes(challenge.admin_notes ?? "");
  }, [challenge]);

  async function handleSave() {
    setSubmitting(true);
    try {
      await onSave({ winner_user_id: winnerId || null, admin_notes: notes.trim() });
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Dialog open={!!challenge} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Edit winner — {challenge?.title}</DialogTitle>
          <DialogDescription>
            Defaults to whoever led by {challenge?.winner_type === "goal_completion_pct" ? "goal completion %" : "steps"} when the
            challenge ended — override here if needed (e.g. a disqualification found after the fact).
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-3">
          <div className="grid gap-2">
            <Label htmlFor="winner-select">Winner</Label>
            <Select value={winnerId} onValueChange={(v) => setWinnerId(v ?? "")}>
              <SelectTrigger id="winner-select">
                <SelectValue placeholder="No winner set">
                  {winnerId ? userDisplayName(participants.find((p) => p.user_id === winnerId)?.user) : "No winner set"}
                </SelectValue>
              </SelectTrigger>
              <SelectContent>
                {participants.map((p) => (
                  <SelectItem key={p.user_id} value={p.user_id}>
                    {userDisplayName(p.user)} — {formatNumber(p.steps)} steps
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="admin-notes">Admin notes (never shown to users)</Label>
            <Textarea
              id="admin-notes"
              rows={3}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="e.g. Excluded usr_011 from winner consideration, see report #rep_014."
            />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button onClick={handleSave} disabled={submitting}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Save
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
