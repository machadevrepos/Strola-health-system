"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { AnalyticsView } from "@/components/analytics/analytics-view";
import {
  fetchAllDailySummaries,
  fetchAllDevices,
  fetchAllSessions,
  fetchAnalyticsEvents,
  fetchAppSettings,
  fetchChallenges,
  fetchComments,
  fetchIntegrationConnections,
  fetchLeaderboard,
  fetchPosts,
  fetchUsers,
} from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

async function loadAnalytics() {
  const [users, events, posts, comments, dailySummaries, challenges, devices, connections, sessions, appSettings] = await Promise.all([
    fetchUsers(),
    // Lifetime windows (feature adoption, user funnel) need the full mock
    // event history, not just a 30-day slice — the per-day charts still
    // trim to their own window downstream.
    fetchAnalyticsEvents(365),
    fetchPosts(),
    fetchComments(),
    fetchAllDailySummaries(),
    fetchChallenges(),
    fetchAllDevices(),
    fetchIntegrationConnections(),
    fetchAllSessions(),
    fetchAppSettings(),
  ]);
  const leaderboards = await Promise.all(challenges.map((c) => fetchLeaderboard(c.id)));
  const participants = leaderboards.flat();
  return { users, events, posts, comments, dailySummaries, challenges, participants, devices, connections, sessions, appSettings };
}

export default function AnalyticsPage() {
  const { data, loading, error, reload } = useApiData(loadAnalytics);

  return (
    <div>
      <PageHeader title="Analytics" description="Engagement, retention, feature adoption, and revenue — the full picture, not just the last 30 days." />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <AnalyticsView {...data} />}
    </div>
  );
}
