"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { ChallengesView } from "@/components/challenges/challenges-view";
import { fetchChallenges, fetchLeaderboard, fetchUsers } from "@/lib/data/api";
import { enrichParticipants } from "@/lib/data/queries";
import { useApiData } from "@/lib/use-api-data";

async function loadChallenges() {
  const [users, challenges] = await Promise.all([fetchUsers(), fetchChallenges()]);
  const leaderboards = await Promise.all(challenges.map((c) => fetchLeaderboard(c.id)));
  const participantCounts = Object.fromEntries(challenges.map((c, i) => [c.id, leaderboards[i].length]));
  const leaderboardsByChallenge = Object.fromEntries(
    challenges.map((c, i) => [c.id, enrichParticipants(leaderboards[i], users)])
  );
  return { challenges, participantCounts, leaderboardsByChallenge, users };
}

export default function ChallengesPage() {
  const { data, loading, error, reload } = useApiData(loadChallenges);

  return (
    <div>
      <PageHeader
        title="Challenges"
        description="The official monthly challenge, plus community challenges members create for themselves."
      />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <ChallengesView {...data} />}
    </div>
  );
}
