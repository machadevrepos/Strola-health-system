"use client";

import * as React from "react";
import Link from "next/link";
import { toast } from "sonner";
import { Crown, CurrencyGbp, Hourglass, UserCircle, TrendUp, TrendDown, Plus, X, MagnifyingGlass } from "@phosphor-icons/react";
import { StatCard } from "@/components/shell/stat-card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { GrantPremiumToUserDialog } from "@/components/premium/grant-premium-to-user-dialog";
import { grantPremium, revokePremium } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { logAction } from "@/lib/audit-log-store";
import { LIFETIME_ISO, classifySubscription, subscriptionOverviewStats, userDisplayName } from "@/lib/data/queries";
import type { SubscriptionSegment } from "@/lib/data/queries";
import { formatCurrencyGBP, formatDate, formatNumber, formatPercent, initials, titleCase } from "@/lib/format";
import type { AnalyticsEvent, AppSettings, UserProfile } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

type SegmentFilter = "all" | SubscriptionSegment;

const SEGMENT_FILTER_LABEL: Record<SegmentFilter, string> = {
  all: "All subscriptions",
  paying: "Paying",
  trial: "Trial",
  comp: "Complimentary",
  free: "Free",
};

const SEGMENT_BADGE: Record<SubscriptionSegment, React.ReactNode> = {
  paying: <Badge className="bg-primary/12 text-primary">Paying</Badge>,
  comp: <Badge variant="outline">Complimentary</Badge>,
  trial: <Badge className="bg-brand-accent/20 text-brand-accent-strong">Trial</Badge>,
  free: <Badge variant="secondary">Free</Badge>,
};

