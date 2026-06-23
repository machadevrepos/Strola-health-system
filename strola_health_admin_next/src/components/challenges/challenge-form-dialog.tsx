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
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { Challenge, ChallengeVisibility } from "@/lib/types";

const VISIBILITY_LABEL: Record<ChallengeVisibility, string> = {
  public: "Public",
  private: "Private (invite-only)",
};

export interface ChallengeFormValues {
  title: string;
  description: string;
  goal_steps: number;
  start_date: string;
  end_date: string;
  badge_emoji: string;
  visibility: ChallengeVisibility;
}

const EMPTY: ChallengeFormValues = {
  title: "",
  description: "",
  goal_steps: 50000,
  start_date: new Date().toISOString().slice(0, 10),
  end_date: new Date(Date.now() + 7 * 86_400_000).toISOString().slice(0, 10),
  badge_emoji: "🏆",
  visibility: "public",
};

export function ChallengeFormDialog({
  open,
  onOpenChange,
  challenge,
  onSave,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  challenge?: Challenge | null;
  onSave: (values: ChallengeFormValues) => void | Promise<void>;
}) {
  const [values, setValues] = React.useState<ChallengeFormValues>(EMPTY);
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (!open) return;
    setValues(
      challenge
        ? {
            title: challenge.title,
            description: challenge.description,
            goal_steps: challenge.goal_steps,
            start_date: challenge.start_date.slice(0, 10),
            end_date: challenge.end_date.slice(0, 10),
            badge_emoji: challenge.badge_emoji,
            visibility: challenge.visibility,
          }
        : EMPTY
    );
  }, [open, challenge]);

  async function handleSave() {
    setSubmitting(true);
    try {
      await onSave(values);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{challenge ? "Edit challenge" : "Create challenge"}</DialogTitle>
          <DialogDescription>
            {challenge ? "Changes apply immediately to anyone already participating." : "Visible to all users once created, unless set to private."}
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-3">
          <div className="grid gap-2">
            <Label htmlFor="ch-title">Title</Label>
            <Input id="ch-title" value={values.title} onChange={(e) => setValues({ ...values, title: e.target.value })} autoFocus />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="ch-description">Description</Label>
            <Textarea
              id="ch-description"
              rows={2}
              value={values.description}
              onChange={(e) => setValues({ ...values, description: e.target.value })}
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="ch-goal">Goal (steps)</Label>
              <Input
                id="ch-goal"
                type="number"
                step={1000}
                value={values.goal_steps}
                onChange={(e) => setValues({ ...values, goal_steps: Number(e.target.value) })}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="ch-emoji">Badge emoji</Label>
              <Input
                id="ch-emoji"
                value={values.badge_emoji}
                onChange={(e) => setValues({ ...values, badge_emoji: e.target.value })}
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="ch-start">Start date</Label>
              <Input
                id="ch-start"
                type="date"
                value={values.start_date}
                onChange={(e) => setValues({ ...values, start_date: e.target.value })}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="ch-end">End date</Label>
              <Input
                id="ch-end"
                type="date"
                value={values.end_date}
                onChange={(e) => setValues({ ...values, end_date: e.target.value })}
              />
            </div>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="ch-visibility">Visibility</Label>
            <Select value={values.visibility} onValueChange={(v) => v && setValues({ ...values, visibility: v as ChallengeVisibility })}>
              <SelectTrigger id="ch-visibility"><SelectValue>{VISIBILITY_LABEL[values.visibility]}</SelectValue></SelectTrigger>
              <SelectContent>
                <SelectItem value="public">Public</SelectItem>
                <SelectItem value="private">Private (invite-only)</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button disabled={values.title.trim().length === 0 || submitting} onClick={handleSave}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            {challenge ? "Save changes" : "Create challenge"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
