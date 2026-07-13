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
import type { Announcement } from "@/lib/types";

export interface AnnouncementFormValues {
  emoji: string;
  message: string;
  link_target: string;
  starts_at: string;
  ends_at: string;
}

const EMPTY: AnnouncementFormValues = {
  emoji: "📣",
  message: "",
  link_target: "",
  starts_at: new Date().toISOString().slice(0, 10),
  ends_at: "",
};

export function AnnouncementFormDialog({
  open,
  onOpenChange,
  announcement,
  onSave,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  announcement?: Announcement | null;
  onSave: (values: AnnouncementFormValues) => void | Promise<void>;
}) {
  const [values, setValues] = React.useState<AnnouncementFormValues>(EMPTY);
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (!open) return;
    setValues(
      announcement
        ? {
            emoji: announcement.emoji,
            message: announcement.message,
            link_target: announcement.link_target ?? "",
            starts_at: announcement.starts_at.slice(0, 10),
            ends_at: announcement.ends_at?.slice(0, 10) ?? "",
          }
        : EMPTY
    );
  }, [open, announcement]);

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
          <DialogTitle>{announcement ? "Edit announcement" : "New announcement"}</DialogTitle>
          <DialogDescription>Shown once per user the next time they open the app, while active.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-3">
          <div className="grid grid-cols-[5rem_1fr] gap-3">
            <div className="grid gap-2">
              <Label htmlFor="ann-emoji">Emoji</Label>
              <Input id="ann-emoji" value={values.emoji} onChange={(e) => setValues({ ...values, emoji: e.target.value })} autoFocus />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="ann-link">Link target (optional)</Label>
              <Input
                id="ann-link"
                value={values.link_target}
                onChange={(e) => setValues({ ...values, link_target: e.target.value })}
                placeholder="challenge_of_the_month"
              />
            </div>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="ann-message">Message</Label>
            <Textarea
              id="ann-message"
              rows={3}
              value={values.message}
              onChange={(e) => setValues({ ...values, message: e.target.value })}
              placeholder="July Challenge is Live! Join now and compete for the top spot."
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="ann-start">Starts</Label>
              <Input id="ann-start" type="date" value={values.starts_at} onChange={(e) => setValues({ ...values, starts_at: e.target.value })} />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="ann-end">Ends (optional)</Label>
              <Input id="ann-end" type="date" value={values.ends_at} onChange={(e) => setValues({ ...values, ends_at: e.target.value })} />
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button disabled={values.message.trim().length === 0 || submitting} onClick={handleSave}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            {announcement ? "Save changes" : "Create announcement"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
