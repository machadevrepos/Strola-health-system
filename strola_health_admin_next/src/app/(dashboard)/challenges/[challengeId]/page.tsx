"use client";

import { useParams } from "next/navigation";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { ChallengeDetailView } from "@/components/challenges/challenge-detail-view";
import { fetchChallenge, fetchLeaderboard, fetchUsers } from "@/lib/data/api";
import { enrichParticipants } from "@/lib/data/queries";
import { useApiData } from "@/lib/use-api-data";

async function loadChallengeDetail(challengeId: string) {
  const [challenge, rawParticipants, users] = await Promise.all([
    fetchChallenge(challengeId),
    fetchLeaderboard(challengeId),
    fetchUsers(),
  ]);
  return { challenge, participants: enrichParticipants(rawParticipants, users) };
}

export default function ChallengeDetailPage() {
  const { challengeId } = useParams<{ challengeId: string }>();
  const { data, loading, error, reload } = useApiData(() => loadChallengeDetail(challengeId), [challengeId]);

  if (loading) return <PageLoading />;
  if (error) return <PageError message={error} onRetry={reload} />;
  if (!data) return null;

  return <ChallengeDetailView challenge={data.challenge} participants={data.participants} />;
}
