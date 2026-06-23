"use client";

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ChallengesGrid } from "@/components/challenges/challenges-grid";
import { BadgesGrid } from "@/components/challenges/badges-grid";
import type { Badge, Challenge, UserProfile } from "@/lib/types";

export function ChallengesView({
  challenges,
  participantCounts,
  badges,
  awardCounts,
  users,
}: {
  challenges: Challenge[];
  participantCounts: Record<string, number>;
  badges: Badge[];
  awardCounts: Record<string, number>;
  users: UserProfile[];
}) {
  return (
    <Tabs defaultValue="challenges">
      <TabsList>
        <TabsTrigger value="challenges">Challenges ({challenges.length})</TabsTrigger>
        <TabsTrigger value="badges">Badges ({badges.length})</TabsTrigger>
      </TabsList>
      <TabsContent value="challenges" className="mt-4">
        <ChallengesGrid challenges={challenges} participantCounts={participantCounts} users={users} />
      </TabsContent>
      <TabsContent value="badges" className="mt-4">
        <BadgesGrid badges={badges} awardCounts={awardCounts} />
      </TabsContent>
    </Tabs>
  );
}
