"use client";

import * as React from "react";
import { toast } from "sonner";
import { Plus, Trash, Star } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
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
import { CircleNotch } from "@phosphor-icons/react";
import { createBetaOverride, deleteBetaOverride } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { useAuth } from "@/lib/auth-context";
import { logAction } from "@/lib/audit-log-store";
import { findUserById, userDisplayName } from "@/lib/data/queries";
import { formatDate } from "@/lib/format";
import type { BetaOverride, FeatureFlag, UserProfile } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

const TARGET_TYPE_LABEL: Record<BetaOverride["target_type"], string> = {
  user_id: "Specific user",
  email: "Specific email",
  ambassador: "All ambassadors",
};

export function BetaTestingPanel({
  overrides: initialOverrides,
  flags,
  users,
}: {
  overrides: BetaOverride[];
  flags: FeatureFlag[];
  users: UserProfile[];
}) {
  const { user: currentUser } = useAuth();
  const [overrides, setOverrides] = React.useState(initialOverrides);
  const [createOpen, setCreateOpen] = React.useState(false);
  const [featureKey, setFeatureKey] = React.useState(flags[0]?.key ?? "");
  const [targetType, setTargetType] = React.useState<BetaOverride["target_type"]>("user_id");
  const [targetValue, setTargetValue] = React.useState("");
  const [creating, setCreating] = React.useState(false);
  const [deleteTarget, setDeleteTarget] = React.useState<BetaOverride | null>(null);
  const [deleting, setDeleting] = React.useState(false);

  const ambassadors = users.filter((u) => u.is_ambassador);
  const promotableUsers = users.filter((u) => u.role === "user" && !u.deleted);

  async function create() {
    if (!featureKey || (targetType !== "ambassador" && !targetValue.trim())) return;
    setCreating(true);
    try {
      const created = await createBetaOverride({
        feature_key: featureKey,
        target_type: targetType,
        target_value: targetValue.trim(),
        created_by: currentUser?.uid ?? null,
      });
      setOverrides((prev) => [created, ...prev]);
      toast.success("Beta access granted");
      logAction("Granted beta access", `${featureKey} → ${TARGET_TYPE_LABEL[targetType]}`);
      setTargetValue("");
      setCreateOpen(false);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't grant beta access"));
    } finally {
      setCreating(false);
    }
  }

  async function confirmDelete() {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await deleteBetaOverride(deleteTarget.id);
      setOverrides((prev) => prev.filter((o) => o.id !== deleteTarget.id));
      toast.success("Beta access removed");
      logAction("Removed beta access", deleteTarget.feature_key);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't remove beta access"));
    } finally {
      setDeleting(false);
      setDeleteTarget(null);
    }
  }

  return (
    <div>
      <div className="mb-3 flex items-center justify-between">
        <div>
          <h3 className="text-sm font-medium text-foreground">Beta access overrides</h3>
          <p className="text-xs text-muted-foreground">
            Turn a feature on for one user, one email, or every ambassador — without changing the flag everyone else
            sees. {ambassadors.length} ambassador{ambassadors.length === 1 ? "" : "s"} right now.
          </p>
        </div>
        <Button size="sm" onClick={() => setCreateOpen(true)}>
          <Plus size={14} /> Grant access
        </Button>
      </div>

      <div className="space-y-2">
        {overrides.length === 0 && <p className="py-8 text-center text-sm text-muted-foreground">No beta overrides yet.</p>}
        {overrides.map((o) => (
          <Card key={o.id} className="border-border shadow-none">
            <CardContent className="flex items-center justify-between gap-3 py-3">
              <div>
                <div className="flex items-center gap-2">
                  <span className="font-mono text-sm font-medium text-foreground">{o.feature_key}</span>
                  <Badge variant="outline" className="text-[11px]">{TARGET_TYPE_LABEL[o.target_type]}</Badge>
                </div>
                <p className="mt-1 text-xs text-muted-foreground">
                  {o.target_type === "user_id" && userDisplayName(findUserById(users, o.target_value))}
                  {o.target_type === "email" && o.target_value}
                  {o.target_type === "ambassador" && `Applies to all ${ambassadors.length} ambassadors`}
                  {" · granted "}
                  {formatDate(o.created_at)}
                </p>
              </div>
              <Button variant="ghost" size="icon-sm" aria-label="Remove override" onClick={() => setDeleteTarget(o)}>
                <Trash size={14} />
              </Button>
            </CardContent>
          </Card>
        ))}
      </div>

      <Dialog open={createOpen} onOpenChange={setCreateOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Grant beta access</DialogTitle>
            <DialogDescription>Turns a feature on for this target only — everyone else keeps whatever the feature flag already says.</DialogDescription>
          </DialogHeader>
          <div className="grid gap-3">
            <div className="grid gap-2">
              <Label htmlFor="beta-feature">Feature</Label>
              <Select value={featureKey} onValueChange={(v) => v && setFeatureKey(v)}>
                <SelectTrigger id="beta-feature"><SelectValue>{featureKey}</SelectValue></SelectTrigger>
                <SelectContent>
                  {flags.map((f) => (
                    <SelectItem key={f.key} value={f.key}>
                      {f.key}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="grid gap-2">
              <Label htmlFor="beta-target-type">Grant to</Label>
              <Select value={targetType} onValueChange={(v) => v && setTargetType(v as BetaOverride["target_type"])}>
                <SelectTrigger id="beta-target-type"><SelectValue>{TARGET_TYPE_LABEL[targetType]}</SelectValue></SelectTrigger>
                <SelectContent>
                  <SelectItem value="user_id">Specific user</SelectItem>
                  <SelectItem value="email">Specific email</SelectItem>
                  <SelectItem value="ambassador">
                    <span className="inline-flex items-center gap-1"><Star size={12} /> All ambassadors</span>
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>
            {targetType === "user_id" && (
              <div className="grid gap-2">
                <Label htmlFor="beta-user">User</Label>
                <Select value={targetValue} onValueChange={(v) => v && setTargetValue(v)}>
                  <SelectTrigger id="beta-user">
                    <SelectValue placeholder="Choose a user">
                      {targetValue ? userDisplayName(findUserById(users, targetValue)) : "Choose a user"}
                    </SelectValue>
                  </SelectTrigger>
                  <SelectContent>
                    {promotableUsers.map((u) => (
                      <SelectItem key={u.id} value={u.id}>
                        {userDisplayName(u)} — {u.email ?? `@${u.username}`}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            )}
            {targetType === "email" && (
              <div className="grid gap-2">
                <Label htmlFor="beta-email">Email</Label>
                <Input id="beta-email" type="email" value={targetValue} onChange={(e) => setTargetValue(e.target.value)} placeholder="beta.tester@example.com" />
              </div>
            )}
            {targetType === "ambassador" && (
              <p className="text-xs text-muted-foreground">
                Applies immediately to all {ambassadors.length} current ambassadors — and to anyone marked an
                ambassador afterward, without a new override.
              </p>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setCreateOpen(false)} disabled={creating}>
              Cancel
            </Button>
            <Button disabled={!featureKey || (targetType !== "ambassador" && !targetValue.trim()) || creating} onClick={create}>
              Grant access
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AlertDialog open={!!deleteTarget} onOpenChange={(open) => !open && setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Remove this beta override?</AlertDialogTitle>
            <AlertDialogDescription>The target reverts to whatever the global feature flag already says.</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleting}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} disabled={deleting} className="bg-destructive text-white hover:bg-destructive/90">
              {deleting && <CircleNotch size={14} className="animate-spin" />}
              Remove
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
