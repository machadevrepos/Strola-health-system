"use client";

import type { ReactNode } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { DauTrendChart } from "@/components/charts/dau-trend-chart";
import { FunnelChart } from "@/components/charts/funnel-chart";
import {
  avgDailyStepsPerDay,
  dailyActiveUsers,
  eventCountsPerDay,
  featureUsageBreakdown,
  postsPerDay,
  retentionCurve,
} from "@/lib/data/queries";
import { formatNumber } from "@/lib/format";
import type { AnalyticsEvent, CommunityPost, DailyActivitySummary, UserProfile } from "@/lib/types";

function ChartCard({ title, description, children }: { title: string; description: string; children: ReactNode }) {
  return (
    <Card className="border-border shadow-none">
      <CardHeader>
        <CardTitle>{title}</CardTitle>
        <CardDescription>{description}</CardDescription>
      </CardHeader>
      <CardContent>{children}</CardContent>
    </Card>
  );
}

function RetentionChart({ users, events }: { users: UserProfile[]; events: AnalyticsEvent[] }) {
  const points = retentionCurve(users, events);
  const max = Math.max(1, ...points.map((p) => p.pct));
  return (
    <div className="space-y-2.5">
      {points.map((p) => (
        <div key={p.offsetDays} className="flex items-center gap-3">
          <span className="w-14 shrink-0 text-xs text-muted-foreground">Day {p.offsetDays}</span>
          <div className="h-2 flex-1 overflow-hidden rounded-full bg-muted">
            <div className="h-full rounded-full bg-primary" style={{ width: `${(p.pct / max) * 100}%` }} />
          </div>
          <span className="w-20 shrink-0 text-right font-mono text-xs text-foreground">
            {p.eligible > 0 ? `${p.pct}%` : "—"}
          </span>
        </div>
      ))}
      <p className="pt-1 text-xs text-muted-foreground">
        % who reopened the app that many days after signing up. Offsets with too small a signup cohort in the
        30-day window show &quot;—&quot; rather than an unreliable percentage.
      </p>
    </div>
  );
}

export function AnalyticsView({
  users,
  events,
  posts,
  dailySummaries,
}: {
  users: UserProfile[];
  events: AnalyticsEvent[];
  posts: CommunityPost[];
  dailySummaries: DailyActivitySummary[];
}) {
  const dau = dailyActiveUsers(events, 30);
  const avgSteps = avgDailyStepsPerDay(dailySummaries, 30);
  const challengeJoins = eventCountsPerDay(events, "challenge_joined", 30);
  const featureUsage = featureUsageBreakdown(events, 30);
  const workoutStarts = eventCountsPerDay(events, "workout_started", 30);
  const communityPosts = postsPerDay(posts, 30);
  const shares = eventCountsPerDay(events, "steps_shared", 30);
  const healthConnections = eventCountsPerDay(events, "health_app_connected", 30);

  const avgStepsOverall = avgSteps.length > 0 ? Math.round(avgSteps.reduce((a, b) => a + b.count, 0) / avgSteps.length) : 0;

  return (
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
      <ChartCard title="Daily users" description="Distinct users who opened the app each day.">
        <DauTrendChart data={dau} seriesName="Active users" />
      </ChartCard>

      <ChartCard title="Retention" description="Reopened the app N days after signing up.">
        <RetentionChart users={users} events={events} />
      </ChartCard>

      <ChartCard title="Average daily steps" description={`Across users with recorded history — ${formatNumber(avgStepsOverall)} avg over the period.`}>
        <DauTrendChart data={avgSteps} seriesName="Avg steps" />
      </ChartCard>

      <ChartCard title="Most used features" description="Core actions taken, last 30 days.">
        <FunnelChart data={featureUsage} />
      </ChartCard>

      <ChartCard title="Challenge participation" description="Challenge joins per day.">
        <DauTrendChart data={challengeJoins} seriesName="Joins" />
      </ChartCard>

      <ChartCard title="Workout starts" description="Sessions started per day.">
        <DauTrendChart data={workoutStarts} seriesName="Workouts started" />
      </ChartCard>

      <ChartCard title="Community posts" description="New posts per day.">
        <DauTrendChart data={communityPosts} seriesName="Posts" />
      </ChartCard>

      <ChartCard title="Shares" description="Steps shared externally, per day.">
        <DauTrendChart data={shares} seriesName="Shares" />
      </ChartCard>

      <ChartCard title="Apple Health / Health Connect connections" description="New health-app connections per day.">
        <DauTrendChart data={healthConnections} seriesName="Connections" />
      </ChartCard>
    </div>
  );
}
