"use client";

import Link from "next/link";
import {
  Users,
  ShieldWarning,
  DeviceMobile,
  Crown,
  Trophy,
  ChatCircleText,
  Warning,
  CurrencyGbp,
  UserPlus,
  UserMinus,
  Headset,
  Wrench,
  Trash,
} from "@phosphor-icons/react";
import { PageHeader } from "@/components/shell/page-header";
import { StatCard } from "@/components/shell/stat-card";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { DauRangeCard } from "@/components/charts/dau-range-card";
import { SubscriptionDonut } from "@/components/charts/subscription-donut";
import {
  fetchAccountDeletionRequests,
  fetchAllDevices,
  fetchAnalyticsEvents,
  fetchAppSettings,
  fetchChallenges,
  fetchCrashReports,
  fetchFirmwareFailures,
  fetchPosts,
  fetchReports,
  fetchSupportTickets,
  fetchUsers,
} from "@/lib/data/api";
import { NEEDS_ATTENTION_LABEL, needsAttentionItems, overviewTotals, subscriptionMix } from "@/lib/data/queries";
import type { NeedsAttentionCategory, NeedsAttentionItem } from "@/lib/data/queries";
import { useApiData } from "@/lib/use-api-data";
import { formatCurrencyGBP, formatNumber, formatRelative, formatSignedPercent } from "@/lib/format";
import type { CrashReport } from "@/lib/types";

async function loadOverview() {
  const [users, reports, posts, challenges, devices, events, crashes, tickets, firmwareFailures, deletionRequests, appSettings] =
    await Promise.all([
      fetchUsers(),
      fetchReports(),
      fetchPosts(),
      fetchChallenges(),
      fetchAllDevices(),
      // A full year so the DAU chart's 30/90/365-day toggle always has real
      // data — overviewTotals' own 7/30-day windows work the same either way.
      fetchAnalyticsEvents(365),
      fetchCrashReports(5),
      fetchSupportTickets(),
      fetchFirmwareFailures(),
      fetchAccountDeletionRequests(),
      fetchAppSettings(),
    ]);
  return { users, reports, posts, challenges, devices, events, crashes, tickets, firmwareFailures, deletionRequests, appSettings };
}

export default function OverviewPage() {
  const { data, loading, error, reload } = useApiData(loadOverview);

  return (
    <div>
      <PageHeader
        title="Overview"
        description="Strolla Health at a glance — engagement, subscriptions, and what needs attention."
      />

      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <OverviewContent {...data} />}
    </div>
  );
}

function OverviewContent({
  users,
  reports,
  posts,
  challenges,
  devices,
  events,
  crashes,
  tickets,
  firmwareFailures,
  deletionRequests,
  appSettings,
}: Awaited<ReturnType<typeof loadOverview>>) {
  const totals = overviewTotals({ users, reports, posts, challenges, devices, events }, appSettings.premium_monthly_price_gbp);
  const mix = subscriptionMix(users);
  const attentionItems = needsAttentionItems({ reports, tickets, firmwareFailures, deletionRequests, devices });

  return (
    <>
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-3 xl:grid-cols-5">
        <StatCard
          label="Total users"
          value={formatNumber(totals.totalUsers)}
          trendLabel={formatSignedPercent(totals.totalUsersGrowthPct)}
          hint="vs last month"
          icon={<Users size={16} />}
        />
        <StatCard label="Daily active users" value={formatNumber(totals.dauToday)} icon={<Users size={16} />} />
        <StatCard label="Active this week" value={formatNumber(totals.activeThisWeek)} icon={<Users size={16} />} />
        <StatCard label="Active this month" value={formatNumber(totals.activeThisMonth)} icon={<Users size={16} />} />
        <StatCard
          label="New signups"
          value={formatNumber(totals.newSignups7d)}
          trendLabel={formatSignedPercent(totals.newSignupsGrowthPct)}
          hint="last 7 days, vs prior week"
          icon={<Users size={16} />}
        />
      </div>

      <div className="mt-3 grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatCard label="Premium subscribers" value={formatNumber(totals.premiumSubscribers)} icon={<Crown size={16} />} />
        <StatCard
          label="Active challenges"
          value={totals.activeChallenges}
          hint="includes private challenges"
          icon={<Trophy size={16} />}
        />
        <StatCard
          label="Trackers connected"
          value={`${totals.pairedDevices}/${totals.totalDevices}`}
          icon={<DeviceMobile size={16} />}
        />
        <StatCard label="Posts today" value={totals.postsToday} icon={<ChatCircleText size={16} />} />
      </div>

      <div className="mt-3 grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatCard
          label="Open reports"
          value={totals.openReports}
          tone={totals.openReports > 0 ? "danger" : "default"}
          icon={<ShieldWarning size={16} />}
        />
        <StatCard label="Monthly recurring revenue" value={formatCurrencyGBP(totals.mrr)} icon={<CurrencyGbp size={16} />} />
        <StatCard label="New premium subs" value={formatNumber(totals.newPremiumThisMonth)} hint="this month" icon={<UserPlus size={16} />} />
        <StatCard label="Cancelled subs" value={formatNumber(totals.cancelledPremiumThisMonth)} hint="this month" icon={<UserMinus size={16} />} />
      </div>

      <div className="mt-4 grid grid-cols-1 gap-3 lg:grid-cols-3">
        <DauRangeCard events={events} />

        <Card className="border-border shadow-none">
          <CardHeader>
            <CardTitle>Subscription mix</CardTitle>
            <CardDescription>Active accounts by tier.</CardDescription>
          </CardHeader>
          <CardContent>
            <SubscriptionDonut data={mix} />
          </CardContent>
        </Card>
      </div>

      <div className="mt-3">
        <NeedsAttentionCard items={attentionItems} />
      </div>

      <div className="mt-3">
        <RecentCrashesCard crashes={crashes} />
      </div>
    </>
  );
}

