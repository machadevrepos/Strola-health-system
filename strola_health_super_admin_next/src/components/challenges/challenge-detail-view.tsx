"use client";

import * as React from "react";
import Image from "next/image";
import Link from "next/link";
import { toast } from "sonner";
import { ArrowLeft, Trophy, UserMinus, Star, Lock, Globe, CircleNotch, Copy } from "@phosphor-icons/react";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { ChallengeStatusBadge } from "@/components/shell/status-badges";
import { challengeStatus, userDisplayName } from "@/lib/data/queries";
import { removeParticipant } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { formatDate, formatNumber, initials } from "@/lib/format";
import { logAction } from "@/lib/audit-log-store";
import type { EnrichedParticipant } from "@/lib/data/queries";
import type { Challenge } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

export function ChallengeDetailView({
  challenge,
  participants: initialParticipants,
}: {
  challenge: Challenge;
  participants: EnrichedParticipant[];
}) {
  const [participants, setParticipants] = React.useState(initialParticipants);
  const [kickTarget, setKickTarget] = React.useState<EnrichedParticipant | null>(null);
  const [kicking, setKicking] = React.useState(false);
  const status = challengeStatus(challenge);

  React.useEffect(() => setParticipants(initialParticipants), [initialParticipants]);

  async function kick() {
    if (!kickTarget) return;
    setKicking(true);
    try {
      await removeParticipant(challenge.id, kickTarget.user_id);
      setParticipants((prev) => prev.filter((p) => p.id !== kickTarget.id));
      toast.success(`${userDisplayName(kickTarget.user)} removed from the challenge`);
      logAction("Removed participant", `${userDisplayName(kickTarget.user)} from ${challenge.title}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't remove participant"));
    } finally {
      setKicking(false);
      setKickTarget(null);
    }
  }

  const active = participants.filter((p) => !p.left_at);
  // No "goal" concept — challenges are won by most steps, so progress is
  // shown relative to whoever's currently leading, not an arbitrary target.
  const leaderSteps = participants[0]?.steps ?? 0;

  return (
    <div>
      <Link href="/challenges" className="mb-4 inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft size={14} /> All challenges
      </Link>

      {challenge.image_url && (
        <div className="relative mb-4 h-40 w-full overflow-hidden rounded-lg sm:h-56">
          <Image src={challenge.image_url} alt="" fill className="object-cover" sizes="100vw" />
        </div>
      )}

      <div className="flex flex-wrap items-start justify-between gap-3 pb-5">
        <div className="flex items-center gap-3">
          <span className="text-3xl">{challenge.badge_emoji}</span>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-lg font-semibold tracking-tight text-foreground">{challenge.title}</h1>
              {challenge.is_official && <Star size={15} weight="fill" className="text-brand-accent" />}
            </div>
            <p className="text-sm text-muted-foreground">{challenge.description}</p>
          </div>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          {challenge.status === "draft" && <Badge variant="outline">Draft</Badge>}
          {challenge.status === "archived" && <Badge variant="secondary">Archived</Badge>}
          {challenge.status === "published" && <ChallengeStatusBadge status={status} />}
          <Badge variant="outline" className="gap-1">
            {challenge.visibility === "private" ? <Lock size={11} /> : <Globe size={11} />}
            {challenge.visibility}
          </Badge>
        </div>
      </div>

      {challenge.visibility === "private" && challenge.invite_code && (
        <Card className="mb-4 border-border shadow-none">
          <CardContent className="flex items-center justify-between gap-3">
            <div>
              <h3 className="text-sm font-medium text-foreground">Invite code</h3>
              <p className="mt-0.5 font-mono text-sm text-muted-foreground">{challenge.invite_code}</p>
            </div>
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                navigator.clipboard.writeText(challenge.invite_code!);
                toast.success("Invite code copied");
              }}
            >
              <Copy size={14} /> Copy
            </Button>
          </CardContent>
        </Card>
      )}

      {challenge.rules && (
        <Card className="mb-4 border-border shadow-none">
          <CardContent>
            <h3 className="mb-1.5 text-sm font-medium text-foreground">Rules</h3>
            <p className="text-sm text-muted-foreground">{challenge.rules}</p>
          </CardContent>
        </Card>
      )}

      <div className="mb-4 grid grid-cols-3 gap-3">
        <Card className="border-border p-3 shadow-none">
          <p className="text-xs text-muted-foreground">Participants</p>
          <p className="font-mono text-lg font-semibold text-foreground">{active.length}</p>
        </Card>
        <Card className="border-border p-3 shadow-none">
          <p className="text-xs text-muted-foreground">Starts</p>
          <p className="text-sm font-medium text-foreground">{formatDate(challenge.start_date)}</p>
        </Card>
        <Card className="border-border p-3 shadow-none">
          <p className="text-xs text-muted-foreground">Ends</p>
          <p className="text-sm font-medium text-foreground">{formatDate(challenge.end_date)}</p>
        </Card>
      </div>

      <Card className="border-border shadow-none">
        <CardContent>
          <h3 className="mb-3 text-sm font-medium text-foreground">Leaderboard</h3>
          {participants.length === 0 ? (
            <div className="flex flex-col items-center gap-2 py-10 text-center text-muted-foreground">
              <Trophy size={20} />
              <p className="text-sm">No one has joined yet.</p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <TableHead className="w-10">#</TableHead>
                  <TableHead>Participant</TableHead>
                  <TableHead>Steps</TableHead>
                  <TableHead>% of leader</TableHead>
                  <TableHead>Joined</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="w-10" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {participants.map((p, i) => (
                  <TableRow key={p.id}>
                    <TableCell className="font-mono text-muted-foreground">{i + 1}</TableCell>
                    <TableCell>
                      <Link href={`/users/${p.user_id}`} className="flex items-center gap-2 hover:underline">
                        <Avatar className="size-6">
                          <AvatarFallback className="text-[10px]">{initials(userDisplayName(p.user))}</AvatarFallback>
                        </Avatar>
                        {userDisplayName(p.user)}
                      </Link>
                    </TableCell>
                    <TableCell className="font-mono">{formatNumber(p.steps)}</TableCell>
                    <TableCell className="w-32">
                      <div className="flex items-center gap-2">
                        <div className="h-1.5 w-16 overflow-hidden rounded-full bg-muted">
                          <div
                            className="h-full rounded-full bg-primary"
                            style={{ width: `${leaderSteps > 0 ? Math.round((p.steps / leaderSteps) * 100) : 0}%` }}
                          />
                        </div>
                        <span className="font-mono text-xs text-muted-foreground">
                          {leaderSteps > 0 ? Math.round((p.steps / leaderSteps) * 100) : 0}%
                        </span>
                      </div>
                    </TableCell>
                    <TableCell className="text-muted-foreground">{formatDate(p.joined_at)}</TableCell>
                    <TableCell>
                      {p.left_at ? <Badge variant="secondary">Left</Badge> : <Badge className="bg-success/15 text-success">Active</Badge>}
                    </TableCell>
                    <TableCell>
                      {!p.left_at && (
                        <Button variant="ghost" size="icon-sm" aria-label="Remove participant" onClick={() => setKickTarget(p)}>
                          <UserMinus size={14} />
                        </Button>
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <AlertDialog open={!!kickTarget} onOpenChange={(open) => !open && setKickTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Remove {kickTarget ? userDisplayName(kickTarget.user) : "this participant"}?</AlertDialogTitle>
            <AlertDialogDescription>
              They&apos;ll be removed from this challenge&apos;s leaderboard immediately. They can rejoin later if it&apos;s still active.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={kicking}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={kick} disabled={kicking} className="bg-destructive text-white hover:bg-destructive/90">
              {kicking && <CircleNotch size={14} className="animate-spin" />}
              Remove
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
