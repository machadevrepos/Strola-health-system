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
import type { Badge as BadgeT } from "@/lib/types";

export interface BadgeFormValues {
  name: string;
  description: string;
  emoji: string;
}

const EMPTY: BadgeFormValues = { name: "", description: "", emoji: "🏅" };

export function BadgeFormDialog({
  open,
  onOpenChange,
  badge,
  onSave,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  badge?: BadgeT | null;
  onSave: (values: BadgeFormValues) => void | Promise<void>;
}) {
  const [values, setValues] = React.useState<BadgeFormValues>(EMPTY);
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (!open) return;
    setValues(badge ? { name: badge.name, description: badge.description, emoji: badge.emoji } : EMPTY);
  }, [open, badge]);

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
          <DialogTitle>{badge ? "Edit badge" : "Create badge"}</DialogTitle>
          <DialogDescription>Badges are awarded manually from a user&apos;s profile.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-3">
          <div className="grid grid-cols-[1fr_5rem] gap-3">
            <div className="grid gap-2">
              <Label htmlFor="badge-name">Name</Label>
              <Input id="badge-name" value={values.name} onChange={(e) => setValues({ ...values, name: e.target.value })} autoFocus />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="badge-emoji">Emoji</Label>
              <Input id="badge-emoji" value={values.emoji} onChange={(e) => setValues({ ...values, emoji: e.target.value })} />
            </div>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="badge-description">Description</Label>
            <Textarea
              id="badge-description"
              rows={2}
              value={values.description}
              onChange={(e) => setValues({ ...values, description: e.target.value })}
            />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button disabled={values.name.trim().length === 0 || submitting} onClick={handleSave}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            {badge ? "Save changes" : "Create badge"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
