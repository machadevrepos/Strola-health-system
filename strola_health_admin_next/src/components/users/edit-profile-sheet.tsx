"use client";

import * as React from "react";
import { CircleNotch } from "@phosphor-icons/react";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
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
import { titleCase } from "@/lib/format";
import type { Gender, UnitSystem, UserProfile } from "@/lib/types";

export interface ProfileEdits {
  name: string;
  username: string;
  bio: string;
  location: string;
  height_cm: number;
  weight_kg: number | null;
  gender: Gender;
  daily_goal_steps: number;
  units: UnitSystem;
}

export function EditProfileSheet({
  user,
  open,
  onOpenChange,
  onSave,
}: {
  user: UserProfile;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSave: (edits: ProfileEdits) => void | Promise<void>;
}) {
  const [edits, setEdits] = React.useState<ProfileEdits>(() => fromUser(user));
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (open) setEdits(fromUser(user));
  }, [open, user]);

  async function handleSave() {
    setSubmitting(true);
    try {
      await onSave(edits);
      onOpenChange(false);
    } finally {
      setSubmitting(false);
    }
  }

  function fromUser(u: UserProfile): ProfileEdits {
    return {
      name: u.name,
      username: u.username,
      bio: u.bio ?? "",
      location: u.location ?? "",
      height_cm: u.height_cm,
      weight_kg: u.weight_kg,
      gender: u.gender,
      daily_goal_steps: u.daily_goal_steps,
      units: u.units,
    };
  }

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent className="flex flex-col gap-0 p-0">
        <SheetHeader className="border-b border-border p-4">
          <SheetTitle>Edit profile</SheetTitle>
          <SheetDescription>
            Admin override — same fields the user edits themselves, for correcting data on their behalf.
          </SheetDescription>
        </SheetHeader>

        <div className="flex-1 space-y-4 overflow-y-auto p-4">
          <div className="grid gap-2">
            <Label htmlFor="edit-name">Name</Label>
            <Input id="edit-name" value={edits.name} onChange={(e) => setEdits({ ...edits, name: e.target.value })} />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="edit-username">Username</Label>
            <Input
              id="edit-username"
              value={edits.username}
              onChange={(e) => setEdits({ ...edits, username: e.target.value })}
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="edit-bio">Bio</Label>
            <Textarea
              id="edit-bio"
              rows={2}
              value={edits.bio}
              onChange={(e) => setEdits({ ...edits, bio: e.target.value })}
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="edit-location">Location</Label>
            <Input
              id="edit-location"
              value={edits.location}
              onChange={(e) => setEdits({ ...edits, location: e.target.value })}
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="edit-height">Height (cm)</Label>
              <Input
                id="edit-height"
                type="number"
                value={edits.height_cm}
                onChange={(e) => setEdits({ ...edits, height_cm: Number(e.target.value) })}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="edit-weight">Weight (kg)</Label>
              <Input
                id="edit-weight"
                type="number"
                value={edits.weight_kg ?? ""}
                onChange={(e) => setEdits({ ...edits, weight_kg: e.target.value ? Number(e.target.value) : null })}
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="edit-gender">Gender</Label>
              <Select value={edits.gender} onValueChange={(v) => setEdits({ ...edits, gender: v as Gender })}>
                <SelectTrigger id="edit-gender"><SelectValue>{titleCase(edits.gender)}</SelectValue></SelectTrigger>
                <SelectContent>
                  <SelectItem value="female">Female</SelectItem>
                  <SelectItem value="male">Male</SelectItem>
                  <SelectItem value="other">Other</SelectItem>
                  <SelectItem value="prefer_not_to_say">Prefer not to say</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="grid gap-2">
              <Label htmlFor="edit-units">Units</Label>
              <Select value={edits.units} onValueChange={(v) => setEdits({ ...edits, units: v as UnitSystem })}>
                <SelectTrigger id="edit-units"><SelectValue>{titleCase(edits.units)}</SelectValue></SelectTrigger>
                <SelectContent>
                  <SelectItem value="metric">Metric</SelectItem>
                  <SelectItem value="imperial">Imperial</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="edit-goal">Daily step goal</Label>
            <Input
              id="edit-goal"
              type="number"
              step={500}
              value={edits.daily_goal_steps}
              onChange={(e) => setEdits({ ...edits, daily_goal_steps: Number(e.target.value) })}
            />
          </div>
        </div>

        <SheetFooter className="border-t border-border p-4">
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button onClick={handleSave} disabled={submitting}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Save changes
          </Button>
        </SheetFooter>
      </SheetContent>
    </Sheet>
  );
}
