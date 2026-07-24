"use client";

import * as React from "react";
import Link from "next/link";
import { toast } from "sonner";
import { Crown, CurrencyGbp, Clock, Plus, X } from "@phosphor-icons/react";
import { StatCard } from "@/components/shell/stat-card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { GrantPremiumToUserDialog } from "@/components/premium/grant-premium-to-user-dialog";
import { grantPremium, revokePremium } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { logAction } from "@/lib/audit-log-store";
import { LIFETIME_ISO, premiumRevenueEstimate, premiumSubscribers, userDisplayName } from "@/lib/data/queries";
import { formatDate, formatNumber, initials, titleCase } from "@/lib/format";
import type { AppSettings, UserProfile } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

export function PremiumView({ users: initialUsers, appSettings }: { users: UserProfile[]; appSettings: AppSettings }) {
  const [users, setUsers] = React.useState(initialUsers);
  const [grantOpen, setGrantOpen] = React.useState(false);

  React.useEffect(() => setUsers(initialUsers), [initialUsers]);

  const subscribers = premiumSubscribers(users);
  const revenue = premiumRevenueEstimate(users, appSettings.premium_monthly_price_gbp);
  const compCount = subscribers.filter((s) => s.isComp).length;
  const expiringSoon = subscribers.filter(
    (s) => s.expiresAt && +new Date(s.expiresAt) - Date.now() < 7 * 86_400_000 && +new Date(s.expiresAt) - Date.now() > 0
  ).length;
  const nonSubscribers = users.filter(
    (u) => u.role === "user" && !u.deleted && !(u.subscription.tier === "premium" && u.subscription.status === "active")
  );

  async function grantToUser(userId: string, until: Date | null, reason: string) {
    const untilIso = until ? until.toISOString() : LIFETIME_ISO;
    const untilLabel = until ? formatDate(untilIso) : "forever (lifetime)";
    try {
      await grantPremium(userId, untilIso, reason);
      setUsers((prev) =>
        prev.map((u) => (u.id === userId ? { ...u, subscription: { ...u.subscription, comp_until: untilIso, comp_reason: reason } } : u))
      );
      const target = users.find((u) => u.id === userId);
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
      <div className="mb-4 flex items-center justify-between">
        <div className="grid flex-1 grid-cols-2 gap-3 lg:grid-cols-4">
          <StatCard label="Subscribers" value={formatNumber(subscribers.length)} icon={<Crown size={16} />} />
          <StatCard
            label="Est. monthly revenue"
            value={`£${revenue.toFixed(2)}`}
            hint="Paying subscribers only — synthetic price"
            icon={<CurrencyGbp size={16} />}
          />
          <StatCard label="Admin-comp'd" value={formatNumber(compCount)} icon={<Crown size={16} />} />
          <StatCard
            label="Expiring in 7 days"
            value={formatNumber(expiringSoon)}
            tone={expiringSoon > 0 ? "danger" : "default"}
            icon={<Clock size={16} />}
          />
        </div>
      </div>

      <div className="mb-3 flex justify-end">
        <Button size="sm" onClick={() => setGrantOpen(true)}>
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
            {subscribers.length === 0 && (
              <TableRow>
                <TableCell colSpan={4} className="h-32 text-center text-sm text-muted-foreground">
                  No premium subscribers right now.
                </TableCell>
              </TableRow>
            )}
            {subscribers.map(({ user, isComp, expiresAt }) => (
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
                <TableCell>
                  {isComp ? (
                    <Badge variant="outline">Admin comp</Badge>
                  ) : (
                    <Badge className="bg-primary/12 text-primary">Paying</Badge>
                  )}
                </TableCell>
                <TableCell className="text-xs text-muted-foreground">
                  <p>
                    {isComp ? "Comp expires" : "Renews"} {expiresAt ? formatDate(expiresAt) : "—"}
                    {" · "}
                    {titleCase(user.subscription.status)}
                  </p>
                  {user.subscription.cancelled_at && <p>Cancelled {formatDate(user.subscription.cancelled_at)}</p>}
                  {!isComp && user.subscription.revenuecat_app_user_id && (
                    <p className="font-mono">{user.subscription.revenuecat_app_user_id}</p>
                  )}
                </TableCell>
                <TableCell>
                  <div className="flex justify-end gap-2">
                    {isComp ? (
                      <>
                        <Button variant="outline" size="sm" onClick={() => extend(user, 30)}>
                          Extend 30d
                        </Button>
                        <Button variant="ghost" size="icon-sm" aria-label="Remove premium" onClick={() => revoke(user)}>
                          <X size={14} />
                        </Button>
                      </>
                    ) : (
                      <span className="text-xs text-muted-foreground">Real subscription — managed via RevenueCat</span>
                    )}
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      <GrantPremiumToUserDialog open={grantOpen} onOpenChange={setGrantOpen} candidates={nonSubscribers} onGrant={grantToUser} />
    </div>
  );
}
