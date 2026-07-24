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
import type { Challenge } from "@/lib/types";

// Deliberately narrow — the app has exactly one admin-controlled challenge
// (the recurring official monthly one), and per the client only its name,
// photo, and description are editorial decisions. Everything else (dates,
// goal, visibility, winner rules) either doesn't apply or isn't something
// an admin sets by hand here.
export interface OfficialChallengeFormValues {
  title: string;
  description: string;
  image_url: string;
  start_date: string;
  end_date: string;
}

const EMPTY: OfficialChallengeFormValues = {
  title: "",
  description: "",
  image_url: "",
  start_date: new Date().toISOString().slice(0, 10),
  end_date: new Date(Date.now() + 30 * 86_400_000).toISOString().slice(0, 10),
};

export function OfficialChallengeFormDialog({
  open,
  onOpenChange,
  challenge,
  onSave,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  challenge?: Challenge | null;
  onSave: (values: OfficialChallengeFormValues) => void | Promise<void>;
}) {
  const [values, setValues] = React.useState<OfficialChallengeFormValues>(EMPTY);
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (!open) return;
    setValues(
      challenge
        ? {
            title: challenge.title,
            description: challenge.description,
            image_url: challenge.image_url ?? "",
            start_date: challenge.start_date.slice(0, 10),
            end_date: challenge.end_date.slice(0, 10),
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
          <DialogTitle>{challenge ? "Edit official challenge" : "Set up official challenge"}</DialogTitle>
          <DialogDescription>
            The one recurring public challenge everyone sees — winner is whoever logs the most steps, no goal to hit.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-3">
          <div className="grid gap-2">
            <Label htmlFor="oc-title">Name</Label>
            <Input id="oc-title" value={values.title} onChange={(e) => setValues({ ...values, title: e.target.value })} autoFocus />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="oc-description">Description</Label>
            <Textarea
              id="oc-description"
              rows={3}
              value={values.description}
              onChange={(e) => setValues({ ...values, description: e.target.value })}
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="oc-image">Photo URL</Label>
            <Input
              id="oc-image"
              value={values.image_url}
              onChange={(e) => setValues({ ...values, image_url: e.target.value })}
              placeholder="https://…"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="oc-start">Start date</Label>
              <Input
                id="oc-start"
                type="date"
                value={values.start_date}
                onChange={(e) => setValues({ ...values, start_date: e.target.value })}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="oc-end">End date</Label>
              <Input
                id="oc-end"
                type="date"
                value={values.end_date}
                onChange={(e) => setValues({ ...values, end_date: e.target.value })}
              />
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button disabled={values.title.trim().length === 0 || submitting} onClick={handleSave}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            {challenge ? "Save changes" : "Create"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
