"use client";

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ChallengesGrid } from "@/components/challenges/challenges-grid";
import { CompletedChallengesPanel } from "@/components/challenges/completed-challenges-panel";
import { challengeStatus } from "@/lib/data/queries";
import type { EnrichedParticipant } from "@/lib/data/queries";
import type { Challenge, UserProfile } from "@/lib/types";

export function ChallengesView({
  challenges,
  participantCounts,
  leaderboardsByChallenge,
  users,
}: {
  challenges: Challenge[];
  participantCounts: Record<string, number>;
  leaderboardsByChallenge: Record<string, EnrichedParticipant[]>;
  users: UserProfile[];
}) {
  const completedCount = challenges.filter((c) => c.status === "archived" || challengeStatus(c) === "ended").length;

  return (
    <Tabs defaultValue="challenges">
      <TabsList>
        <TabsTrigger value="challenges">Challenges ({challenges.length})</TabsTrigger>
        <TabsTrigger value="completed">Completed ({completedCount})</TabsTrigger>
      </TabsList>
      <TabsContent value="challenges" className="mt-4">
        <ChallengesGrid challenges={challenges} participantCounts={participantCounts} users={users} />
      </TabsContent>
      <TabsContent value="completed" className="mt-4">
        <CompletedChallengesPanel challenges={challenges} leaderboardsByChallenge={leaderboardsByChallenge} />
      </TabsContent>
    </Tabs>
  );
}
