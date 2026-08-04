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
  Key,
  EnvelopeSimple,
  AppleLogo,
  AndroidLogo,
  Question,
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
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { AccountStatusBadge, RoleBadge, SubscriptionBadge } from "@/components/shell/status-badges";
import { BanUserDialog } from "@/components/users/ban-user-dialog";
import { GrantPremiumConfirmDialog, type PendingGrant } from "@/components/users/grant-premium-confirm-dialog";
import { SendEmailDialog } from "@/components/users/send-email-dialog";
import { formatDate, formatRelative, initials } from "@/lib/format";
import {
  TRACKER_STATUS_LABEL,
  LIFETIME_ISO,
  daysUntilPurge,
  hasAdminGrantedPremium,
  lastActiveMap,
  trackerStatusForUser,
  userDisplayName as displayName,
  type TrackerStatus,
} from "@/lib/data/queries";
import { banUser, grantPremium, resetUserPassword, revokePremium, sendUserEmail, unbanUser } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { logAction } from "@/lib/audit-log-store";
import type { AnalyticsEvent, Device, UserProfile } from "@/lib/types";

type RoleFilter = "all" | "user" | "admin" | "super_admin";
type StatusFilter = "all" | "active" | "banned" | "deleted";
type SubscriptionFilter = "all" | "premium" | "trial" | "free";
type TrackerFilter = "all" | TrackerStatus;
type PlatformFilter = "all" | "ios" | "android";

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
  banned: "Suspended",
  deleted: "Deleted",
};
const SUBSCRIPTION_FILTER_LABEL: Record<SubscriptionFilter, string> = {
  all: "All subscriptions",
  premium: "Premium",
  trial: "Trial",
  free: "Free",
};
const TRACKER_FILTER_LABEL: Record<TrackerFilter, string> = {
  all: "All trackers",
  connected: "Tracker connected",
  never_paired: "Never paired",
  offline: "Tracker offline",
};
const PLATFORM_FILTER_LABEL: Record<PlatformFilter, string> = {
  all: "All platforms",
  ios: "iPhone",
  android: "Android",
};
const TAG_LABEL: Record<string, string> = {
  kickstarter: "Kickstarter",
  beta_tester: "Beta tester",
};

const PAGE_SIZE = 10;
const INACTIVE_THRESHOLD_DAYS = 30;

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

function subscriptionMatches(u: UserProfile, filter: SubscriptionFilter): boolean {
  if (filter === "all") return true;
  if (filter === "trial") return u.subscription.status === "trialing";
  if (filter === "premium") return u.subscription.tier === "premium" && u.subscription.status === "active";
  return u.subscription.tier === "free" && u.subscription.status !== "trialing";
}

