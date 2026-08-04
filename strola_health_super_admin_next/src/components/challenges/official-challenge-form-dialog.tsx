"use client";

import * as React from "react";
import { CircleNotch, ImageSquare, X } from "@phosphor-icons/react";
import { ref as storageRef, uploadBytes, getDownloadURL } from "firebase/storage";
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
import { getFirebaseStorage } from "@/lib/firebase-client";
import { IS_MOCK_MODE } from "@/lib/mock-mode";
import { useAuth } from "@/lib/auth-context";
import type { Challenge } from "@/lib/types";

// Deliberately narrow — the app has exactly one admin-controlled challenge
// (the recurring official monthly one). Per the client, name/photo/
// description/goal are the editorial decisions; visibility and winner rules
// aren't something an admin sets by hand here (always public, most-steps).
export interface OfficialChallengeFormValues {
  title: string;
  description: string;
  image_url: string;
  goal_steps: number;
  start_date: string;
  end_date: string;
}

const EMPTY: OfficialChallengeFormValues = {
  title: "",
  description: "",
  image_url: "",
  goal_steps: 100000,
  start_date: new Date().toISOString().slice(0, 10),
  end_date: new Date(Date.now() + 30 * 86_400_000).toISOString().slice(0, 10),
};

const HTTP_URL_PATTERN = /^https?:\/\/[^\s]+\.[^\s]+$/i;

function validate(values: OfficialChallengeFormValues): { title?: string; image_url?: string; goal_steps?: string; end_date?: string } {
  const errors: { title?: string; image_url?: string; goal_steps?: string; end_date?: string } = {};
  if (!values.title.trim()) errors.title = "Name is required.";
  else if (values.title.length > 40) errors.title = "Name must be 40 characters or fewer.";
  if (values.image_url.trim() && !HTTP_URL_PATTERN.test(values.image_url.trim())) {
    errors.image_url = "Enter a full URL starting with http:// or https://";
  }
  if (!values.goal_steps || values.goal_steps <= 0) errors.goal_steps = "Goal must be a positive number of steps.";
  if (values.start_date && values.end_date && values.end_date < values.start_date) {
    errors.end_date = "End date must be on or after the start date.";
  }
  return errors;
}

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
  const { user: authUser } = useAuth();
  const [values, setValues] = React.useState<OfficialChallengeFormValues>(EMPTY);
  const [submitting, setSubmitting] = React.useState(false);
  const [uploading, setUploading] = React.useState(false);
  const [uploadError, setUploadError] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (!open) return;
    setValues(
      challenge
        ? {
            title: challenge.title,
            description: challenge.description,
            image_url: challenge.image_url ?? "",
            goal_steps: challenge.goal_steps ?? EMPTY.goal_steps,
            start_date: challenge.start_date.slice(0, 10),
            end_date: challenge.end_date.slice(0, 10),
          }
        : EMPTY
    );
  }, [open, challenge]);

  const errors = validate(values);
  const isValid = Object.keys(errors).length === 0;

  async function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = ""; // lets the same file be picked again after removing it
    if (!file) return;

    setUploadError(null);
    setUploading(true);
    try {
      // Mock mode has no real Firebase project behind it — a local object
      // URL previews the picture in the demo without touching Storage.
      if (IS_MOCK_MODE) {
        setValues((v) => ({ ...v, image_url: URL.createObjectURL(file) }));
        return;
      }
      if (!authUser) throw new Error("Not signed in.");
      const ext = file.name.includes(".") ? file.name.slice(file.name.lastIndexOf(".")) : "";
      const path = `challenge_images/${authUser.uid}/${Date.now()}${ext}`;
      const fileRef = storageRef(getFirebaseStorage(), path);
      await uploadBytes(fileRef, file, { contentType: file.type || "image/jpeg" });
      const url = await getDownloadURL(fileRef);
      setValues((v) => ({ ...v, image_url: url }));
    } catch {
      setUploadError("Couldn't upload that image. Please try again.");
    } finally {
      setUploading(false);
    }
  }

  async function handleSave() {
    if (!isValid) return;
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
            The one recurring public challenge everyone sees — winner is whoever logs the most steps toward the goal below.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-3">
          <div className="grid gap-2">
            <Label htmlFor="oc-title">Name</Label>
            <Input
              id="oc-title"
              value={values.title}
              onChange={(e) => setValues({ ...values, title: e.target.value })}
              aria-invalid={!!errors.title}
              autoFocus
            />
            {errors.title && <p className="text-xs text-destructive">{errors.title}</p>}
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
            <Label htmlFor="oc-image">Cover photo</Label>
            {values.image_url ? (
              <div className="relative overflow-hidden rounded-md border">
                {/* eslint-disable-next-line @next/next/no-img-element -- arbitrary Storage download URL, not a build-time-known asset */}
                <img src={values.image_url} alt="" className="h-32 w-full object-cover" />
                <Button
                  type="button"
                  variant="secondary"
                  size="icon-sm"
                  className="absolute top-2 right-2"
                  onClick={() => setValues({ ...values, image_url: "" })}
                  disabled={uploading}
                >
                  <X size={14} />
                </Button>
              </div>
            ) : (
              <label
                htmlFor="oc-image"
                className="flex h-32 cursor-pointer flex-col items-center justify-center gap-1.5 rounded-md border border-dashed text-sm text-muted-foreground hover:bg-muted/50"
              >
                {uploading ? (
                  <>
                    <CircleNotch size={18} className="animate-spin" />
                    Uploading…
                  </>
                ) : (
                  <>
                    <ImageSquare size={20} />
                    Click to upload a landscape photo
                  </>
                )}
              </label>
            )}
            <input
              id="oc-image"
              type="file"
              accept="image/*"
              className="hidden"
              onChange={handleFileChange}
              disabled={uploading}
            />
            {errors.image_url && <p className="text-xs text-destructive">{errors.image_url}</p>}
            {uploadError && <p className="text-xs text-destructive">{uploadError}</p>}
          </div>
          <div className="grid gap-2">
            <Label htmlFor="oc-goal">Goal (steps)</Label>
            <Input
              id="oc-goal"
              type="number"
              min={1}
              value={values.goal_steps}
              onChange={(e) => setValues({ ...values, goal_steps: Number(e.target.value) })}
              aria-invalid={!!errors.goal_steps}
            />
            {errors.goal_steps && <p className="text-xs text-destructive">{errors.goal_steps}</p>}
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
                aria-invalid={!!errors.end_date}
              />
              {errors.end_date && <p className="text-xs text-destructive">{errors.end_date}</p>}
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button disabled={!isValid || submitting || uploading} onClick={handleSave}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            {challenge ? "Save changes" : "Create"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
