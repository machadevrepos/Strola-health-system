"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { Plus, DotsThree, PencilSimple, Trash, Star, Lock, Globe, CircleNotch } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
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
import { ChallengeFormDialog, type ChallengeFormValues } from "@/components/challenges/challenge-form-dialog";
import { challengeStatus, findUserById, userDisplayName } from "@/lib/data/queries";
import {
  createChallenge as apiCreateChallenge,
  deleteChallenge as apiDeleteChallenge,
  setOfficialMonthly,
  updateChallenge,
} from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { useAuth } from "@/lib/auth-context";
import { formatDate, formatNumber } from "@/lib/format";
import { logAction } from "@/lib/audit-log-store";
import type { Challenge, UserProfile } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

export function ChallengesGrid({
  challenges: initialChallenges,
  participantCounts,
  users,
}: {
  challenges: Challenge[];
  participantCounts: Record<string, number>;
  users: UserProfile[];
}) {
  const router = useRouter();
  const { user: currentUser } = useAuth();
  const [challenges, setChallenges] = React.useState(initialChallenges);
  const [formOpen, setFormOpen] = React.useState(false);
  const [editTarget, setEditTarget] = React.useState<Challenge | null>(null);
  const [deleteTarget, setDeleteTarget] = React.useState<Challenge | null>(null);
  const [deleting, setDeleting] = React.useState(false);

  React.useEffect(() => setChallenges(initialChallenges), [initialChallenges]);

  async function createChallenge(values: ChallengeFormValues) {
    try {
      const created = await apiCreateChallenge({ ...values, created_by: currentUser?.uid });
      setChallenges((prev) => [created, ...prev]);
      toast.success("Challenge created");
      logAction("Created challenge", values.title);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't create challenge"));
    }
  }

  async function saveChallenge(values: ChallengeFormValues) {
    if (!editTarget) return;
    try {
      const updated = await updateChallenge(editTarget.id, values);
      setChallenges((prev) => prev.map((c) => (c.id === editTarget.id ? updated : c)));
      toast.success("Challenge updated");
      logAction("Edited challenge", values.title);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't update challenge"));
    } finally {
      setEditTarget(null);
    }
  }

  async function deleteChallenge() {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await apiDeleteChallenge(deleteTarget.id);
      setChallenges((prev) => prev.filter((c) => c.id !== deleteTarget.id));
      toast.success("Challenge deleted");
      logAction("Deleted challenge", deleteTarget.title);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't delete challenge"));
    } finally {
      setDeleting(false);
      setDeleteTarget(null);
    }
  }

  async function setOfficial(id: string) {
    const challenge = challenges.find((c) => c.id === id);
    try {
      await setOfficialMonthly(id);
      setChallenges((prev) => prev.map((c) => ({ ...c, is_official: c.id === id })));
      toast.success("Set as the official monthly challenge");
      logAction("Set official monthly challenge", challenge?.title ?? id);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't set official challenge"));
    }
  }

  return (
    <div>
      <div className="mb-3 flex justify-end">
        <Button size="sm" onClick={() => setFormOpen(true)}>
          <Plus size={14} /> Create challenge
        </Button>
      </div>

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {challenges.map((c) => {
          const status = challengeStatus(c);
          const creator = c.created_by ? findUserById(users, c.created_by) : undefined;
          return (
            <Card
              key={c.id}
              className="cursor-pointer border-border shadow-none transition-colors hover:bg-muted/50"
              onClick={() => router.push(`/challenges/${c.id}`)}
            >
              <CardContent>
                <div className="flex items-start justify-between gap-2">
                  <div className="flex items-center gap-2">
                    <span className="text-xl">{c.badge_emoji}</span>
                    <div>
                      <div className="flex items-center gap-1.5">
                        <span className="text-sm font-medium text-foreground">{c.title}</span>
                        {c.is_official && <Star size={13} weight="fill" className="text-brand-accent" />}
                      </div>
                      <p className="text-xs text-muted-foreground">
                        {formatDate(c.start_date)} - {formatDate(c.end_date)}
                      </p>
                    </div>
                  </div>
                  <DropdownMenu>
                    <DropdownMenuTrigger
                      render={
                        <button
                          type="button"
                          className="rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-foreground"
                          aria-label="Challenge actions"
                          onClick={(e) => e.stopPropagation()}
                        />
                      }
                    >
                      <DotsThree size={18} weight="bold" />
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end" onClick={(e) => e.stopPropagation()}>
                      <DropdownMenuItem onClick={() => setEditTarget(c)}>
                        <PencilSimple size={14} /> Edit
                      </DropdownMenuItem>
                      {!c.is_official && (
                        <DropdownMenuItem onClick={() => setOfficial(c.id)}>
                          <Star size={14} /> Set as official monthly
                        </DropdownMenuItem>
                      )}
                      <DropdownMenuItem variant="destructive" onClick={() => setDeleteTarget(c)}>
                        <Trash size={14} /> Delete
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>

                <p className="mt-2 line-clamp-2 text-sm text-muted-foreground">{c.description}</p>

                <p className="mt-2 text-xs text-muted-foreground">
                  Created by{" "}
                  {c.created_by ? (
                    <Link
                      href={`/users/${c.created_by}`}
                      onClick={(e) => e.stopPropagation()}
                      className="font-medium text-foreground hover:underline"
                    >
                      {userDisplayName(creator)}
                    </Link>
                  ) : (
                    <span className="font-medium text-foreground">Strolla Health</span>
                  )}
                  {creator?.role === "user" && (
                    <Badge variant="outline" className="ml-1.5 text-[10px]">
                      community
                    </Badge>
                  )}
                </p>

                <div className="mt-3 flex items-center justify-between text-sm">
                  <span className="font-mono text-muted-foreground">{formatNumber(c.goal_steps)} step goal</span>
                  <span className="font-mono text-muted-foreground">{participantCounts[c.id] ?? 0} joined</span>
                </div>

                <div className="mt-3 flex items-center gap-2">
                  <ChallengeStatusBadge status={status} />
                  <Badge variant="outline" className="gap-1">
                    {c.visibility === "private" ? <Lock size={11} /> : <Globe size={11} />}
                    {c.visibility}
                  </Badge>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      <ChallengeFormDialog open={formOpen} onOpenChange={setFormOpen} onSave={async (v) => { await createChallenge(v); setFormOpen(false); }} />
      <ChallengeFormDialog
        open={!!editTarget}
        onOpenChange={(open) => !open && setEditTarget(null)}
        challenge={editTarget}
        onSave={saveChallenge}
      />

      <AlertDialog open={!!deleteTarget} onOpenChange={(open) => !open && setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete &quot;{deleteTarget?.title}&quot;?</AlertDialogTitle>
            <AlertDialogDescription>
              This removes the challenge and every participant&apos;s progress in it. This cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleting}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={deleteChallenge} disabled={deleting} className="bg-destructive text-white hover:bg-destructive/90">
              {deleting && <CircleNotch size={14} className="animate-spin" />}
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
