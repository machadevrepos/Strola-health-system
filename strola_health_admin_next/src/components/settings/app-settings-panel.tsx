"use client";

import * as React from "react";
import { toast } from "sonner";
import { CircleNotch } from "@phosphor-icons/react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { updateAppSettings } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { logAction } from "@/lib/audit-log-store";
import { formatRelative } from "@/lib/format";
import type { AppSettings } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

export function AppSettingsPanel({ settings: initialSettings }: { settings: AppSettings }) {
  const [settings, setSettings] = React.useState(initialSettings);
  const [form, setForm] = React.useState(initialSettings);
  const [saving, setSaving] = React.useState(false);

  React.useEffect(() => {
    setSettings(initialSettings);
    setForm(initialSettings);
  }, [initialSettings]);

  const dirty = JSON.stringify(form) !== JSON.stringify(settings);

  function field<K extends keyof AppSettings>(key: K, value: AppSettings[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  async function save() {
    setSaving(true);
    try {
      const updated = await updateAppSettings(form);
      setSettings(updated);
      setForm(updated);
      toast.success("App settings saved");
      logAction("Updated app settings", "");
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't save app settings"));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="space-y-4">
      <Card className="border-border shadow-none">
        <CardHeader>
          <CardTitle>Step goals & challenges</CardTitle>
          <CardDescription>Defaults applied to new users and new challenges.</CardDescription>
        </CardHeader>
        <CardContent className="grid grid-cols-1 gap-3 sm:grid-cols-3">
          <div className="grid gap-2">
            <Label htmlFor="default-goal">Default daily goal (steps)</Label>
            <Input
              id="default-goal"
              type="number"
              step={500}
              value={form.default_daily_goal_steps}
              onChange={(e) => field("default_daily_goal_steps", Number(e.target.value))}
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="challenge-duration">Challenge default duration (days)</Label>
            <Input
              id="challenge-duration"
              type="number"
              value={form.challenge_default_duration_days}
              onChange={(e) => field("challenge_default_duration_days", Number(e.target.value))}
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="challenge-goal">Challenge default goal (steps)</Label>
            <Input
              id="challenge-goal"
              type="number"
              step={1000}
              value={form.challenge_default_goal_steps}
              onChange={(e) => field("challenge_default_goal_steps", Number(e.target.value))}
            />
          </div>
        </CardContent>
      </Card>

      <Card className="border-border shadow-none">
        <CardHeader>
          <CardTitle>Notification defaults</CardTitle>
          <CardDescription>What a new user starts with — they can still turn any of these off themselves.</CardDescription>
        </CardHeader>
        <CardContent className="divide-y divide-border">
          {(
            [
              ["notify_goal_reminder_default", "Daily goal reminder"],
              ["notify_streak_default", "Streak milestones"],
              ["notify_challenge_updates_default", "Challenge updates"],
            ] as [keyof AppSettings, string][]
          ).map(([key, label]) => (
            <div key={key} className="flex items-center justify-between py-2.5 first:pt-0 last:pb-0">
              <span className="text-sm text-muted-foreground">{label}</span>
              <Switch checked={form[key] as boolean} onCheckedChange={(v) => field(key, !!v)} />
            </div>
          ))}
        </CardContent>
      </Card>

      <Card className="border-border shadow-none">
        <CardHeader>
          <CardTitle>Limits</CardTitle>
          <CardDescription>Applied to uploads and text fields across the app.</CardDescription>
        </CardHeader>
        <CardContent className="grid grid-cols-1 gap-3 sm:grid-cols-3">
          <div className="grid gap-2">
            <Label htmlFor="max-image">Max image size (MB)</Label>
            <Input
              id="max-image"
              type="number"
              value={form.max_image_size_mb}
              onChange={(e) => field("max_image_size_mb", Number(e.target.value))}
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="max-post">Max post length (characters)</Label>
            <Input
              id="max-post"
              type="number"
              value={form.max_post_length}
              onChange={(e) => field("max_post_length", Number(e.target.value))}
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="max-bio">Max bio length (characters)</Label>
            <Input
              id="max-bio"
              type="number"
              value={form.max_bio_length}
              onChange={(e) => field("max_bio_length", Number(e.target.value))}
            />
          </div>
        </CardContent>
      </Card>

      <div className="flex items-center justify-between">
        <p className="text-xs text-muted-foreground">Last saved {formatRelative(settings.updated_at)}</p>
        <Button size="sm" disabled={!dirty || saving} onClick={save}>
          {saving && <CircleNotch size={14} className="animate-spin" />}
          Save changes
        </Button>
      </div>
    </div>
  );
}
