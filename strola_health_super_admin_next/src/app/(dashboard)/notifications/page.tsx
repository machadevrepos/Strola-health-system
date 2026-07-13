"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { NotificationsView } from "@/components/notifications/notifications-view";
import {
  fetchAllDevices,
  fetchAnalyticsEvents,
  fetchChallenges,
  fetchLeaderboard,
  fetchPushNotifications,
  fetchUsers,
} from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

async function loadNotifications() {
  const [users, events, devices, challenges, history] = await Promise.all([
    fetchUsers(),
    fetchAnalyticsEvents(30),
    fetchAllDevices(),
    fetchChallenges(),
    fetchPushNotifications(),
  ]);
  const leaderboards = await Promise.all(challenges.map((c) => fetchLeaderboard(c.id)));
  const participants = leaderboards.flat();
  return { users, events, devices, participants, history };
}

export default function NotificationsPage() {
  const { data, loading, error, reload } = useApiData(loadNotifications);

  return (
    <div>
      <PageHeader
        title="Push Notifications"
        description="Send a push to everyone, or a specific segment — new challenges, features, holiday messages, maintenance notices."
      />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <NotificationsView {...data} onSent={reload} />}
    </div>
  );
}
