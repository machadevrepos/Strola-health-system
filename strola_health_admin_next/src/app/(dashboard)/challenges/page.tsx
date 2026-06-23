"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { ChallengesView } from "@/components/challenges/challenges-view";
import { fetchAllAwards, fetchBadges, fetchChallenges, fetchLeaderboard, fetchUsers } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

async function loadChallenges() {
  const [users, challenges, badges, awards] = await Promise.all([fetchUsers(), fetchChallenges(), fetchBadges(), fetchAllAwards()]);
  const counts = await Promise.all(challenges.map((c) => fetchLeaderboard(c.id)));
  const participantCounts = Object.fromEntries(challenges.map((c, i) => [c.id, counts[i].length]));
  const awardCounts = Object.fromEntries(badges.map((b) => [b.id, awards.filter((a) => a.badge_id === b.id).length]));
  return { challenges, participantCounts, badges, awardCounts, users };
}

export default function ChallengesPage() {
  const { data, loading, error, reload } = useApiData(loadChallenges);

  return (
    <div>
      <PageHeader
        title="Challenges & Badges"
        description="Curate official and community challenges, and manage the badge catalog."
      />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <ChallengesView {...data} />}
    </div>
  );
}
