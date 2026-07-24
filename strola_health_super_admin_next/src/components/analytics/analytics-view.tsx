"use client";

import type { ReactNode } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { StatCard } from "@/components/shell/stat-card";
import { DauTrendChart } from "@/components/charts/dau-trend-chart";
import { FunnelChart } from "@/components/charts/funnel-chart";
import { RetentionCurveChart } from "@/components/charts/retention-curve-chart";
import { BarList } from "@/components/charts/bar-list";
import {
  activeUsersInWindow,
  averageSessionLength,
  averageStreak,
  avgDailyStepsPerDay,
  communityHealthStats,
  currentChallengeParticipation,
  dailyActiveUsers,
  featureAdoptionRates,
  goalCompletionRates,
  newSignupsPerDay,
  premiumAnalyticsStats,
  retentionCurve,
  returningUsersToday,
  screenViewBreakdown,
  stepGoalDistribution,
  trackerUsageStats,
  userFunnel,
} from "@/lib/data/queries";
import { formatCurrencyGBP, formatDuration, formatNumber, formatPercent } from "@/lib/format";
import type {
  AnalyticsEvent,
  AppSettings,
  Challenge,
  ChallengeParticipant,
  CommunityComment,
  CommunityPost,
  DailyActivitySummary,
  Device,
  IntegrationConnection,
  UserProfile,
  WorkoutSession,
} from "@/lib/types";

function ChartCard({ title, description, children }: { title: string; description?: string; children: ReactNode }) {
  return (
    <Card className="border-border shadow-none">
      <CardHeader>
        <CardTitle>{title}</CardTitle>
        {description && <CardDescription>{description}</CardDescription>}
      </CardHeader>
      <CardContent>{children}</CardContent>
    </Card>
  );
}

