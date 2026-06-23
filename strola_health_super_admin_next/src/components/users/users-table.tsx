"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import {
  MagnifyingGlass,
  DotsThree,
  Prohibit,
  CheckCircle,
  Crown,
  DownloadSimple,
  CaretLeft,
  CaretRight,
  X,
  CircleNotch,
} from "@phosphor-icons/react";
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
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { AccountStatusBadge, RoleBadge, SubscriptionBadge } from "@/components/shell/status-badges";
import { BanUserDialog } from "@/components/users/ban-user-dialog";
import { GrantPremiumConfirmDialog, type PendingGrant } from "@/components/users/grant-premium-confirm-dialog";
import { formatDate, initials } from "@/lib/format";
import { hasAdminGrantedPremium, userDisplayName as displayName } from "@/lib/data/queries";
import { banUser, grantPremium, revokePremium, unbanUser } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { logAction } from "@/lib/audit-log-store";
import type { UserProfile } from "@/lib/types";

type RoleFilter = "all" | "user" | "admin" | "super_admin";
type StatusFilter = "all" | "active" | "banned" | "deleted";

// Explicit labels rather than relying on Select.Value's auto-resolution from
// registered items — that depends on internal store timing that proved
// unreliable for the role select elsewhere (see RoleChangeDialog history).
const ROLE_FILTER_LABEL: Record<RoleFilter, string> = {
  all: "All roles",
  user: "User",
  admin: "Admin",
  super_admin: "Super admin",
};
const STATUS_FILTER_LABEL: Record<StatusFilter, string> = {
  all: "All statuses",
  active: "Active",
  banned: "Banned",
  deleted: "Deleted",
};

const PAGE_SIZE = 10;

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

