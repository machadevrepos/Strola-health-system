"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { AnalyticsView } from "@/components/analytics/analytics-view";
import { fetchAllDailySummaries, fetchAnalyticsEvents, fetchPosts, fetchUsers } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

async function loadAnalytics() {
  const [users, events, posts, dailySummaries] = await Promise.all([
    fetchUsers(),
    fetchAnalyticsEvents(30),
    fetchPosts(),
    fetchAllDailySummaries(),
  ]);
  return { users, events, posts, dailySummaries };
}

export default function AnalyticsPage() {
  const { data, loading, error, reload } = useApiData(loadAnalytics);

  return (
    <div>
      <PageHeader title="Analytics" description="Engagement, retention, and feature usage over the last 30 days." />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <AnalyticsView {...data} />}
    </div>
  );
}