export function PremiumView({
  users: initialUsers,
  events,
  appSettings,
}: {
  users: UserProfile[];
  events: AnalyticsEvent[];
  appSettings: AppSettings;
}) {
  const [users, setUsers] = React.useState(initialUsers);
  const [grantOpen, setGrantOpen] = React.useState(false);
  const [segmentFilter, setSegmentFilter] = React.useState<SegmentFilter>("all");
  const [query, setQuery] = React.useState("");

  React.useEffect(() => setUsers(initialUsers), [initialUsers]);

  const stats = subscriptionOverviewStats(users, events, appSettings.premium_monthly_price_gbp);
  const nonSubscribers = users.filter(
    (u) => u.role === "user" && !u.deleted && !(u.subscription.tier === "premium" && u.subscription.status === "active")
  );

  const listed = users
    .filter((u) => u.role === "user" && !u.deleted)
    .map((u) => ({ user: u, segment: classifySubscription(u) }))
    .filter(({ segment }) => segment !== "free")
    .filter(({ segment }) => segmentFilter === "all" || segment === segmentFilter)
    .filter(({ user }) => {
      if (!query) return true;
      const q = query.toLowerCase();
      const haystack = `${userDisplayName(user)} ${user.email ?? ""} ${user.subscription.revenuecat_app_user_id ?? ""}`.toLowerCase();
      return haystack.includes(q);
    })
    .sort((a, b) => {
      const aExp = a.segment === "paying" ? a.user.subscription.renews_at : a.user.subscription.comp_until;
      const bExp = b.segment === "paying" ? b.user.subscription.renews_at : b.user.subscription.comp_until;
      if (!aExp && !bExp) return 0;
      if (!aExp) return 1;
      if (!bExp) return -1;
      return +new Date(aExp) - +new Date(bExp);
    });

  async function grantToUser(userId: string, until: Date | null, reason: string) {
    try {
      await grantPremium(userId, until ? until.toISOString() : LIFETIME_ISO, reason);
      setUsers((prev) =>
        prev.map((u) =>
          u.id === userId
            ? { ...u, subscription: { ...u.subscription, comp_until: until ? until.toISOString() : LIFETIME_ISO, comp_reason: reason } }
            : u
        )
      );
      const target = users.find((u) => u.id === userId);
      const untilLabel = until ? formatDate(until.toISOString()) : "forever (lifetime)";
      toast.success(`Premium granted${target ? ` to ${userDisplayName(target)}` : ""} until ${untilLabel}`);
      logAction("Granted premium", `${target ? userDisplayName(target) : userId} until ${untilLabel} — ${reason}`);
      setGrantOpen(false);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't grant premium"));
    }
  }

  async function extend(user: UserProfile, days: number) {
    const base = user.subscription.comp_until && +new Date(user.subscription.comp_until) > Date.now() ? new Date(user.subscription.comp_until) : new Date();
    const until = new Date(base);
    until.setDate(until.getDate() + days);
    const reason = user.subscription.comp_reason ?? "admin_grant";
    try {
      await grantPremium(user.id, until.toISOString(), reason);
      setUsers((prev) =>
        prev.map((u) =>
          u.id === user.id ? { ...u, subscription: { ...u.subscription, comp_until: until.toISOString(), comp_reason: reason } } : u
        )
      );
      toast.success(`Extended to ${formatDate(until.toISOString())}`);
      logAction("Extended premium", `${userDisplayName(user)} to ${formatDate(until.toISOString())}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't extend premium"));
    }
  }

  async function revoke(user: UserProfile) {
    try {
      await revokePremium(user.id);
      setUsers((prev) =>
        prev.map((u) => (u.id === user.id ? { ...u, subscription: { ...u.subscription, comp_until: null, comp_reason: null } } : u))
      );
      toast.success(`Premium removed for ${userDisplayName(user)}`);
      logAction("Removed premium", userDisplayName(user));
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't remove premium"));
    }
  }

  return (
    <div>
      <div className="mb-4 grid grid-cols-2 gap-3 lg:grid-cols-3 xl:grid-cols-6">
        <StatCard
          label="Active premium"
          value={formatNumber(stats.activePremium)}
          hint="Paying + complimentary"
          icon={<Crown size={16} />}
        />
        <StatCard
          label="Monthly recurring revenue"
          value={formatCurrencyGBP(stats.mrr)}
          hint="Paying subscribers only"
          icon={<CurrencyGbp size={16} />}
        />
        <StatCard label="Trial users" value={formatNumber(stats.trialUsers)} icon={<Hourglass size={16} />} />
        <StatCard label="Free users" value={formatNumber(stats.freeUsers)} icon={<UserCircle size={16} />} />
        <StatCard
          label="Conversion rate"
          value={formatPercent(stats.conversionRatePct)}
          hint="Trial → premium"
          icon={<TrendUp size={16} />}
        />
        <StatCard
          label="Churn"
          value={formatPercent(stats.churnRatePct)}
          hint="Last 30 days"
          tone={stats.churnRatePct && stats.churnRatePct > 0 ? "danger" : "default"}
          icon={<TrendDown size={16} />}
        />
      </div>

      <div className="mb-3 flex flex-wrap items-center gap-2">
        <div className="relative flex-1 min-w-[220px] max-w-sm">
          <MagnifyingGlass size={14} className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
          <Input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search name, email, or RevenueCat ID"
            className="pl-8"
          />
        </div>
        <Select value={segmentFilter} onValueChange={(v) => v && setSegmentFilter(v as SegmentFilter)}>
          <SelectTrigger className="w-44"><SelectValue>{SEGMENT_FILTER_LABEL[segmentFilter]}</SelectValue></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All subscriptions</SelectItem>
            <SelectItem value="paying">Paying</SelectItem>
            <SelectItem value="trial">Trial</SelectItem>
            <SelectItem value="comp">Complimentary</SelectItem>
          </SelectContent>
        </Select>
        <Button size="sm" className="ml-auto" onClick={() => setGrantOpen(true)}>
          <Plus size={14} /> Grant premium to a user
        </Button>
      </div>

      <div className="overflow-hidden rounded-lg border border-border">
        <Table>
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead>User</TableHead>
              <TableHead>Type</TableHead>
              <TableHead>Details</TableHead>
              <TableHead className="w-56" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {listed.length === 0 && (
              <TableRow>
                <TableCell colSpan={4} className="h-32 text-center text-sm text-muted-foreground">
                  No subscriptions match these filters.
                </TableCell>
              </TableRow>
            )}
            {listed.map(({ user, segment }) => {
              const expiresAt = segment === "paying" ? user.subscription.renews_at : user.subscription.comp_until;
              const isLifetime = expiresAt === LIFETIME_ISO;
              return (
                <TableRow key={user.id}>
                  <TableCell>
                    <Link href={`/users/${user.id}`} className="flex items-center gap-2.5 hover:underline">
                      <Avatar className="size-8">
                        {user.photo_url && <AvatarImage src={user.photo_url} alt={userDisplayName(user)} />}
                        <AvatarFallback className="text-xs">{initials(userDisplayName(user))}</AvatarFallback>
                      </Avatar>
                      <div className="min-w-0">
                        <p className="truncate text-sm font-medium text-foreground">{userDisplayName(user)}</p>
                        <p className="truncate text-xs text-muted-foreground">{user.email ?? `@${user.username}`}</p>
                      </div>
                    </Link>
                  </TableCell>
                  <TableCell>{SEGMENT_BADGE[segment]}</TableCell>
                  <TableCell className="text-xs text-muted-foreground">
                    <p>
                      {segment === "paying" ? "Renews" : segment === "trial" ? "Trial ends" : "Comp expires"}{" "}
                      {isLifetime ? "— lifetime" : expiresAt ? formatDate(expiresAt) : "—"}
                      {" · "}
                      {titleCase(user.subscription.status)}
                    </p>
                    {segment === "comp" && user.subscription.comp_reason && <p>Reason: {user.subscription.comp_reason}</p>}
                    {user.subscription.cancelled_at && <p>Cancelled {formatDate(user.subscription.cancelled_at)}</p>}
                    {segment === "paying" && user.subscription.revenuecat_app_user_id && (
                      <p className="font-mono">{user.subscription.revenuecat_app_user_id}</p>
                    )}
                  </TableCell>
                  <TableCell>
                    <div className="flex justify-end gap-2">
                      {segment === "comp" ? (
                        <>
                          <Button variant="outline" size="sm" onClick={() => extend(user, 30)}>
                            Extend 30d
                          </Button>
                          <Button variant="ghost" size="icon-sm" aria-label="Remove premium" onClick={() => revoke(user)}>
                            <X size={14} />
                          </Button>
                        </>
                      ) : (
                        <span className="text-xs text-muted-foreground">
                          {segment === "trial" ? "Automatic signup trial" : "Real subscription — managed via RevenueCat"}
                        </span>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </div>

      <GrantPremiumToUserDialog open={grantOpen} onOpenChange={setGrantOpen} candidates={nonSubscribers} onGrant={grantToUser} />
    </div>
  );
}
