"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { PencilSimple, Trophy, Star } from "@phosphor-icons/react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { WinnerNotesDialog, type WinnerNotesValues } from "@/components/challenges/winner-notes-dialog";
import { challengeStatus, userDisplayName } from "@/lib/data/queries";
import { updateChallenge } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { logAction } from "@/lib/audit-log-store";
import { formatDate, formatNumber } from "@/lib/format";
import type { EnrichedParticipant } from "@/lib/data/queries";
import type { Challenge } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

export function CompletedChallengesPanel({
  challenges: initialChallenges,
  leaderboardsByChallenge,
}: {
  challenges: Challenge[];
  leaderboardsByChallenge: Record<string, EnrichedParticipant[]>;
}) {
  const router = useRouter();
  const [challenges, setChallenges] = React.useState(initialChallenges);
  const [editTarget, setEditTarget] = React.useState<Challenge | null>(null);

  const completed = challenges
    .filter((c) => c.status === "archived" || challengeStatus(c) === "ended")
    .sort((a, b) => +new Date(b.end_date) - +new Date(a.end_date));

  async function saveWinner(values: WinnerNotesValues) {
    if (!editTarget) return;
    try {
      const updated = await updateChallenge(editTarget.id, values);
      setChallenges((prev) => prev.map((c) => (c.id === editTarget.id ? updated : c)));
      toast.success("Winner info updated");
      logAction("Edited challenge winner info", editTarget.title);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't update winner info"));
    } finally {
      setEditTarget(null);
    }
  }

  if (completed.length === 0) {
    return (
      <div className="flex flex-col items-center gap-2 py-16 text-center text-muted-foreground">
        <Trophy size={24} />
        <p className="text-sm">No challenges have ended yet.</p>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {completed.map((c) => {
        const leaderboard = leaderboardsByChallenge[c.id] ?? [];
        const winner = c.winner_user_id ? leaderboard.find((p) => p.user_id === c.winner_user_id) : undefined;
        return (
          <Card
            key={c.id}
            className="cursor-pointer border-border shadow-none transition-colors hover:bg-muted/50"
            onClick={() => router.push(`/challenges/${c.id}`)}
          >
            <CardContent>
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-center gap-2.5">
                  <span className="text-xl">{c.badge_emoji}</span>
                  <div>
                    <div className="flex items-center gap-1.5">
                      <span className="text-sm font-medium text-foreground">{c.title}</span>
                      {c.is_official && <Star size={12} weight="fill" className="text-brand-accent" />}
                    </div>
                    <p className="text-xs text-muted-foreground">
                      {formatDate(c.start_date)} – {formatDate(c.end_date)}
                    </p>
                  </div>
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={(e) => {
                    e.stopPropagation();
                    setEditTarget(c);
                  }}
                >
                  <PencilSimple size={14} /> Edit winner
                </Button>
              </div>

              <div className="mt-3 flex items-center gap-2">
                {winner ? (
                  <Badge className="gap-1 bg-brand-accent/20 text-brand-accent-strong">
                    <Trophy size={12} /> {userDisplayName(winner.user)} — {formatNumber(winner.steps)} steps
                  </Badge>
                ) : (
                  <Badge variant="outline">No winner set</Badge>
                )}
                <Badge variant="outline" className="text-[11px]">
                  {c.winner_type === "goal_completion_pct" ? "By goal completion %" : "By most steps"}
                </Badge>
              </div>

              {c.admin_notes && (
                <p className="mt-2 text-xs text-muted-foreground">
                  Notes: <span className="text-foreground">{c.admin_notes}</span>
                </p>
              )}
            </CardContent>
          </Card>
        );
      })}

      <WinnerNotesDialog
        challenge={editTarget}
        participants={editTarget ? leaderboardsByChallenge[editTarget.id] ?? [] : []}
        onOpenChange={(open) => !open && setEditTarget(null)}
        onSave={saveWinner}
      />
    </div>
  );
}
