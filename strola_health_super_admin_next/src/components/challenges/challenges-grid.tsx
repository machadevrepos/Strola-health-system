"use client";

import * as React from "react";
import Image from "next/image";
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
import { OfficialChallengeFormDialog, type OfficialChallengeFormValues } from "@/components/challenges/official-challenge-form-dialog";
import { challengeStatus, findUserById, userDisplayName } from "@/lib/data/queries";
import {
  createChallenge as apiCreateChallenge,
  deleteChallenge as apiDeleteChallenge,
  setOfficialMonthly,
  updateChallenge,
} from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { useAuth } from "@/lib/auth-context";
import { formatDate } from "@/lib/format";
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
  const [officialFormOpen, setOfficialFormOpen] = React.useState(false);
  const [officialEditTarget, setOfficialEditTarget] = React.useState<Challenge | null>(null);
  const [prepFormOpen, setPrepFormOpen] = React.useState(false);
  const [deleteTarget, setDeleteTarget] = React.useState<Challenge | null>(null);
  const [deleting, setDeleting] = React.useState(false);

  React.useEffect(() => setChallenges(initialChallenges), [initialChallenges]);

  const official = challenges.find((c) => c.is_official);
  const others = challenges.filter((c) => c.id !== official?.id);
  // Genuine member-made challenges only — `others` alone also catches
  // archived/draft challenges that were (or will be) the official one but
  // aren't *currently* it, and those are still `visibility: "public"`
  // correctly. Lumping them in here read as a "Private challenges" section
  // that still showed a public/globe badge on some cards — the actual bug
  // behind that, not literal hardcoding in the badge itself (that part
  // already renders `c.visibility` correctly either way).
  const community = others.filter((c) => c.visibility === "private");
  const otherPublic = others.filter((c) => c.visibility === "public");
  // The challenge prepared ahead of time for next month, if one exists —
  // there's only ever meant to be one at a time (onChallengeStart promotes
  // whichever has the earliest start_date if somehow more than one is due).
  const pendingDraft = otherPublic.find((c) => c.status === "draft");

  function openCreateOfficial() {
    setOfficialEditTarget(null);
    setOfficialFormOpen(true);
  }

  function openEditOfficial(challenge: Challenge) {
    setOfficialEditTarget(challenge);
    setOfficialFormOpen(true);
  }

  async function saveOfficial(values: OfficialChallengeFormValues) {
    try {
      if (officialEditTarget) {
        const updated = await updateChallenge(officialEditTarget.id, values);
        setChallenges((prev) => prev.map((c) => (c.id === officialEditTarget.id ? updated : c)));
        toast.success("Official challenge updated");
        logAction("Edited official challenge", values.title);
      } else {
        const created = await apiCreateChallenge({
          ...values,
          visibility: "public",
          winner_type: "most_steps",
          created_by: currentUser?.uid,
        });
        // Goes live immediately — there's no separate draft/publish step for
        // the official challenge, this replaces whichever one was official
        // before it.
        await setOfficialMonthly(created.id);
        setChallenges((prev) => [{ ...created, is_official: true }, ...prev.map((c) => ({ ...c, is_official: false }))]);
        toast.success(`"${created.title}" is now the official monthly challenge`);
        logAction("Created official challenge", values.title);
      }
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't save this challenge"));
    } finally {
      setOfficialFormOpen(false);
      setOfficialEditTarget(null);
    }
  }

  // Prepares (or edits) next month's challenge as a draft — doesn't touch
  // the current official challenge, doesn't go live, and doesn't carry over
  // the current challenge's participants (it's a brand new challenge
  // document, not an edit of the live one). onChallengeStart promotes it
  // automatically once its start_date arrives; publishNow below promotes it
  // early on demand.
  async function savePrepared(values: OfficialChallengeFormValues) {
    try {
      if (pendingDraft) {
        const updated = await updateChallenge(pendingDraft.id, values);
        setChallenges((prev) => prev.map((c) => (c.id === pendingDraft.id ? updated : c)));
        toast.success("Prepared challenge updated");
        logAction("Updated prepared challenge", values.title);
      } else {
        const created = await apiCreateChallenge({
          ...values,
          visibility: "public",
          winner_type: "most_steps",
          created_by: currentUser?.uid,
          status: "draft",
        });
        setChallenges((prev) => [created, ...prev]);
        toast.success(`"${created.title}" prepared — it'll go live automatically on ${formatDate(created.start_date)}`);
        logAction("Prepared next official challenge", values.title);
      }
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't save this challenge"));
    } finally {
      setPrepFormOpen(false);
    }
  }

  async function publishNow(target: Challenge) {
    try {
      await setOfficialMonthly(target.id);
      setChallenges((prev) =>
        prev.map((c) => {
          if (c.id === target.id) return { ...c, is_official: true, status: "published" };
          return c.is_official ? { ...c, is_official: false } : c;
        })
      );
      toast.success(`"${target.title}" is now the official monthly challenge`);
      logAction("Published prepared challenge early", target.title);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't publish this challenge"));
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

  return (
    <div className="space-y-7">
      <section>
        <div className="mb-2 flex items-center justify-between">
          <div>
            <h3 className="text-sm font-medium text-foreground">Official monthly challenge</h3>
            <p className="text-xs text-muted-foreground">The one recurring public challenge everyone sees — most steps wins.</p>
          </div>
          <div className="flex items-center gap-2">
            {!official && (
              <Button size="sm" onClick={openCreateOfficial}>
                <Plus size={14} /> Set up official challenge
              </Button>
            )}
            <Button size="sm" variant="outline" onClick={() => setPrepFormOpen(true)}>
              <Plus size={14} /> {pendingDraft ? "Edit prepared challenge" : "Prepare next month's challenge"}
            </Button>
          </div>
        </div>
        {official ? (
          <Card
            className="cursor-pointer border-border shadow-none transition-colors hover:bg-muted/50"
            onClick={() => router.push(`/challenges/${official.id}`)}
          >
            <CardContent className="flex flex-col gap-4 sm:flex-row">
              {official.image_url && (
                <div className="relative h-32 w-full shrink-0 overflow-hidden rounded-md sm:w-48">
                  <Image src={official.image_url} alt="" fill className="object-cover" sizes="192px" />
                </div>
              )}
              <div className="min-w-0 flex-1">
                <div className="flex items-start justify-between gap-2">
                  <div className="flex items-center gap-2">
                    <span className="text-xl">{official.badge_emoji}</span>
                    <div>
                      <div className="flex items-center gap-1.5">
                        <span className="text-sm font-medium text-foreground">{official.title}</span>
                        <Star size={13} weight="fill" className="text-brand-accent" />
                      </div>
                      <p className="text-xs text-muted-foreground">
                        {formatDate(official.start_date)} - {formatDate(official.end_date)}
                      </p>
                    </div>
                  </div>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={(e) => {
                      e.stopPropagation();
                      openEditOfficial(official);
                    }}
                  >
                    <PencilSimple size={14} /> Edit
                  </Button>
                </div>
                <p className="mt-2 line-clamp-2 text-sm text-muted-foreground">{official.description}</p>
                <div className="mt-3 flex flex-wrap items-center gap-2 text-sm">
                  <span className="font-mono text-muted-foreground">{participantCounts[official.id] ?? 0} joined</span>
                  <ChallengeStatusBadge status={challengeStatus(official)} />
                </div>
              </div>
            </CardContent>
          </Card>
        ) : (
          <p className="py-6 text-sm text-muted-foreground">No official challenge set yet.</p>
        )}
      </section>

      <section>
        <h3 className="mb-1 text-sm font-medium text-foreground">Private challenges ({community.length})</h3>
        <p className="mb-3 text-xs text-muted-foreground">
          Created by members for themselves and their friends — view here for moderation, not editable.
        </p>
        {community.length === 0 ? (
          <p className="py-6 text-sm text-muted-foreground">No private challenges yet.</p>
        ) : (
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {community.map((c) => (
              <ChallengeMiniCard
                key={c.id}
                challenge={c}
                users={users}
                participantCount={participantCounts[c.id] ?? 0}
                onOpen={() => router.push(`/challenges/${c.id}`)}
                onDelete={() => setDeleteTarget(c)}
              />
            ))}
          </div>
        )}
      </section>

      {otherPublic.length > 0 && (
        <section>
          <h3 className="mb-1 text-sm font-medium text-foreground">Other public challenges ({otherPublic.length})</h3>
          <p className="mb-3 text-xs text-muted-foreground">
            Past or upcoming official challenges that aren&apos;t the current one — archived, draft, or scheduled.
          </p>
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {otherPublic.map((c) => (
              <ChallengeMiniCard
                key={c.id}
                challenge={c}
                users={users}
                participantCount={participantCounts[c.id] ?? 0}
                onOpen={() => router.push(`/challenges/${c.id}`)}
                onDelete={() => setDeleteTarget(c)}
                onPublishNow={c.status === "draft" ? () => publishNow(c) : undefined}
              />
            ))}
          </div>
        </section>
      )}

      <OfficialChallengeFormDialog
        open={officialFormOpen}
        onOpenChange={(open) => {
          setOfficialFormOpen(open);
          if (!open) setOfficialEditTarget(null);
        }}
        challenge={officialEditTarget}
        onSave={saveOfficial}
      />

      <OfficialChallengeFormDialog
        open={prepFormOpen}
        onOpenChange={setPrepFormOpen}
        challenge={pendingDraft}
        onSave={savePrepared}
        mode="prepare"
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

// Shared by both the "Private challenges" and "Other public challenges"
// grids — same card, just fed from a differently-filtered list. Renders
// `challenge.visibility` as-is (Lock for private, Globe for public); which
// list a card ends up in is what determines that, not this component.
function ChallengeMiniCard({
  challenge: c,
  users,
  participantCount,
  onOpen,
  onDelete,
  onPublishNow,
}: {
  challenge: Challenge;
  users: UserProfile[];
  participantCount: number;
  onOpen: () => void;
  onDelete: () => void;
  // Only passed for a challenge prepared ahead of time and still a draft —
  // promotes it to official immediately instead of waiting for its
  // start_date (onChallengeStart does that automatically otherwise).
  onPublishNow?: () => void;
}) {
  const status = challengeStatus(c);
  const creator = c.created_by ? findUserById(users, c.created_by) : undefined;
  return (
    <Card className="cursor-pointer border-border shadow-none transition-colors hover:bg-muted/50" onClick={onOpen}>
      <CardContent>
        <div className="flex items-start justify-between gap-2">
          <div className="flex items-center gap-2">
            <span className="text-xl">{c.badge_emoji}</span>
            <div>
              <span className="text-sm font-medium text-foreground">{c.title}</span>
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
              {onPublishNow && (
                <DropdownMenuItem
                  onClick={(e) => {
                    e.stopPropagation();
                    onPublishNow();
                  }}
                >
                  <Star size={14} /> Publish now
                </DropdownMenuItem>
              )}
              <DropdownMenuItem
                variant="destructive"
                onClick={(e) => {
                  e.stopPropagation();
                  onDelete();
                }}
              >
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
        </p>

        <div className="mt-3 flex items-center justify-between text-sm">
          <span className="font-mono text-muted-foreground">{participantCount} joined</span>
        </div>

        <div className="mt-3 flex flex-wrap items-center gap-2">
          {c.status === "draft" && <Badge variant="secondary">Draft — starts {formatDate(c.start_date)}</Badge>}
          {c.status === "archived" && <Badge variant="secondary">Archived</Badge>}
          {c.status === "published" && <ChallengeStatusBadge status={status} />}
          <Badge variant="outline" className="gap-1">
            {c.visibility === "private" ? <Lock size={11} /> : <Globe size={11} />}
            {c.visibility}
          </Badge>
        </div>
      </CardContent>
    </Card>
  );
}
