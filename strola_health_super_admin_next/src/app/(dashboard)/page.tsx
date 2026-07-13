"use client";

import Link from "next/link";
import { Users, ShieldWarning, Image as ImageIcon, DeviceMobile, Crown, Trophy, ChatCircleText, Warning } from "@phosphor-icons/react";
import { PageHeader } from "@/components/shell/page-header";
import { StatCard } from "@/components/shell/stat-card";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { DauTrendChart } from "@/components/charts/dau-trend-chart";
import { FunnelChart } from "@/components/charts/funnel-chart";
import { SubscriptionDonut } from "@/components/charts/subscription-donut";
import {
  fetchAllDevices,
  fetchAnalyticsEvents,
  fetchChallenges,
  fetchCrashReports,
  fetchPosts,
  fetchReports,
  fetchUsers,
} from "@/lib/data/api";
import { dailyActiveUsers, overviewTotals, subscriptionMix, workoutFunnel } from "@/lib/data/queries";
import { useApiData } from "@/lib/use-api-data";
import { formatNumber, formatRelative } from "@/lib/format";
import type { CrashReport } from "@/lib/types";

async function loadOverview() {
  const [users, reports, posts, challenges, devices, events, crashes] = await Promise.all([
    fetchUsers(),
    fetchReports(),
    fetchPosts(),
    fetchChallenges(),
    fetchAllDevices(),
    fetchAnalyticsEvents(30),
    fetchCrashReports(5),
  ]);
  return { users, reports, posts, challenges, devices, events, crashes };
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
}: Awaited<ReturnType<typeof loadOverview>>) {
  const totals = overviewTotals({ users, reports, posts, challenges, devices, events });
  const dau = dailyActiveUsers(events, 30);
  const funnel = workoutFunnel(events, 30);
  const mix = subscriptionMix(users);
  const recentReports = reports.filter((r) => r.status === "open").slice(0, 4);

  return (
    <>
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-5">
        <StatCard label="Total users" value={formatNumber(totals.totalUsers)} icon={<Users size={16} />} />
        <StatCard label="Active today" value={formatNumber(totals.dauToday)} icon={<Users size={16} />} />
        <StatCard label="Active this week" value={formatNumber(totals.activeThisWeek)} icon={<Users size={16} />} />
        <StatCard label="Active this month" value={formatNumber(totals.activeThisMonth)} icon={<Users size={16} />} />
        <StatCard label="New signups" value={formatNumber(totals.newSignups7d)} hint="last 7 days" icon={<Users size={16} />} />
      </div>

      <div className="mt-3 grid grid-cols-2 gap-3 lg:grid-cols-6">
        <StatCard label="Premium subscribers" value={formatNumber(totals.premiumSubscribers)} icon={<Crown size={16} />} />
        <StatCard label="Active challenges" value={totals.activeChallenges} icon={<Trophy size={16} />} />
        <StatCard
          label="Devices paired"
          value={`${totals.pairedDevices}/${totals.totalDevices}`}
          icon={<DeviceMobile size={16} />}
        />
        <StatCard label="Posts today" value={totals.postsToday} icon={<ChatCircleText size={16} />} />
        <StatCard
          label="Open reports"
          value={totals.openReports}
          tone={totals.openReports > 0 ? "danger" : "default"}
          icon={<ShieldWarning size={16} />}
        />
        <StatCard label="Hidden posts" value={totals.hiddenPosts} icon={<ImageIcon size={16} />} />
      </div>

      <div className="mt-4 grid grid-cols-1 gap-3 lg:grid-cols-3">
        <Card className="border-border shadow-none lg:col-span-2">
          <CardHeader>
            <CardTitle>Daily active users</CardTitle>
            <CardDescription>Last 30 days, from app_opened events.</CardDescription>
          </CardHeader>
          <CardContent>
            <DauTrendChart data={dau} />
          </CardContent>
        </Card>

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

      <div className="mt-3 grid grid-cols-1 gap-3 lg:grid-cols-3">
        <Card className="border-border shadow-none lg:col-span-2">
          <CardHeader>
            <CardTitle>Workout funnel</CardTitle>
            <CardDescription>Started vs. completed, last 30 days.</CardDescription>
          </CardHeader>
          <CardContent>
            <FunnelChart data={funnel} />
          </CardContent>
        </Card>

        <Card className="border-border shadow-none">
          <CardHeader className="flex-row items-center justify-between [&>div]:contents">
            <div>
              <CardTitle>Needs attention</CardTitle>
              <CardDescription>Open reports, oldest first.</CardDescription>
            </div>
          </CardHeader>
          <CardContent className="space-y-3">
            {recentReports.length === 0 && (
              <p className="text-sm text-muted-foreground">No open reports. Nice and quiet.</p>
            )}
            {recentReports.map((r) => (
              <Link
                key={r.id}
                href="/moderation"
                className="block rounded-md border border-border p-2.5 text-sm transition-colors hover:bg-muted"
              >
                <div className="flex items-center justify-between gap-2">
                  <Badge variant="outline" className="text-[11px]">
                    {r.target_type === "post" ? "Post" : "User"}
                  </Badge>
                  <span className="text-xs text-muted-foreground">{formatRelative(r.created_at)}</span>
                </div>
                <p className="mt-1.5 line-clamp-2 text-muted-foreground">{r.reason}</p>
              </Link>
            ))}
          </CardContent>
        </Card>
      </div>

      <div className="mt-3">
        <RecentCrashesCard crashes={crashes} />
      </div>
    </>
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
