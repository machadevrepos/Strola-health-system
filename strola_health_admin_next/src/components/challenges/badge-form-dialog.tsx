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
import { Switch } from "@/components/ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { EmojiPickerPopover } from "@/components/ui/emoji-picker-popover";
import type { Badge as BadgeT, BadgeRequirementMetric } from "@/lib/types";

export const METRIC_LABEL: Record<BadgeRequirementMetric, string> = {
  total_steps: "Total steps",
  session_steps: "Steps in a single session",
  streak_days: "Daily-goal streak (days)",
  challenges_completed: "Challenges completed",
  // Retired — kept only so legacy badges created before categories were
  // locked down still render a real label instead of "undefined".
  early_morning_sessions: "Sessions before 7am (retired)",
  community_posts: "Community posts (retired)",
};

// The app's Achievements screen groups every badge into exactly one of
// these three sections — new badges must fit one of them.
const CATEGORY_METRIC: Record<"steps" | "streaks" | "challenges", BadgeRequirementMetric> = {
  steps: "total_steps",
  streaks: "streak_days",
  challenges: "challenges_completed",
};
const CATEGORY_LABEL: Record<keyof typeof CATEGORY_METRIC, string> = {
  steps: "Steps",
  streaks: "Streaks",
  challenges: "Challenges",
};

// Legacy badges created before categories were locked down (retired metrics
// like "early morning sessions") fall back to Steps — picking any category
// in the form corrects it on save.
function metricToCategory(metric: BadgeRequirementMetric): keyof typeof CATEGORY_METRIC {
  const entry = (Object.entries(CATEGORY_METRIC) as [keyof typeof CATEGORY_METRIC, BadgeRequirementMetric][]).find(
    ([, m]) => m === metric
  );
  return entry?.[0] ?? "steps";
}

export interface BadgeFormValues {
  name: string;
  description: string;
  emoji: string;
  requirement_metric: BadgeRequirementMetric;
  requirement_value: number;
  enabled: boolean;
  visible: boolean;
}

const EMPTY: BadgeFormValues = {
  name: "",
  description: "",
  emoji: "🏅",
  requirement_metric: "total_steps",
  requirement_value: 10000,
  enabled: true,
  visible: true,
};

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
    setValues(
      badge
        ? {
            name: badge.name,
            description: badge.description,
            emoji: badge.emoji,
            requirement_metric: badge.requirement_metric,
            requirement_value: badge.requirement_value,
            enabled: badge.enabled,
            visible: badge.visible,
          }
        : EMPTY
    );
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
          <div className="grid grid-cols-[1fr_7rem] gap-3">
            <div className="grid gap-2">
              <Label htmlFor="badge-name">Name</Label>
              <Input id="badge-name" value={values.name} onChange={(e) => setValues({ ...values, name: e.target.value })} autoFocus />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="badge-emoji">Emoji</Label>
              <div className="flex gap-1.5">
                <EmojiPickerPopover value={values.emoji} onSelect={(emoji) => setValues({ ...values, emoji })} />
                <Input
                  id="badge-emoji"
                  value={values.emoji}
                  onChange={(e) => setValues({ ...values, emoji: e.target.value })}
                  className="min-w-0 px-2 text-center"
                />
              </div>
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
          <div className="grid grid-cols-[1fr_8rem] gap-3">
            <div className="grid gap-2">
              <Label htmlFor="badge-category">Category</Label>
              <Select
                value={metricToCategory(values.requirement_metric)}
                onValueChange={(v) => v && setValues({ ...values, requirement_metric: CATEGORY_METRIC[v as keyof typeof CATEGORY_METRIC] })}
              >
                <SelectTrigger id="badge-category"><SelectValue>{CATEGORY_LABEL[metricToCategory(values.requirement_metric)]}</SelectValue></SelectTrigger>
                <SelectContent>
                  {(Object.keys(CATEGORY_LABEL) as (keyof typeof CATEGORY_LABEL)[]).map((cat) => (
                    <SelectItem key={cat} value={cat}>
                      {CATEGORY_LABEL[cat]}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="grid gap-2">
              <Label htmlFor="badge-value">Threshold</Label>
              <Input
                id="badge-value"
                type="number"
                value={values.requirement_value}
                onChange={(e) => setValues({ ...values, requirement_value: Number(e.target.value) })}
              />
            </div>
          </div>
          <p className="text-xs text-muted-foreground">
            Raising this later (e.g. &quot;100k Steps&quot; → &quot;150k Steps&quot;) takes effect immediately, no app
            update needed. Awarding a badge to a specific user is still done manually from their profile.
          </p>
          <div className="flex items-center justify-between rounded-md border border-border p-3">
            <div>
              <p className="text-sm font-medium text-foreground">Enabled</p>
              <p className="text-xs text-muted-foreground">Whether this badge can currently be earned at all.</p>
            </div>
            <Switch checked={values.enabled} onCheckedChange={(v) => setValues({ ...values, enabled: !!v })} />
          </div>
          <div className="flex items-center justify-between rounded-md border border-border p-3">
            <div>
              <p className="text-sm font-medium text-foreground">Visible</p>
              <p className="text-xs text-muted-foreground">Shown to users as a locked/upcoming goal before they earn it.</p>
            </div>
            <Switch checked={values.visible} onCheckedChange={(v) => setValues({ ...values, visible: !!v })} />
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