export function AnalyticsView({
  users,
  events,
  posts,
  comments,
  dailySummaries,
  challenges,
  participants,
  devices,
  connections,
  sessions,
  appSettings,
}: {
  users: UserProfile[];
  events: AnalyticsEvent[];
  posts: CommunityPost[];
  comments: CommunityComment[];
  dailySummaries: DailyActivitySummary[];
  challenges: Challenge[];
  participants: ChallengeParticipant[];
  devices: Device[];
  connections: IntegrationConnection[];
  sessions: WorkoutSession[];
  appSettings: AppSettings;
}) {
  const dau = dailyActiveUsers(events, 30);
  const dauToday = activeUsersInWindow(events, 1);
  const wau = activeUsersInWindow(events, 7);
  const mau = activeUsersInWindow(events, 30);
  const newUsers = newSignupsPerDay(users, 30);
  const returningToday = returningUsersToday(users, events);
  const avgSteps = avgDailyStepsPerDay(dailySummaries, 30);
  const avgStepsOverall = avgSteps.length > 0 ? Math.round(avgSteps.reduce((a, b) => a + b.count, 0) / avgSteps.length) : 0;

  const challengeParticipation = currentChallengeParticipation(challenges, participants, events);
  const avgSession = averageSessionLength(sessions);
  const streak = averageStreak(dailySummaries);
  const stepGoals = stepGoalDistribution(users);

  const screenUsage = screenViewBreakdown(events, 30);
  const adoption = featureAdoptionRates(users, events);
  const goalRates = goalCompletionRates(users, dailySummaries);
  const community = communityHealthStats(posts, comments, 30);
  const premium = premiumAnalyticsStats(users, events, appSettings.premium_monthly_price_gbp);
  const retention = retentionCurve(users, events);
  const funnel = userFunnel(users, events, connections);
  const tracker = trackerUsageStats(devices);

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatCard label="DAU" value={formatNumber(dauToday)} hint="Opened the app today" />
        <StatCard label="WAU" value={formatNumber(wau)} hint="Last 7 days" />
        <StatCard label="MAU" value={formatNumber(mau)} hint="Last 30 days" />
        <StatCard label="Returning today" value={formatNumber(returningToday)} hint="Opened today, signed up before today" />
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <ChartCard title="Daily active users" description="Distinct users who opened the app each day.">
          <DauTrendChart data={dau} seriesName="Active users" />
        </ChartCard>

        <ChartCard title="New users" description="Signups per day, last 30 days.">
          <DauTrendChart data={newUsers} seriesName="New users" />
        </ChartCard>
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        <StatCard label="Average session" value={formatDuration(avgSession)} hint="Mean workout duration" />
        <StatCard label="Average streak" value={`${streak.toFixed(1)} days`} hint="Current consecutive-day streak, active users" />
        <StatCard
          label="Most common step goal"
          value={stepGoals.mostCommon !== null ? formatNumber(stepGoals.mostCommon) : "—"}
          hint={stepGoals.mostCommonPct !== null ? `${stepGoals.mostCommonPct}% of users` : undefined}
        />
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Card className="border-border shadow-none">
          <CardHeader>
            <CardTitle>Challenge participation</CardTitle>
            <CardDescription>{challengeParticipation?.title ?? "No active challenge right now."}</CardDescription>
          </CardHeader>
          <CardContent className="grid grid-cols-2 gap-3">
            <StatCard label="Joined" value={formatNumber(challengeParticipation?.joined ?? 0)} />
            <StatCard label="Of active users" value={formatPercent(challengeParticipation?.activeUserPct ?? null)} />
          </CardContent>
        </Card>

        <ChartCard title="Average daily steps" description={`Across users with recorded history — ${formatNumber(avgStepsOverall)} avg over the period.`}>
          <DauTrendChart data={avgSteps} seriesName="Avg steps" />
        </ChartCard>
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <ChartCard title="Screen usage" description="Most-visited screens, last 30 days.">
          <BarList items={screenUsage.map((s) => ({ label: s.stage, value: s.count }))} valueLabel={formatNumber} />
        </ChartCard>

        <ChartCard title="Feature adoption" description="% of all users who have ever used each feature.">
          <BarList items={adoption.map((a) => ({ label: a.feature, value: a.pct, displayValue: `${a.pct}%` }))} />
        </ChartCard>
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <ChartCard title="Goal completion rate" description="% of user-days that hit that user's own daily step goal.">
          <div className="grid grid-cols-3 gap-3">
            <StatCard label="Today" value={formatPercent(goalRates.today)} />
            <StatCard label="This week" value={formatPercent(goalRates.week)} />
            <StatCard label="This month" value={formatPercent(goalRates.month)} />
          </div>
        </ChartCard>

        <ChartCard title="Community health" description="Last 30 days.">
          <div className="grid grid-cols-2 gap-3">
            <StatCard label="Posts" value={formatNumber(community.posts)} />
            <StatCard label="Comments" value={formatNumber(community.comments)} />
            <StatCard label="Likes" value={formatNumber(community.likes)} />
            <StatCard label="New friends" value="—" hint="No friend/follow relationship in the data model yet" />
          </div>
        </ChartCard>
      </div>

      <ChartCard title="Premium analytics" description="Built on the same synthetic price as the MRR estimate on the Subscriptions page — illustrative, not real revenue.">
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-3 xl:grid-cols-5">
          <StatCard label="Conversion" value={formatPercent(premium.conversionRatePct)} />
          <StatCard label="Churn" value={formatPercent(premium.churnRatePct)} />
          <StatCard label="Renewal" value={formatPercent(premium.renewalRatePct)} />
          <StatCard label="LTV" value={formatCurrencyGBP(premium.ltv)} />
          <StatCard label="ARPU" value={formatCurrencyGBP(premium.arpu)} />
        </div>
      </ChartCard>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <ChartCard title="Retention" description="Reopened the app N days after signing up.">
          <RetentionCurveChart points={retention} />
        </ChartCard>

        <ChartCard title="User funnel" description="Distinct users who've ever reached each stage.">
          <FunnelChart data={funnel} />
        </ChartCard>
      </div>

      <ChartCard title="Tracker usage">
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          <StatCard label="Connected today" value={formatNumber(tracker.connectedToday)} />
          <StatCard label="Synced today" value={formatNumber(tracker.syncedToday)} />
          <StatCard label="Average battery" value={tracker.averageBatteryPct !== null ? `${tracker.averageBatteryPct}%` : "—"} />
          <StatCard label="Sync failures" value={formatNumber(tracker.syncFailures)} tone={tracker.syncFailures > 0 ? "danger" : "default"} />
        </div>
        <div className="mt-4">
          <p className="mb-2 text-xs font-medium text-muted-foreground">Firmware versions</p>
          <BarList items={tracker.firmwareVersions.map((f) => ({ label: f.stage, value: f.count }))} valueLabel={formatNumber} />
        </div>
      </ChartCard>
    </div>
  );
}
