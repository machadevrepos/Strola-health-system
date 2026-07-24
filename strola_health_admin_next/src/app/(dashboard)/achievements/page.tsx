"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { BadgesGrid } from "@/components/challenges/badges-grid";
import { fetchAllAwards, fetchBadges } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

async function loadAchievements() {
  const [badges, awards] = await Promise.all([fetchBadges(), fetchAllAwards()]);
  const awardCounts = Object.fromEntries(badges.map((b) => [b.id, awards.filter((a) => a.badge_id === b.id).length]));
  return { badges, awardCounts };
}

export default function AchievementsPage() {
  const { data, loading, error, reload } = useApiData(loadAchievements);

  return (
    <div>
      <PageHeader
        title="Achievements"
        description="Manage the badge catalog shown in the app's Achievements screen."
      />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <BadgesGrid badges={data.badges} awardCounts={data.awardCounts} />}
    </div>
  );
}
