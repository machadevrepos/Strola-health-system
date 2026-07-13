"use client";

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ChallengesGrid } from "@/components/challenges/challenges-grid";
import { BadgesGrid } from "@/components/challenges/badges-grid";
import { CompletedChallengesPanel } from "@/components/challenges/completed-challenges-panel";
import { challengeStatus } from "@/lib/data/queries";
import type { EnrichedParticipant } from "@/lib/data/queries";
import type { Badge, Challenge, UserProfile } from "@/lib/types";

export function ChallengesView({
  challenges,
  participantCounts,
  leaderboardsByChallenge,
  badges,
  awardCounts,
  users,
}: {
  challenges: Challenge[];
  participantCounts: Record<string, number>;
  leaderboardsByChallenge: Record<string, EnrichedParticipant[]>;
  badges: Badge[];
  awardCounts: Record<string, number>;
  users: UserProfile[];
}) {
  const completedCount = challenges.filter((c) => c.status === "archived" || challengeStatus(c) === "ended").length;

  return (
    <Tabs defaultValue="challenges">
      <TabsList>
        <TabsTrigger value="challenges">Challenges ({challenges.length})</TabsTrigger>
        <TabsTrigger value="completed">Completed ({completedCount})</TabsTrigger>
        <TabsTrigger value="badges">Badges ({badges.length})</TabsTrigger>
      </TabsList>
      <TabsContent value="challenges" className="mt-4">
        <ChallengesGrid challenges={challenges} participantCounts={participantCounts} users={users} />
      </TabsContent>
      <TabsContent value="completed" className="mt-4">
        <CompletedChallengesPanel challenges={challenges} leaderboardsByChallenge={leaderboardsByChallenge} />
      </TabsContent>
      <TabsContent value="badges" className="mt-4">
        <BadgesGrid badges={badges} awardCounts={awardCounts} />
      </TabsContent>
    </Tabs>
  );
}