const NEEDS_ATTENTION_ICON: Record<NeedsAttentionCategory, typeof ShieldWarning> = {
  report: ShieldWarning,
  support_ticket: Headset,
  firmware_failure: Wrench,
  deletion_request: Trash,
};

function NeedsAttentionCard({ items }: { items: NeedsAttentionItem[] }) {
  const counts = items.reduce(
    (acc, item) => {
      acc[item.category] += 1;
      return acc;
    },
    { report: 0, support_ticket: 0, firmware_failure: 0, deletion_request: 0 } as Record<NeedsAttentionCategory, number>
  );

  return (
    <Card className="border-border shadow-none">
      <CardHeader>
        <CardTitle>Needs attention</CardTitle>
        <CardDescription>Open reports, support tickets, failed firmware updates, and pending deletion requests.</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          {(Object.keys(NEEDS_ATTENTION_LABEL) as NeedsAttentionCategory[]).map((category) => {
            const Icon = NEEDS_ATTENTION_ICON[category];
            return (
              <StatCard
                key={category}
                label={NEEDS_ATTENTION_LABEL[category]}
                value={counts[category]}
                tone={counts[category] > 0 ? "danger" : "default"}
                icon={<Icon size={16} />}
              />
            );
          })}
        </div>

        <div className="space-y-3">
          {items.length === 0 && <p className="text-sm text-muted-foreground">All clear. Nice and quiet.</p>}
          {items.slice(0, 6).map((item) => {
            const row = (
              <div className="flex items-center justify-between gap-2">
                <Badge variant="outline" className="text-[11px]">
                  {NEEDS_ATTENTION_LABEL[item.category]}
                </Badge>
                <span className="text-xs text-muted-foreground">{formatRelative(item.timestamp)}</span>
              </div>
            );
            const className = "block rounded-md border border-border p-2.5 text-sm transition-colors hover:bg-muted";
            return item.href ? (
              <Link key={item.id} href={item.href} className={className}>
                {row}
                <p className="mt-1.5 line-clamp-2 text-muted-foreground">{item.title}</p>
              </Link>
            ) : (
              <div key={item.id} className="rounded-md border border-border p-2.5 text-sm">
                {row}
                <p className="mt-1.5 line-clamp-2 text-muted-foreground">{item.title}</p>
              </div>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}

function RecentCrashesCard({ crashes }: { crashes: CrashReport[] }) {
  return (
    <Card className="border-border shadow-none">
      <CardHeader>
        <CardTitle>Recent app crashes</CardTitle>
        <CardDescription>
          No crash-reporting pipeline is wired in yet — this is a placeholder for once one is (Crashlytics/Sentry).
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        {crashes.length === 0 && <p className="text-sm text-muted-foreground">No crashes reported.</p>}
        {crashes.map((c) => (
          <div key={c.id} className="rounded-md border border-border p-2.5 text-sm">
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-1.5">
                <Warning size={13} className="text-destructive" />
                <Badge variant="outline" className="text-[11px]">
                  {c.platform === "ios" ? "iOS" : "Android"} {c.app_version}
                </Badge>
              </div>
              <span className="text-xs text-muted-foreground">{formatRelative(c.occurred_at)}</span>
            </div>
            <p className="mt-1.5 font-mono text-xs text-muted-foreground">{c.summary}</p>
            {c.user_id && (
              <Link href={`/users/${c.user_id}`} className="mt-1 inline-block text-xs font-medium text-foreground hover:underline">
                View affected user
              </Link>
            )}
          </div>
        ))}
      </CardContent>
    </Card>
  );
}
