"use client";

import * as React from "react";
import Link from "next/link";
import {
  CaretDown,
  Prohibit,
  SpeakerSimpleSlash,
  Trash,
  UserMinus,
  Warning,
} from "@phosphor-icons/react";
import { ReportStatusBadge } from "@/components/shell/status-badges";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { ResolveReportDialog } from "@/components/moderation/resolve-report-dialog";
import { WarnUserDialog } from "@/components/moderation/warn-user-dialog";
import { MuteUserDialog, type MuteTarget } from "@/components/moderation/mute-user-dialog";
import { DeleteAllPostsDialog, type DeleteAllPostsTarget } from "@/components/moderation/delete-all-posts-dialog";
import { BanUserDialog } from "@/components/users/ban-user-dialog";
import { DeleteAccountDialog } from "@/components/users/delete-account-dialog";
import { groupReportsByTarget, moderationHistoryForUser, userDisplayName } from "@/lib/data/queries";
import { formatDate, formatDateTime, initials, titleCase } from "@/lib/format";
import type { EnrichedPost, EnrichedReport, GroupedReport } from "@/lib/data/queries";
import type { ReportStatus, UserProfile } from "@/lib/types";

export function ReportsPanel({
  reports,
  posts,
  onDismiss,
  onRemovePost,
  onWarnUser,
  onMuteUser,
  onBanUser,
  onDeleteAccount,
  onDeleteAllPosts,
}: {
  reports: EnrichedReport[];
  posts: EnrichedPost[];
  onDismiss: (reportIds: string[], note: string) => void | Promise<void>;
  onRemovePost: (reportIds: string[], postId: string) => void | Promise<void>;
  onWarnUser: (reportIds: string[], userId: string, reason: string) => void | Promise<void>;
  onMuteUser: (reportIds: string[], userId: string, hours: number, reason: string) => void | Promise<void>;
  onBanUser: (reportIds: string[], userId: string, reason: string) => void | Promise<void>;
  onDeleteAccount: (reportIds: string[], userId: string) => void | Promise<void>;
  onDeleteAllPosts: (reportIds: string[], userId: string) => void | Promise<void>;
}) {
  const [dismissTarget, setDismissTarget] = React.useState<EnrichedReport | null>(null);
  const [warnTarget, setWarnTarget] = React.useState<{ group: GroupedReport; user: UserProfile } | null>(null);
  const [muteTarget, setMuteTarget] = React.useState<{ group: GroupedReport; target: MuteTarget } | null>(null);
  const [banTarget, setBanTarget] = React.useState<{ group: GroupedReport; user: UserProfile } | null>(null);
  const [deleteAccountTarget, setDeleteAccountTarget] = React.useState<{ group: GroupedReport; user: UserProfile } | null>(null);
  const [deleteAllPostsTarget, setDeleteAllPostsTarget] = React.useState<{ group: GroupedReport; target: DeleteAllPostsTarget } | null>(null);

  const groups = groupReportsByTarget(reports);
  const openGroups = groups.filter((g) => g.hasOpen);
  const resolvedGroups = groups.filter((g) => !g.hasOpen);

  return (
    <div className="space-y-6">
      <section>
        <h3 className="mb-2 text-sm font-medium text-foreground">Open ({openGroups.length})</h3>
        {openGroups.length === 0 ? (
          <p className="py-6 text-sm text-muted-foreground">No open reports. Nice and quiet.</p>
        ) : (
          <div className="space-y-3">
            {openGroups.map((g) => (
              <ReportGroupCard
                key={`${g.targetType}:${g.targetId}`}
                group={g}
                allReports={reports}
                posts={posts}
                onDismissClick={() => setDismissTarget(g.reports.find((r) => r.status === "open") ?? g.reports[0])}
                onRemoveClick={g.targetPost ? () => onRemovePost(openReportIds(g), g.targetId) : undefined}
                onWarnClick={g.targetUser ? () => setWarnTarget({ group: g, user: g.targetUser! }) : undefined}
                onMuteClick={
                  g.targetUser
                    ? (hours) => setMuteTarget({ group: g, target: { userId: g.targetUser!.id, userName: userDisplayName(g.targetUser!), hours } })
                    : undefined
                }
                onBanClick={g.targetUser ? () => setBanTarget({ group: g, user: g.targetUser! }) : undefined}
                onDeleteAccountClick={g.targetUser ? () => setDeleteAccountTarget({ group: g, user: g.targetUser! }) : undefined}
                onDeleteAllPostsClick={
                  g.targetUser
                    ? () => {
                        const postCount = posts.filter((p) => p.author_id === g.targetUser!.id).length;
                        setDeleteAllPostsTarget({ group: g, target: { userId: g.targetUser!.id, userName: userDisplayName(g.targetUser!), postCount } });
                      }
                    : undefined
                }
              />
            ))}
          </div>
        )}
      </section>

      {resolvedGroups.length > 0 && (
        <section>
          <h3 className="mb-2 text-sm font-medium text-foreground">Resolved history ({resolvedGroups.length})</h3>
          <div className="space-y-3">
            {resolvedGroups.map((g) => (
              <ReportGroupCard key={`${g.targetType}:${g.targetId}`} group={g} allReports={reports} posts={posts} />
            ))}
          </div>
        </section>
      )}

      <ResolveReportDialog
        report={dismissTarget}
        onOpenChange={(open) => !open && setDismissTarget(null)}
        onResolve={async (status: ReportStatus, note: string) => {
          if (!dismissTarget) return;
          const group = groups.find((g) => g.targetType === dismissTarget.target_type && g.targetId === dismissTarget.target_id);
          await onDismiss(group ? openReportIds(group) : [dismissTarget.id], note);
          setDismissTarget(null);
        }}
      />

      <WarnUserDialog
        target={warnTarget ? { userId: warnTarget.user.id, userName: userDisplayName(warnTarget.user) } : null}
        onOpenChange={(open) => !open && setWarnTarget(null)}
        onConfirm={async (reason) => {
          if (warnTarget) await onWarnUser(openReportIds(warnTarget.group), warnTarget.user.id, reason);
          setWarnTarget(null);
        }}
      />

      <MuteUserDialog
        target={muteTarget?.target ?? null}
        onOpenChange={(open) => !open && setMuteTarget(null)}
        onConfirm={async (reason) => {
          if (muteTarget) await onMuteUser(openReportIds(muteTarget.group), muteTarget.target.userId, muteTarget.target.hours, reason);
          setMuteTarget(null);
        }}
      />

      <BanUserDialog
        user={banTarget?.user ?? null}
        onOpenChange={(open) => !open && setBanTarget(null)}
        onConfirm={async (reason) => {
          if (banTarget) await onBanUser(openReportIds(banTarget.group), banTarget.user.id, reason);
          setBanTarget(null);
        }}
      />

      {deleteAccountTarget && (
        <DeleteAccountDialog
          user={deleteAccountTarget.user}
          open
          onOpenChange={(open) => !open && setDeleteAccountTarget(null)}
          onConfirm={async () => {
            await onDeleteAccount(openReportIds(deleteAccountTarget.group), deleteAccountTarget.user.id);
            setDeleteAccountTarget(null);
          }}
        />
      )}

      <DeleteAllPostsDialog
        target={deleteAllPostsTarget?.target ?? null}
        onOpenChange={(open) => !open && setDeleteAllPostsTarget(null)}
        onConfirm={async () => {
          if (deleteAllPostsTarget) await onDeleteAllPosts(openReportIds(deleteAllPostsTarget.group), deleteAllPostsTarget.target.userId);
          setDeleteAllPostsTarget(null);
        }}
      />
    </div>
  );
}

