"use client";

import { useParams } from "next/navigation";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { UserDetailView } from "@/components/users/user-detail-view";
import {
  fetchAnalyticsEvents,
  fetchBadges,
  fetchBadgesForUser,
  fetchChallenges,
  fetchChallengesForUser,
  fetchDailySummaryForUser,
  fetchDevicesForUser,
  fetchIntegrationConnections,
  fetchReports,
  fetchSessionsForUser,
  fetchSupportTickets,
  fetchUser,
  fetchUserNotes,
  fetchUsers,
} from "@/lib/data/api";
import { enrichAwards, enrichParticipants } from "@/lib/data/queries";
import { useApiData } from "@/lib/use-api-data";

async function loadUserDetail(userId: string) {
  const [
    user,
    sessions,
    dailySummary,
    devices,
    rawAwards,
    allBadges,
    rawParticipations,
    challenges,
    events,
    connections,
    reports,
    tickets,
    notes,
    staff,
  ] = await Promise.all([
    fetchUser(userId),
    fetchSessionsForUser(userId),
    // Full history, not just the last 30 days — "Lifetime stats" needs
    // everything the mock/backend has recorded for this account.
    fetchDailySummaryForUser(userId, 3650),
    fetchDevicesForUser(userId),
    fetchBadgesForUser(userId),
    fetchBadges(),
    fetchChallengesForUser(userId),
    fetchChallenges(),
    fetchAnalyticsEvents(365),
    fetchIntegrationConnections(),
    fetchReports(),
    fetchSupportTickets(),
    fetchUserNotes(userId),
    fetchUsers(),
  ]);
  return {
    user,
    sessions,
    dailySummary,
    devices,
    badges: enrichAwards(rawAwards, [user], allBadges),
    allBadges,
    participations: enrichParticipants(rawParticipations, [user]),
    challenges,
    events,
    connections: connections.filter((c) => c.user_id === userId),
    reports,
    tickets: tickets.filter((t) => t.user_id === userId),
    notes,
    staff,
  };
}

export default function UserDetailPage() {
  const { userId } = useParams<{ userId: string }>();
  const { data, loading, error, reload } = useApiData(() => loadUserDetail(userId), [userId]);

  if (loading) return <PageLoading />;
  if (error) return <PageError message={error} onRetry={reload} />;
  if (!data) return null;

  return (
    <UserDetailView
      user={data.user}
      sessions={data.sessions}
      dailySummary={data.dailySummary}
      devices={data.devices}
      badges={data.badges}
      allBadges={data.allBadges}
      participations={data.participations}
      challenges={data.challenges}
      events={data.events}
      connections={data.connections}
      reports={data.reports}
      tickets={data.tickets}
      notes={data.notes}
      staff={data.staff}
    />
  );
}
