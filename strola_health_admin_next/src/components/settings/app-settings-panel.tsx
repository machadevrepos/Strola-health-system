"use client";

import * as React from "react";
import { toast } from "sonner";
import { CircleNotch, SignOut, WarningCircle } from "@phosphor-icons/react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { BarList } from "@/components/charts/bar-list";
import { forceLogoutAllUsers, updateAppSettings } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { logAction } from "@/lib/audit-log-store";
import { appVersionDistribution, usersBelowVersion } from "@/lib/data/queries";
import { formatNumber, formatRelative } from "@/lib/format";
import type { AppSettings, PrivacySettings, UserProfile } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

const PRIVACY_LABEL: [keyof PrivacySettings, string][] = [
  ["public_profile", "Public profile"],
  ["share_activity", "Share activity"],
  ["show_in_leaderboards", "Show in leaderboards"],
  ["allow_friend_requests", "Allow friend requests"],
  ["hide_activity_data", "Hide activity data"],
  ["hide_achievements", "Hide achievements"],
  ["hide_recent_activity", "Hide recent activity"],
];

export function AppSettingsPanel({ settings: initialSettings, users }: { settings: AppSettings; users: UserProfile[] }) {
  const [settings, setSettings] = React.useState(initialSettings);
  const [form, setForm] = React.useState(initialSettings);
  const [saving, setSaving] = React.useState(false);
  const [forceLogoutOpen, setForceLogoutOpen] = React.useState(false);
  const [forceLoggingOut, setForceLoggingOut] = React.useState(false);

  React.useEffect(() => {
    setSettings(initialSettings);
    setForm(initialSettings);
  }, [initialSettings]);

  const dirty = JSON.stringify(form) !== JSON.stringify(settings);

  function field<K extends keyof AppSettings>(key: K, value: AppSettings[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  function privacyField(key: keyof PrivacySettings, value: boolean) {
    setForm((prev) => ({ ...prev, default_privacy: { ...prev.default_privacy, [key]: value } }));
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

  async function handleForceLogout() {
    setForceLoggingOut(true);
    try {
      const result = await forceLogoutAllUsers();
      toast.success(`Signed out ${formatNumber(result.loggedOut)} user${result.loggedOut === 1 ? "" : "s"}`);
      logAction("Forced logout for all users", `${result.loggedOut} sessions revoked`);
      setForceLogoutOpen(false);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't force logout"));
    } finally {
      setForceLoggingOut(false);
    }
  }

  const versionShares = appVersionDistribution(users);
  const belowMinimum = form.minimum_required_app_version ? usersBelowVersion(users, form.minimum_required_app_version) : 0;

  return (
    <div className="space-y-4">
      <Card className="border-border shadow-none">
        <CardHeader>
          <CardTitle>Step goals & challenges</CardTitle>
          <CardDescription>Defaults applied to new users and new challenges.</CardDescription>
        </CardHeader>
        <CardContent className="grid grid-cols-1 gap-3 sm:grid-cols-2">
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
        </CardContent>
      </Card>

      <Card className="border-border shadow-none">
        <CardHeader>
          <CardTitle>Premium</CardTitle>
          <CardDescription>Drives the trial length new signups get and the revenue estimates shown on Subscriptions and Analytics.</CardDescription>
        </CardHeader>
        <CardContent className="grid grid-cols-1 gap-3 sm:grid-cols-3">
          <div className="grid gap-2">
            <Label htmlFor="trial-days">Trial length (days)</Label>
            <Input
              id="trial-days"
              type="number"
              value={form.trial_period_days}
              onChange={(e) => field("trial_period_days", Number(e.target.value))}
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="monthly-price">Monthly price (£)</Label>
            <Input
              id="monthly-price"
              type="number"
              step={0.01}
              value={form.premium_monthly_price_gbp}
              onChange={(e) => field("premium_monthly_price_gbp", Number(e.target.value))}
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="annual-price">Annual price (£)</Label>
            <Input
              id="annual-price"
              type="number"
              step={0.01}
              value={form.premium_annual_price_gbp}
              onChange={(e) => field("premium_annual_price_gbp", Number(e.target.value))}
            />
          </div>
        </CardContent>
      </Card>

      <Card className="border-border shadow-none">
        <CardHeader>
          <CardTitle>Default privacy</CardTitle>
          <CardDescription>What a new signup starts with — they can change any of these themselves from Settings &gt; Privacy.</CardDescription>
        </CardHeader>
        <CardContent className="divide-y divide-border">
          {PRIVACY_LABEL.map(([key, label]) => (
            <div key={key} className="flex items-center justify-between py-2.5 first:pt-0 last:pb-0">
              <span className="text-sm text-muted-foreground">{label}</span>
              <Switch checked={form.default_privacy[key]} onCheckedChange={(v) => privacyField(key, !!v)} />
            </div>
          ))}
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

      <Card className="border-border shadow-none">
        <CardHeader>
          <CardTitle>App version</CardTitle>
          <CardDescription>Current install spread, and the minimum build a force-update gate would allow.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <BarList
            items={versionShares.map((v) => ({ label: v.version, value: v.count, displayValue: `${v.pct}%` }))}
          />
          <div className="grid gap-2 border-t border-border pt-4 sm:max-w-xs">
            <Label htmlFor="min-version">Minimum required version</Label>
            <Input
              id="min-version"
              placeholder="e.g. 2.3.0"
              value={form.minimum_required_app_version ?? ""}
              onChange={(e) => field("minimum_required_app_version", e.target.value.trim() || null)}
            />
            <p className="text-xs text-muted-foreground">
              {form.minimum_required_app_version
                ? `${formatNumber(belowMinimum)} user${belowMinimum === 1 ? "" : "s"} below this version would be blocked. No update-gate screen is wired into the client yet — this is the config it would read.`
                : "No minimum enforced — leave blank to disable the update gate."}
            </p>
          </div>
        </CardContent>
      </Card>

      <Card className="border-border shadow-none">
        <CardHeader>
          <CardTitle>Security</CardTitle>
          <CardDescription>For an incident — e.g. a compromised staff account or leaked token.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between gap-3 rounded-md border border-destructive/20 bg-destructive/5 p-3">
            <div>
              <p className="text-sm font-medium text-foreground">Force logout everyone</p>
              <p className="text-xs text-muted-foreground">Signs every user out of every device immediately. They&apos;ll need to sign back in.</p>
            </div>
            <Button variant="destructive" size="sm" onClick={() => setForceLogoutOpen(true)}>
              <SignOut size={14} /> Force logout
            </Button>
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

      <AlertDialog open={forceLogoutOpen} onOpenChange={(open) => !forceLoggingOut && setForceLogoutOpen(open)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle className="flex items-center gap-2">
              <WarningCircle size={18} className="text-destructive" /> Force logout every user?
            </AlertDialogTitle>
            <AlertDialogDescription>
              Every signed-in user is immediately signed out of every device and has to sign back in. Only do this for
              a real security incident.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={forceLoggingOut}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleForceLogout} disabled={forceLoggingOut} className="bg-destructive text-white hover:bg-destructive/90">
              {forceLoggingOut && <CircleNotch size={14} className="animate-spin" />}
              Force logout everyone
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