function openReportIds(group: GroupedReport): string[] {
  return group.reports.filter((r) => r.status === "open").map((r) => r.id);
}

function ReportGroupCard({
  group,
  allReports,
  posts,
  onDismissClick,
  onRemoveClick,
  onWarnClick,
  onMuteClick,
  onBanClick,
  onDeleteAccountClick,
  onDeleteAllPostsClick,
}: {
  group: GroupedReport;
  allReports: EnrichedReport[];
  posts: EnrichedPost[];
  onDismissClick?: () => void;
  onRemoveClick?: () => void;
  onWarnClick?: () => void;
  onMuteClick?: (hours: 24 | 168) => void;
  onBanClick?: () => void;
  onDeleteAccountClick?: () => void;
  onDeleteAllPostsClick?: () => void;
}) {
  const { targetType, targetPost, targetUser, reports, reporterCount, hasOpen } = group;
  const history = targetUser ? moderationHistoryForUser({ user: targetUser, reports: allReports, posts }) : undefined;

  return (
    <div className="rounded-lg border border-border p-3">
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-start gap-2.5">
          <Avatar className="size-8 shrink-0">
            <AvatarFallback className="text-xs">{targetUser ? initials(userDisplayName(targetUser)) : "?"}</AvatarFallback>
          </Avatar>
          <div>
            <p className="text-sm">
              <Badge variant="outline" className="text-[11px]">{targetType === "post" ? "Post" : "Account"}</Badge>{" "}
              <span className="font-medium text-foreground">Reported by {reporterCount} user{reporterCount === 1 ? "" : "s"}</span>
            </p>
            {targetUser && (
              <p className="text-xs text-muted-foreground">
                {targetType === "post" ? "by " : ""}
                <Link href={`/users/${targetUser.id}`} className="font-medium text-foreground hover:underline">
                  {userDisplayName(targetUser)}
                </Link>
              </p>
            )}
          </div>
        </div>
        <ReportStatusBadge status={hasOpen ? "open" : reports[0].status} />
      </div>

      {targetType === "post" && targetPost && (
        <div className="mt-2 rounded-md bg-muted p-2 text-sm text-muted-foreground">{targetPost.content}</div>
      )}

      {history && (
        <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 rounded-md border border-border bg-secondary/40 p-2 text-xs text-muted-foreground">
          <span>Joined <span className="font-medium text-foreground">{formatDate(history.joinedAt)}</span></span>
          <span>Warnings <span className="font-medium text-foreground">{history.warnings}</span></span>
          <span>Posts removed <span className="font-medium text-foreground">{history.postsRemoved}</span></span>
          <span>Previous suspensions <span className="font-medium text-foreground">{history.previousSuspensions}</span></span>
          {history.currentlySuspended && <span className="font-medium text-destructive">Currently suspended</span>}
        </div>
      )}

      <div className="mt-2 space-y-2">
        {reports.map((r) => (
          <div key={r.id} className="rounded-md border border-border/70 p-2">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <p className="text-xs">
                <Link href={`/users/${r.reporter_id}`} className="font-medium text-foreground hover:underline">
                  {userDisplayName(r.reporter)}
                </Link>{" "}
                <Badge variant="outline" className="text-[10px]">{titleCase(r.category)}</Badge>
              </p>
              <span className="text-xs text-muted-foreground">{formatDateTime(r.created_at)}</span>
            </div>
            <p className="mt-1 text-sm text-foreground">{r.reason}</p>
            {r.status !== "open" && r.resolution_note && (
              <p className="mt-1 text-xs text-muted-foreground">
                {titleCase(r.status)}: <span className="text-foreground">{r.resolution_note}</span>
              </p>
            )}
          </div>
        ))}
      </div>

      {hasOpen && (
        <div className="mt-3 flex flex-wrap items-center gap-2">
          <Button size="sm" variant="outline" onClick={onDismissClick}>
            Dismiss Report
          </Button>
          {onRemoveClick && (
            <Button size="sm" variant="outline" onClick={onRemoveClick}>
              Remove post
            </Button>
          )}
          {onWarnClick && (
            <Button size="sm" variant="outline" onClick={onWarnClick}>
              <Warning size={13} /> Warn user
            </Button>
          )}
          {onBanClick && (
            <Button size="sm" variant="destructive" onClick={onBanClick}>
              <Prohibit size={13} /> Ban permanently
            </Button>
          )}
          {(onMuteClick || onDeleteAccountClick || onDeleteAllPostsClick) && (
            <DropdownMenu>
              <DropdownMenuTrigger render={<Button size="sm" variant="outline" />}>
                More actions <CaretDown size={12} />
              </DropdownMenuTrigger>
              <DropdownMenuContent align="start">
                {onMuteClick && (
                  <DropdownMenuItem onClick={() => onMuteClick(24)}>
                    <SpeakerSimpleSlash size={14} /> Mute 24 hours
                  </DropdownMenuItem>
                )}
                {onMuteClick && (
                  <DropdownMenuItem onClick={() => onMuteClick(168)}>
                    <SpeakerSimpleSlash size={14} /> Mute 7 days
                  </DropdownMenuItem>
                )}
                {onDeleteAllPostsClick && (
                  <DropdownMenuItem variant="destructive" onClick={onDeleteAllPostsClick}>
                    <Trash size={14} /> Delete all posts
                  </DropdownMenuItem>
                )}
                {onDeleteAccountClick && (
                  <DropdownMenuItem variant="destructive" onClick={onDeleteAccountClick}>
                    <UserMinus size={14} /> Delete account
                  </DropdownMenuItem>
                )}
              </DropdownMenuContent>
            </DropdownMenu>
          )}
        </div>
      )}
    </div>
  );
}