function exportCsv(users: UserProfile[]) {
  const headers = ["id", "name", "username", "email", "role", "status", "subscription_tier", "daily_goal_steps", "created_at"];
  const rows = users.map((u) => [
    u.id,
    displayName(u),
    u.username,
    u.email ?? "",
    u.role,
    u.deleted ? "deleted" : u.banned ? "banned" : "active",
    u.subscription.tier,
    String(u.daily_goal_steps),
    u.created_at,
  ]);
  const csv = [headers, ...rows]
    .map((row) => row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(","))
    .join("\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `strolla-users-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

export function UsersTable({ users: initialUsers }: { users: UserProfile[] }) {
  const router = useRouter();
  const [users, setUsers] = React.useState(initialUsers);
  const [query, setQuery] = React.useState("");
  const [role, setRole] = React.useState<RoleFilter>("all");
  const [status, setStatus] = React.useState<StatusFilter>("all");
  const [banTarget, setBanTarget] = React.useState<UserProfile | null>(null);
  const [pendingGrant, setPendingGrant] = React.useState<PendingGrant | null>(null);
  const [grantTargetId, setGrantTargetId] = React.useState<string | null>(null);
  const [selected, setSelected] = React.useState<Set<string>>(new Set());
  const [page, setPage] = React.useState(0);
  const [bulkBanOpen, setBulkBanOpen] = React.useState(false);
  const [bulkBanning, setBulkBanning] = React.useState(false);

  React.useEffect(() => setUsers(initialUsers), [initialUsers]);

  const filtered = users.filter((u) => {
    if (role !== "all" && u.role !== role) return false;
    if (status === "active" && (u.banned || u.deleted)) return false;
    if (status === "banned" && !u.banned) return false;
    if (status === "deleted" && !u.deleted) return false;
    if (query) {
      const q = query.toLowerCase();
      const haystack = `${u.name} ${u.username} ${u.email ?? ""}`.toLowerCase();
      if (!haystack.includes(q)) return false;
    }
    return true;
  });

  const pageCount = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const currentPage = Math.min(page, pageCount - 1);
  const pageUsers = filtered.slice(currentPage * PAGE_SIZE, currentPage * PAGE_SIZE + PAGE_SIZE);

  React.useEffect(() => {
    setPage(0);
  }, [query, role, status]);

  function toggleSelected(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  function toggleSelectPage() {
    const pageIds = pageUsers.map((u) => u.id);
    const allSelected = pageIds.every((id) => selected.has(id));
    setSelected((prev) => {
      const next = new Set(prev);
      if (allSelected) pageIds.forEach((id) => next.delete(id));
      else pageIds.forEach((id) => next.add(id));
      return next;
    });
  }

  async function unban(user: UserProfile) {
    try {
      await unbanUser(user.id);
      setUsers((prev) => prev.map((u) => (u.id === user.id ? { ...u, banned: false, ban_reason: null } : u)));
      toast.success(`${displayName(user)} unbanned`);
      logAction("Unbanned user", displayName(user));
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't unban this user"));
    }
  }

  function requestGrantPremium(user: UserProfile) {
    const until = new Date();
    until.setDate(until.getDate() + 30);
    setPendingGrant({ userName: displayName(user), until, reason: "admin_grant" });
    setGrantTargetId(user.id);
  }

  async function confirmGrantPremium() {
    if (!pendingGrant || !grantTargetId) return;
    try {
      await grantPremium(grantTargetId, pendingGrant.until.toISOString(), pendingGrant.reason);
      setUsers((prev) =>
        prev.map((u) =>
          u.id === grantTargetId
            ? { ...u, subscription: { ...u.subscription, comp_until: pendingGrant.until.toISOString(), comp_reason: pendingGrant.reason } }
            : u
        )
      );
      toast.success(`Premium granted to ${pendingGrant.userName} until ${formatDate(pendingGrant.until.toISOString())}`);
      logAction("Granted 30 days premium", pendingGrant.userName);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't grant premium"));
    } finally {
      setPendingGrant(null);
      setGrantTargetId(null);
    }
  }

  async function terminatePremium(user: UserProfile) {
    try {
      await revokePremium(user.id);
      setUsers((prev) =>
        prev.map((u) =>
          u.id === user.id ? { ...u, subscription: { ...u.subscription, comp_until: null, comp_reason: null } } : u
        )
      );
      toast.success(`Premium terminated for ${displayName(user)}`);
      logAction("Terminated premium", displayName(user));
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't revoke premium"));
    }
  }

  const bulkBanTargets = users.filter((u) => selected.has(u.id) && !u.banned && !u.deleted);

  async function confirmBulkBan() {
    setBulkBanning(true);
    try {
      const targets = bulkBanTargets;
      const results = await Promise.allSettled(targets.map((u) => banUser(u.id, "Bulk action from admin panel")));
      const succeededIds = new Set(targets.filter((_, i) => results[i].status === "fulfilled").map((u) => u.id));
      setUsers((prev) => prev.map((u) => (succeededIds.has(u.id) ? { ...u, banned: true, ban_reason: "Bulk action from admin panel" } : u)));
      const failedCount = targets.length - succeededIds.size;
      if (succeededIds.size > 0) {
        toast.success(`Banned ${succeededIds.size} user${succeededIds.size === 1 ? "" : "s"}`);
        logAction(`Bulk-banned ${succeededIds.size} users`, targets.filter((u) => succeededIds.has(u.id)).map((u) => displayName(u)).join(", "));
      }
      if (failedCount > 0) toast.error(`${failedCount} ban${failedCount === 1 ? "" : "s"} failed`);
      setSelected(new Set());
    } finally {
      setBulkBanning(false);
      setBulkBanOpen(false);
    }
  }

  function exportSelectionOrFiltered() {
    const set = selected.size > 0 ? users.filter((u) => selected.has(u.id)) : filtered;
    exportCsv(set);
    toast.success(`Exported ${set.length} user${set.length === 1 ? "" : "s"} to CSV`);
    logAction("Exported users to CSV", `${set.length} rows`);
  }

  return (
    <div>
      <div className="mb-3 flex flex-wrap items-center gap-2">
        <div className="relative flex-1 min-w-[220px] max-w-sm">
          <MagnifyingGlass size={14} className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
          <Input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search name, username, or email"
            className="pl-8"
          />
        </div>
        <Select value={role} onValueChange={(v) => v && setRole(v as RoleFilter)}>
          <SelectTrigger className="w-40"><SelectValue>{ROLE_FILTER_LABEL[role]}</SelectValue></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All roles</SelectItem>
            <SelectItem value="user">User</SelectItem>
            <SelectItem value="admin">Admin</SelectItem>
            <SelectItem value="super_admin">Super admin</SelectItem>
          </SelectContent>
        </Select>
        <Select value={status} onValueChange={(v) => v && setStatus(v as StatusFilter)}>
          <SelectTrigger className="w-40"><SelectValue>{STATUS_FILTER_LABEL[status]}</SelectValue></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All statuses</SelectItem>
            <SelectItem value="active">Active</SelectItem>
            <SelectItem value="banned">Banned</SelectItem>
            <SelectItem value="deleted">Deleted</SelectItem>
          </SelectContent>
        </Select>
        <Button variant="outline" size="sm" className="ml-auto" onClick={exportSelectionOrFiltered}>
          <DownloadSimple size={14} /> Export CSV
        </Button>
      </div>

      {selected.size > 0 && (
        <div className="mb-3 flex items-center gap-3 rounded-md border border-border bg-muted px-3 py-2">
          <span className="text-sm font-medium text-foreground">{selected.size} selected</span>
          <Button variant="outline" size="sm" onClick={() => setBulkBanOpen(true)}>
            <Prohibit size={13} /> Ban selected
          </Button>
          <Button variant="ghost" size="sm" onClick={() => setSelected(new Set())} className="ml-auto">
            <X size={13} /> Clear
          </Button>
        </div>
      )}

      <div className="overflow-hidden rounded-lg border border-border">
        <Table>
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead className="w-10">
                <Checkbox
                  checked={pageUsers.length > 0 && pageUsers.every((u) => selected.has(u.id))}
                  onCheckedChange={toggleSelectPage}
                  aria-label="Select all on this page"
                />
              </TableHead>
              <TableHead>User</TableHead>
              <TableHead>Role</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Subscription</TableHead>
              <TableHead>Daily goal</TableHead>
              <TableHead>Joined</TableHead>
              <TableHead className="w-10" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {pageUsers.length === 0 && (
              <TableRow>
                <TableCell colSpan={8} className="h-32 text-center text-sm text-muted-foreground">
                  No users match these filters.
                </TableCell>
              </TableRow>
            )}
            {pageUsers.map((u) => (
              <TableRow key={u.id} className="cursor-pointer" onClick={() => router.push(`/users/${u.id}`)}>
                <TableCell onClick={(e) => e.stopPropagation()}>
                  <Checkbox checked={selected.has(u.id)} onCheckedChange={() => toggleSelected(u.id)} aria-label={`Select ${displayName(u)}`} />
                </TableCell>
                <TableCell>
                  <div className="flex items-center gap-2.5">
                    <Avatar className="size-8">
                      <AvatarFallback className="text-xs">{initials(displayName(u))}</AvatarFallback>
                    </Avatar>
                    <div className="min-w-0">
                      <p className="truncate text-sm font-medium text-foreground">{displayName(u)}</p>
                      <p className="truncate text-xs text-muted-foreground">{u.email ?? `@${u.username}`}</p>
                    </div>
                  </div>
                </TableCell>
                <TableCell><RoleBadge role={u.role} /></TableCell>
                <TableCell><AccountStatusBadge user={u} /></TableCell>
                <TableCell><SubscriptionBadge subscription={u.subscription} /></TableCell>
                <TableCell className="font-mono text-sm text-muted-foreground">
                  {u.daily_goal_steps.toLocaleString("en-GB")}
                </TableCell>
                <TableCell className="text-sm text-muted-foreground">{formatDate(u.created_at)}</TableCell>
                <TableCell onClick={(e) => e.stopPropagation()}>
                  <DropdownMenu>
                    <DropdownMenuTrigger
                      render={
                        <button
                          type="button"
                          className="rounded-md p-1.5 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
                          aria-label={`Actions for ${displayName(u)}`}
                        />
                      }
                    >
                      <DotsThree size={18} weight="bold" />
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem render={<Link href={`/users/${u.id}`} />}>View profile</DropdownMenuItem>
                      {!u.deleted && !u.banned && (
                        <DropdownMenuItem variant="destructive" onClick={() => setBanTarget(u)}>
                          <Prohibit size={14} /> Ban user
                        </DropdownMenuItem>
                      )}
                      {!u.deleted && u.banned && (
                        <DropdownMenuItem onClick={() => unban(u)}>
                          <CheckCircle size={14} /> Unban user
                        </DropdownMenuItem>
                      )}
                      {!u.deleted && (
                        hasAdminGrantedPremium(u) ? (
                          <DropdownMenuItem onClick={() => terminatePremium(u)}>
                            <X size={14} /> Terminate premium
                          </DropdownMenuItem>
                        ) : (
                          <DropdownMenuItem onClick={() => requestGrantPremium(u)}>
                            <Crown size={14} /> Grant 30 days premium
                          </DropdownMenuItem>
                        )
                      )}
                    </DropdownMenuContent>
                  </DropdownMenu>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      <div className="mt-3 flex items-center justify-between">
        <span className="text-xs text-muted-foreground">
          {filtered.length === 0 ? "0" : `${currentPage * PAGE_SIZE + 1}-${Math.min(filtered.length, (currentPage + 1) * PAGE_SIZE)}`} of {filtered.length}
        </span>
        <div className="flex items-center gap-1">
          <Button variant="outline" size="icon-sm" disabled={currentPage === 0} onClick={() => setPage((p) => p - 1)} aria-label="Previous page">
            <CaretLeft size={14} />
          </Button>
          <span className="px-2 text-xs text-muted-foreground">
            Page {currentPage + 1} of {pageCount}
          </span>
          <Button variant="outline" size="icon-sm" disabled={currentPage >= pageCount - 1} onClick={() => setPage((p) => p + 1)} aria-label="Next page">
            <CaretRight size={14} />
          </Button>
        </div>
      </div>

      <BanUserDialog
        user={banTarget}
        onOpenChange={(open) => !open && setBanTarget(null)}
        onConfirm={async (reason) => {
          if (!banTarget) return;
          try {
            await banUser(banTarget.id, reason);
            setUsers((prev) => prev.map((u) => (u.id === banTarget.id ? { ...u, banned: true, ban_reason: reason } : u)));
            toast.success(`${displayName(banTarget)} banned`);
            logAction("Banned user", `${displayName(banTarget)} — ${reason}`);
          } catch (err) {
            toast.error(apiErrorMessage(err, "Couldn't ban this user"));
          } finally {
            setBanTarget(null);
          }
        }}
      />

      <GrantPremiumConfirmDialog
        pending={pendingGrant}
        onOpenChange={(open) => {
          if (!open) {
            setPendingGrant(null);
            setGrantTargetId(null);
          }
        }}
        onConfirm={confirmGrantPremium}
      />

      <AlertDialog open={bulkBanOpen} onOpenChange={(open) => !bulkBanning && setBulkBanOpen(open)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              Ban {bulkBanTargets.length} user{bulkBanTargets.length === 1 ? "" : "s"}?
            </AlertDialogTitle>
            <AlertDialogDescription>
              They&apos;ll all be signed out immediately and blocked from signing back in, with the reason "Bulk
              action from admin panel". This is reversible one at a time from each profile.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={bulkBanning}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmBulkBan} disabled={bulkBanning} className="bg-destructive text-white hover:bg-destructive/90">
              {bulkBanning && <CircleNotch size={14} className="animate-spin" />}
              Ban {bulkBanTargets.length} user{bulkBanTargets.length === 1 ? "" : "s"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
