"use client";

import * as React from "react";
import { CircleNotch, MagnifyingGlass } from "@phosphor-icons/react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { initials, ROLE_LABEL } from "@/lib/format";
import { userDisplayName } from "@/lib/data/queries";
import type { Role, UserProfile } from "@/lib/types";

type StaffRole = Extract<Role, "admin" | "super_admin">;

export function PromoteStaffDialog({
  open,
  onOpenChange,
  candidates,
  onPromote,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  candidates: UserProfile[];
  onPromote: (user: UserProfile, role: StaffRole) => void | Promise<void>;
}) {
  const [query, setQuery] = React.useState("");
  const [selected, setSelected] = React.useState<UserProfile | null>(null);
  const [role, setRole] = React.useState<StaffRole>("admin");
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (!open) {
      setQuery("");
      setSelected(null);
      setRole("admin");
    }
  }, [open]);

  async function handlePromote() {
    if (!selected) return;
    setSubmitting(true);
    try {
      await onPromote(selected, role);
    } finally {
      setSubmitting(false);
    }
  }

  const results = query.trim()
    ? candidates
        .filter((u) => `${userDisplayName(u)} ${u.email ?? ""} ${u.username}`.toLowerCase().includes(query.toLowerCase()))
        .slice(0, 6)
    : [];

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Promote a user to staff</DialogTitle>
          <DialogDescription>
            Search for an existing regular user, then choose the role to grant them. Banned and deleted accounts
            can&apos;t be promoted.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-3">
          {selected ? (
            <div className="flex items-center justify-between rounded-md border border-border p-2.5">
              <div className="flex items-center gap-2.5">
                <Avatar className="size-8">
                  <AvatarFallback className="text-xs">{initials(userDisplayName(selected))}</AvatarFallback>
                </Avatar>
                <div>
                  <p className="text-sm font-medium text-foreground">{userDisplayName(selected)}</p>
                  <p className="text-xs text-muted-foreground">{selected.email}</p>
                </div>
              </div>
              <Button variant="ghost" size="sm" onClick={() => setSelected(null)}>
                Change
              </Button>
            </div>
          ) : (
            <div className="space-y-2">
              <div className="relative">
                <MagnifyingGlass size={14} className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
                <Input
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder="Search name, username, or email"
                  className="pl-8"
                  autoFocus
                />
              </div>
              {results.length > 0 && (
                <div className="max-h-48 space-y-0.5 overflow-y-auto">
                  {results.map((u) => (
                    <button
                      key={u.id}
                      type="button"
                      onClick={() => setSelected(u)}
                      className="flex w-full items-center gap-2.5 rounded-md p-2 text-left text-sm hover:bg-muted"
                    >
                      <Avatar className="size-7">
                        <AvatarFallback className="text-xs">{initials(userDisplayName(u))}</AvatarFallback>
                      </Avatar>
                      <div className="min-w-0 flex-1">
                        <p className="truncate font-medium text-foreground">{userDisplayName(u)}</p>
                        <p className="truncate text-xs text-muted-foreground">{u.email}</p>
                      </div>
                    </button>
                  ))}
                </div>
              )}
              {query.trim() && results.length === 0 && (
                <p className="px-1 text-sm text-muted-foreground">No matching users.</p>
              )}
            </div>
          )}

          <div className="grid gap-2">
            <span className="text-sm text-foreground">Grant role</span>
            <Select value={role} onValueChange={(v) => v && setRole(v as StaffRole)}>
              <SelectTrigger><SelectValue>{ROLE_LABEL[role]}</SelectValue></SelectTrigger>
              <SelectContent>
                <SelectItem value="admin">{ROLE_LABEL.admin}</SelectItem>
                <SelectItem value="super_admin">{ROLE_LABEL.super_admin}</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button disabled={!selected || submitting} onClick={handlePromote}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Promote to {ROLE_LABEL[role]}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