function exportCsv(users: UserProfile[], devices: Device[], lastActive: Map<string, string>) {
  const headers = ["id", "name", "username", "email", "role", "status", "subscription_tier", "country", "platform", "tracker_status", "last_active", "tags", "created_at"];
  const rows = users.map((u) => [
    u.id,
    displayName(u),
    u.username,
    u.email ?? "",
    u.role,
    u.deleted ? "deleted" : u.banned ? "suspended" : "active",
    u.subscription.tier,
    u.country ?? "",
    u.platform,
    TRACKER_STATUS_LABEL[trackerStatusForUser(u.id, devices)],
    lastActive.get(u.id) ?? "",
    u.tags.join("; "),
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

export function UsersTable({
  users: initialUsers,
  devices,
  events,
}: {
  users: UserProfile[];
  devices: Device[];
  events: AnalyticsEvent[];
}) {
  const router = useRouter();
  const [users, setUsers] = React.useState(initialUsers);
  const [query, setQuery] = React.useState("");
  const [role, setRole] = React.useState<RoleFilter>("all");
  const [status, setStatus] = React.useState<StatusFilter>("all");
  const [subscriptionFilter, setSubscriptionFilter] = React.useState<SubscriptionFilter>("all");
  const [trackerFilter, setTrackerFilter] = React.useState<TrackerFilter>("all");
  const [platformFilter, setPlatformFilter] = React.useState<PlatformFilter>("all");
  const [countryFilter, setCountryFilter] = React.useState<string>("all");
  const [ambassadorOnly, setAmbassadorOnly] = React.useState(false);
  const [joinedThisWeekOnly, setJoinedThisWeekOnly] = React.useState(false);
  const [inactiveOnly, setInactiveOnly] = React.useState(false);
  const [activeTags, setActiveTags] = React.useState<Set<string>>(new Set());
  const [banTarget, setBanTarget] = React.useState<UserProfile | null>(null);
  const [emailTarget, setEmailTarget] = React.useState<UserProfile | null>(null);
  const [pendingGrant, setPendingGrant] = React.useState<PendingGrant | null>(null);
  const [grantTargetId, setGrantTargetId] = React.useState<string | null>(null);
  const [selected, setSelected] = React.useState<Set<string>>(new Set());
  const [page, setPage] = React.useState(0);
  const [bulkBanOpen, setBulkBanOpen] = React.useState(false);
  const [bulkBanning, setBulkBanning] = React.useState(false);
  const [bulkGrantOpen, setBulkGrantOpen] = React.useState(false);
  const [bulkGranting, setBulkGranting] = React.useState(false);

  React.useEffect(() => setUsers(initialUsers), [initialUsers]);

  const lastActive = React.useMemo(() => lastActiveMap(events), [events]);

  // Anchored to the dataset's own most-recent timestamp, not Date.now() —
  // same frozen-mock-timeline reasoning used throughout the query layer.
  // (Also keeps this memo pure: no wall-clock read during render.)
  const referenceNow = React.useMemo(() => {
    const fromSignups = users.reduce((max, u) => Math.max(max, +new Date(u.created_at)), 0);
    const fromActivity = Array.from(lastActive.values()).reduce((max, iso) => Math.max(max, +new Date(iso)), 0);
    return Math.max(fromSignups, fromActivity);
  }, [users, lastActive]);

  const allTags = React.useMemo(() => {
    const set = new Set<string>();
    for (const u of users) for (const t of u.tags) set.add(t);
    return Array.from(set).sort();
  }, [users]);

  const allCountries = React.useMemo(() => {
    const set = new Set<string>();
    for (const u of users) if (u.country) set.add(u.country);
    return Array.from(set).sort();
  }, [users]);

  const filtered = users.filter((u) => {
    if (role !== "all" && u.role !== role) return false;
    if (status === "active" && (u.banned || u.deleted)) return false;
    if (status === "banned" && !u.banned) return false;
    if (status === "deleted" && !u.deleted) return false;
    if (!subscriptionMatches(u, subscriptionFilter)) return false;
    if (trackerFilter !== "all" && trackerStatusForUser(u.id, devices) !== trackerFilter) return false;
    if (platformFilter !== "all" && u.platform !== platformFilter) return false;
    if (countryFilter !== "all" && u.country !== countryFilter) return false;
    if (ambassadorOnly && !u.is_ambassador) return false;
    if (joinedThisWeekOnly && referenceNow - +new Date(u.created_at) > 7 * 86_400_000) return false;
    if (inactiveOnly) {
      const last = lastActive.get(u.id);
      const idleMs = last ? referenceNow - +new Date(last) : Infinity;
      if (idleMs <= INACTIVE_THRESHOLD_DAYS * 86_400_000) return false;
    }
    if (activeTags.size > 0 && !u.tags.some((t) => activeTags.has(t))) return false;
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
  }, [query, role, status, subscriptionFilter, trackerFilter, platformFilter, countryFilter, ambassadorOnly, joinedThisWeekOnly, inactiveOnly, activeTags]);

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

  function toggleTag(tag: string) {
    setActiveTags((prev) => {
      const next = new Set(prev);
      if (next.has(tag)) next.delete(tag);
      else next.add(tag);
      return next;
    });
  }

  async function unban(user: UserProfile) {
    try {
      await unbanUser(user.id);
      setUsers((prev) => prev.map((u) => (u.id === user.id ? { ...u, banned: false, ban_reason: null } : u)));
      toast.success(`${displayName(user)} unsuspended`);
      logAction("Unsuspended user", displayName(user));
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't unsuspend this user"));
    }
  }

  function requestGrantPremium(user: UserProfile) {
    const until = new Date();
    until.setDate(until.getDate() + 30);
    setPendingGrant({ userName: displayName(user), until, reason: "admin_grant" });
    setGrantTargetId(user.id);
  }

  async function confirmGrantPremium(reason: string) {
    if (!pendingGrant || !grantTargetId) return;
    const untilIso = pendingGrant.until ? pendingGrant.until.toISOString() : LIFETIME_ISO;
    try {
      await grantPremium(grantTargetId, untilIso, reason);
      setUsers((prev) =>
        prev.map((u) => (u.id === grantTargetId ? { ...u, subscription: { ...u.subscription, comp_until: untilIso, comp_reason: reason } } : u))
      );
      toast.success(`Premium granted to ${pendingGrant.userName} until ${formatDate(untilIso)}`);
      logAction("Granted 30 days premium", `${pendingGrant.userName} — ${reason}`);
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

  async function sendPasswordReset(user: UserProfile) {
    try {
      await resetUserPassword(user.id);
      toast.success(`Password reset email sent to ${displayName(user)}`);
      logAction("Sent password reset email", displayName(user));
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't send the reset email"));
    }
  }

  async function sendEmail(values: { subject: string; body: string }) {
    if (!emailTarget) return;
    try {
      await sendUserEmail(emailTarget.id, values);
      toast.success(`Email sent to ${displayName(emailTarget)}`);
      logAction(`Sent email "${values.subject}"`, displayName(emailTarget));
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't send this email"));
    } finally {
      setEmailTarget(null);
    }
  }

  const bulkBanTargets = users.filter((u) => selected.has(u.id) && !u.banned && !u.deleted);
  const bulkGrantTargets = users.filter((u) => selected.has(u.id) && !u.deleted && !hasAdminGrantedPremium(u));

  async function confirmBulkBan() {
    setBulkBanning(true);
    try {
      const targets = bulkBanTargets;
      const results = await Promise.allSettled(targets.map((u) => banUser(u.id, "Bulk action from admin panel")));
      const succeededIds = new Set(targets.filter((_, i) => results[i].status === "fulfilled").map((u) => u.id));
      setUsers((prev) => prev.map((u) => (succeededIds.has(u.id) ? { ...u, banned: true, ban_reason: "Bulk action from admin panel" } : u)));
      const failedCount = targets.length - succeededIds.size;
      if (succeededIds.size > 0) {
        toast.success(`Suspended ${succeededIds.size} user${succeededIds.size === 1 ? "" : "s"}`);
        logAction(`Bulk-suspended ${succeededIds.size} users`, targets.filter((u) => succeededIds.has(u.id)).map((u) => displayName(u)).join(", "));
      }
      if (failedCount > 0) toast.error(`${failedCount} suspension${failedCount === 1 ? "" : "s"} failed`);
      setSelected(new Set());
    } finally {
      setBulkBanning(false);
      setBulkBanOpen(false);
    }
  }

  async function confirmBulkGrant() {
    setBulkGranting(true);
    try {
      const targets = bulkGrantTargets;
      const until = new Date();
      until.setDate(until.getDate() + 30);
      const results = await Promise.allSettled(targets.map((u) => grantPremium(u.id, until.toISOString(), "bulk_grant")));
      const succeededIds = new Set(targets.filter((_, i) => results[i].status === "fulfilled").map((u) => u.id));
      setUsers((prev) =>
        prev.map((u) =>
          succeededIds.has(u.id)
            ? { ...u, subscription: { ...u.subscription, comp_until: until.toISOString(), comp_reason: "bulk_grant" } }
            : u
        )
      );
      const failedCount = targets.length - succeededIds.size;
      if (succeededIds.size > 0) {
        toast.success(`Granted premium to ${succeededIds.size} user${succeededIds.size === 1 ? "" : "s"}`);
        logAction(`Bulk-granted premium to ${succeededIds.size} users`, targets.filter((u) => succeededIds.has(u.id)).map((u) => displayName(u)).join(", "));
      }
      if (failedCount > 0) toast.error(`${failedCount} grant${failedCount === 1 ? "" : "s"} failed`);
      setSelected(new Set());
    } finally {
      setBulkGranting(false);
      setBulkGrantOpen(false);
    }
  }

  function exportSelectionOrFiltered() {
    const set = selected.size > 0 ? users.filter((u) => selected.has(u.id)) : filtered;
    exportCsv(set, devices, lastActive);
    toast.success(`Exported ${set.length} user${set.length === 1 ? "" : "s"} to CSV`);
    logAction("Exported users to CSV", `${set.length} rows`);
  }

  return (
    <div>
      <div className="mb-2 flex flex-wrap items-center gap-2">
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
          <SelectTrigger className="w-36"><SelectValue>{ROLE_FILTER_LABEL[role]}</SelectValue></SelectTrigger>
          <SelectContent>
            {(Object.keys(ROLE_FILTER_LABEL) as RoleFilter[]).map((v) => (
              <SelectItem key={v} value={v}>{ROLE_FILTER_LABEL[v]}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={status} onValueChange={(v) => v && setStatus(v as StatusFilter)}>
          <SelectTrigger className="w-36"><SelectValue>{STATUS_FILTER_LABEL[status]}</SelectValue></SelectTrigger>
          <SelectContent>
            {(Object.keys(STATUS_FILTER_LABEL) as StatusFilter[]).map((v) => (
              <SelectItem key={v} value={v}>{STATUS_FILTER_LABEL[v]}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={subscriptionFilter} onValueChange={(v) => v && setSubscriptionFilter(v as SubscriptionFilter)}>
          <SelectTrigger className="w-40"><SelectValue>{SUBSCRIPTION_FILTER_LABEL[subscriptionFilter]}</SelectValue></SelectTrigger>
          <SelectContent>
            {(Object.keys(SUBSCRIPTION_FILTER_LABEL) as SubscriptionFilter[]).map((v) => (
              <SelectItem key={v} value={v}>{SUBSCRIPTION_FILTER_LABEL[v]}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={trackerFilter} onValueChange={(v) => v && setTrackerFilter(v as TrackerFilter)}>
          <SelectTrigger className="w-40"><SelectValue>{TRACKER_FILTER_LABEL[trackerFilter]}</SelectValue></SelectTrigger>
          <SelectContent>
            {(Object.keys(TRACKER_FILTER_LABEL) as TrackerFilter[]).map((v) => (
              <SelectItem key={v} value={v}>{TRACKER_FILTER_LABEL[v]}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={platformFilter} onValueChange={(v) => v && setPlatformFilter(v as PlatformFilter)}>
          <SelectTrigger className="w-32"><SelectValue>{PLATFORM_FILTER_LABEL[platformFilter]}</SelectValue></SelectTrigger>
          <SelectContent>
            {(Object.keys(PLATFORM_FILTER_LABEL) as PlatformFilter[]).map((v) => (
              <SelectItem key={v} value={v}>{PLATFORM_FILTER_LABEL[v]}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={countryFilter} onValueChange={(v) => v && setCountryFilter(v)}>
          <SelectTrigger className="w-40"><SelectValue>{countryFilter === "all" ? "All countries" : countryFilter}</SelectValue></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All countries</SelectItem>
            {allCountries.map((c) => (
              <SelectItem key={c} value={c}>{c}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Button variant="outline" size="sm" className="ml-auto" onClick={exportSelectionOrFiltered}>
          <DownloadSimple size={14} /> Export CSV
        </Button>
      </div>

      <div className="mb-3 flex flex-wrap items-center gap-1.5">
        <Button
          variant={ambassadorOnly ? "default" : "outline"}
          size="sm"
          onClick={() => setAmbassadorOnly((v) => !v)}
        >
          Ambassador
        </Button>
        <Button
          variant={joinedThisWeekOnly ? "default" : "outline"}
          size="sm"
          onClick={() => setJoinedThisWeekOnly((v) => !v)}
        >
          Joined this week
        </Button>
        <Button variant={inactiveOnly ? "default" : "outline"} size="sm" onClick={() => setInactiveOnly((v) => !v)}>
          Inactive 30+ days
        </Button>
        {allTags.length > 0 && (
          <>
            <span className="mx-1 text-xs text-muted-foreground">Tags:</span>
            {allTags.map((tag) => (
              <Button
                key={tag}
                variant={activeTags.has(tag) ? "default" : "outline"}
                size="sm"
                onClick={() => toggleTag(tag)}
              >
                {TAG_LABEL[tag] ?? tag}
              </Button>
            ))}
          </>
        )}
        {(ambassadorOnly || joinedThisWeekOnly || inactiveOnly || activeTags.size > 0) && (
          <Button
            variant="ghost"
            size="sm"
            onClick={() => {
              setAmbassadorOnly(false);
              setJoinedThisWeekOnly(false);
              setInactiveOnly(false);
              setActiveTags(new Set());
            }}
          >
            <X size={13} /> Clear filters
          </Button>
        )}
      </div>

      {selected.size > 0 && (
        <div className="mb-3 flex items-center gap-3 rounded-md border border-border bg-muted px-3 py-2">
          <span className="text-sm font-medium text-foreground">{selected.size} selected</span>
          <Button variant="outline" size="sm" onClick={() => setBulkGrantOpen(true)} disabled={bulkGrantTargets.length === 0}>
            <Crown size={13} /> Grant premium
          </Button>
          <Button variant="outline" size="sm" onClick={() => setBulkBanOpen(true)} disabled={bulkBanTargets.length === 0}>
            <Prohibit size={13} /> Suspend selected
          </Button>
          <Button variant="ghost" size="sm" onClick={() => setSelected(new Set())} className="ml-auto">
            <X size={13} /> Clear
          </Button>
        </div>
      )}

      <div className="overflow-x-auto rounded-lg border border-border">
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
              <TableHead>Country</TableHead>
              <TableHead>Device</TableHead>
              <TableHead>Tracker status</TableHead>
              <TableHead>Last active</TableHead>
              <TableHead>Joined</TableHead>
              <TableHead className="w-10" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {pageUsers.length === 0 && (
              <TableRow>
                <TableCell colSpan={11} className="h-32 text-center text-sm text-muted-foreground">
                  No users match these filters.
                </TableCell>
              </TableRow>
            )}
            {pageUsers.map((u) => {
              const tracker = trackerStatusForUser(u.id, devices);
              const last = lastActive.get(u.id);
              return (
                <TableRow key={u.id} className="cursor-pointer" onClick={() => router.push(`/users/${u.id}`)}>
                  <TableCell onClick={(e) => e.stopPropagation()}>
                    <Checkbox checked={selected.has(u.id)} onCheckedChange={() => toggleSelected(u.id)} aria-label={`Select ${displayName(u)}`} />
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2.5">
                      <Avatar className="size-8">
                        {u.photo_url && <AvatarImage src={u.photo_url} alt={displayName(u)} />}
                        <AvatarFallback className="text-xs">{initials(displayName(u))}</AvatarFallback>
                      </Avatar>
                      <div className="min-w-0">
                        <div className="flex items-center gap-1.5">
                          <p className="truncate text-sm font-medium text-foreground">{displayName(u)}</p>
                          {u.tags.map((t) => (
                            <Badge key={t} variant="outline" className="text-[10px]">{TAG_LABEL[t] ?? t}</Badge>
                          ))}
                        </div>
                        <p className="truncate text-xs text-muted-foreground">{u.email ?? `@${u.username}`}</p>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell><RoleBadge role={u.role} /></TableCell>
                  <TableCell>
                    <AccountStatusBadge user={u} />
                    {u.deleted && u.deleted_at && (
                      <p className="mt-1 text-xs text-muted-foreground">Purges in {daysUntilPurge(u.deleted_at)}d</p>
                    )}
                  </TableCell>
                  <TableCell><SubscriptionBadge subscription={u.subscription} /></TableCell>
                  <TableCell className="text-sm text-muted-foreground">{u.country ?? "—"}</TableCell>
                  <TableCell>
                    <span className="inline-flex items-center gap-1.5 text-sm text-muted-foreground">
                      {u.platform === "ios" ? (
                        <AppleLogo size={14} />
                      ) : u.platform === "android" ? (
                        <AndroidLogo size={14} />
                      ) : (
                        <Question size={14} />
                      )}
                      {u.platform === null ? "—" : (u.device_model ?? (u.platform === "ios" ? "iPhone" : "Android"))}
                    </span>
                  </TableCell>
                  <TableCell>
                    <span
                      className={
                        tracker === "connected"
                          ? "text-sm text-success"
                          : tracker === "offline"
                            ? "text-sm text-destructive"
                            : "text-sm text-muted-foreground"
                      }
                    >
                      {TRACKER_STATUS_LABEL[tracker]}
                    </span>
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">{last ? formatRelative(last) : "Never"}</TableCell>
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
                        {!u.deleted && (
                          <DropdownMenuItem onClick={() => setEmailTarget(u)}>
                            <EnvelopeSimple size={14} /> Send email
                          </DropdownMenuItem>
                        )}
                        {!u.deleted && (
                          <DropdownMenuItem onClick={() => sendPasswordReset(u)}>
                            <Key size={14} /> Reset password
                          </DropdownMenuItem>
                        )}
                        {!u.deleted && !u.banned && (
                          <DropdownMenuItem variant="destructive" onClick={() => setBanTarget(u)}>
                            <Prohibit size={14} /> Suspend user
                          </DropdownMenuItem>
                        )}
                        {!u.deleted && u.banned && (
                          <DropdownMenuItem onClick={() => unban(u)}>
                            <CheckCircle size={14} /> Unsuspend user
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
              );
            })}
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
            toast.success(`${displayName(banTarget)} suspended`);
            logAction("Suspended user", `${displayName(banTarget)} — ${reason}`);
          } catch (err) {
            toast.error(apiErrorMessage(err, "Couldn't suspend this user"));
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

      <SendEmailDialog user={emailTarget} onOpenChange={(open) => !open && setEmailTarget(null)} onConfirm={sendEmail} />

      <AlertDialog open={bulkBanOpen} onOpenChange={(open) => !bulkBanning && setBulkBanOpen(open)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              Suspend {bulkBanTargets.length} user{bulkBanTargets.length === 1 ? "" : "s"}?
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
              Suspend {bulkBanTargets.length} user{bulkBanTargets.length === 1 ? "" : "s"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <AlertDialog open={bulkGrantOpen} onOpenChange={(open) => !bulkGranting && setBulkGrantOpen(open)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              Grant premium to {bulkGrantTargets.length} user{bulkGrantTargets.length === 1 ? "" : "s"}?
            </AlertDialogTitle>
            <AlertDialogDescription>
              They&apos;ll each get 30 days of full premium access free of charge. Users already on an admin-granted
              comp period are skipped.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={bulkGranting}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmBulkGrant} disabled={bulkGranting}>
              {bulkGranting && <CircleNotch size={14} className="animate-spin" />}
              Grant premium to {bulkGrantTargets.length} user{bulkGrantTargets.length === 1 ? "" : "s"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
