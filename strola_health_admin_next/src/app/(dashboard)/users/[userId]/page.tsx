"use client";

import { useParams } from "next/navigation";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { UserDetailView } from "@/components/users/user-detail-view";
import {
  fetchBadges,
  fetchBadgesForUser,
  fetchChallenges,
  fetchChallengesForUser,
  fetchDailySummaryForUser,
  fetchDevicesForUser,
  fetchSessionsForUser,
  fetchUser,
} from "@/lib/data/api";
import { enrichAwards, enrichParticipants } from "@/lib/data/queries";
import { useApiData } from "@/lib/use-api-data";

async function loadUserDetail(userId: string) {
  const [user, sessions, dailySummary, devices, rawAwards, allBadges, rawParticipations, challenges] = await Promise.all([
    fetchUser(userId),
    fetchSessionsForUser(userId),
    fetchDailySummaryForUser(userId),
    fetchDevicesForUser(userId),
    fetchBadgesForUser(userId),
    fetchBadges(),
    fetchChallengesForUser(userId),
    fetchChallenges(),
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
    />
  );
}
