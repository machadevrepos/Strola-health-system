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
import { AnnouncementBannerPreview } from "@/components/announcements/announcement-banner-preview";
import { ANNOUNCEMENT_AUDIENCE_LABEL, announcementAudienceIds } from "@/lib/data/queries";
import { formatNumber } from "@/lib/format";
import type { Announcement, AnnouncementAudience, AppVersionAudienceMode, UserProfile } from "@/lib/types";

export interface AnnouncementFormValues {
  emoji: string;
  message: string;
  link_target: string;
  audience: AnnouncementAudience;
  audience_app_version: string;
  audience_app_version_mode: AppVersionAudienceMode;
  starts_at: string;
  ends_at: string;
}

const EMPTY: AnnouncementFormValues = {
  emoji: "📣",
  message: "",
  link_target: "",
  audience: "everyone",
  audience_app_version: "",
  audience_app_version_mode: "at_or_below",
  starts_at: new Date().toISOString().slice(0, 10),
  ends_at: "",
};

const AUDIENCES = Object.keys(ANNOUNCEMENT_AUDIENCE_LABEL) as AnnouncementAudience[];

export function AnnouncementFormDialog({
  open,
  onOpenChange,
  announcement,
  users,
  onSave,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  announcement?: Announcement | null;
  users: UserProfile[];
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
            audience: announcement.audience,
            audience_app_version: announcement.audience_app_version ?? "",
            audience_app_version_mode: announcement.audience_app_version_mode ?? "at_or_below",
            starts_at: announcement.starts_at.slice(0, 10),
            ends_at: announcement.ends_at?.slice(0, 10) ?? "",
          }
        : EMPTY
    );
  }, [open, announcement]);

  const knownVersions = React.useMemo(
    () => Array.from(new Set(users.map((u) => u.app_version))).sort((a, b) => (a < b ? 1 : a > b ? -1 : 0)),
    [users]
  );

  const audienceCount = announcementAudienceIds(
    {
      audience: values.audience,
      audience_app_version: values.audience_app_version || null,
      audience_app_version_mode: values.audience_app_version_mode,
    },
    users
  ).length;

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
      <DialogContent className="sm:max-w-xl">
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

          <div className="grid gap-2">
            <Label htmlFor="ann-audience">Audience</Label>
            <Select value={values.audience} onValueChange={(v) => v && setValues({ ...values, audience: v as AnnouncementAudience })}>
              <SelectTrigger id="ann-audience"><SelectValue>{ANNOUNCEMENT_AUDIENCE_LABEL[values.audience]}</SelectValue></SelectTrigger>
              <SelectContent>
                {AUDIENCES.map((a) => (
                  <SelectItem key={a} value={a}>
                    {ANNOUNCEMENT_AUDIENCE_LABEL[a]}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            {values.audience === "app_version" && (
              <div className="flex gap-2">
                <Select
                  value={values.audience_app_version}
                  onValueChange={(v) => v && setValues({ ...values, audience_app_version: v })}
                >
                  <SelectTrigger className="flex-1">
                    <SelectValue placeholder="Choose a version">{values.audience_app_version || "Choose a version"}</SelectValue>
                  </SelectTrigger>
                  <SelectContent>
                    {knownVersions.map((v) => (
                      <SelectItem key={v} value={v}>
                        {v}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <div className="flex shrink-0 gap-1 rounded-md border border-border bg-secondary/40 p-0.5">
                  <Button
                    type="button"
                    size="sm"
                    variant={values.audience_app_version_mode === "at_or_below" ? "secondary" : "ghost"}
                    className="h-8"
                    onClick={() => setValues({ ...values, audience_app_version_mode: "at_or_below" })}
                  >
                    Or older
                  </Button>
                  <Button
                    type="button"
                    size="sm"
                    variant={values.audience_app_version_mode === "exact" ? "secondary" : "ghost"}
                    className="h-8"
                    onClick={() => setValues({ ...values, audience_app_version_mode: "exact" })}
                  >
                    Exact
                  </Button>
                </div>
              </div>
            )}
            <p className="text-xs text-muted-foreground">
              ~{formatNumber(audienceCount)} user{audienceCount === 1 ? "" : "s"} match this audience right now.
            </p>
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

          <div className="grid gap-2">
            <Label className="mb-0">Preview</Label>
            <AnnouncementBannerPreview emoji={values.emoji} message={values.message} hasLink={values.link_target.trim().length > 0} />
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
