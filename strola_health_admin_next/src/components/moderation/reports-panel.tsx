"use client";

import * as React from "react";
import Link from "next/link";
import { ReportStatusBadge } from "@/components/shell/status-badges";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ResolveReportDialog } from "@/components/moderation/resolve-report-dialog";
import { WarnUserDialog } from "@/components/moderation/warn-user-dialog";
import { BanUserDialog } from "@/components/users/ban-user-dialog";
import { findUserById, userDisplayName } from "@/lib/data/queries";
import { formatDateTime, initials } from "@/lib/format";
import type { EnrichedPost, EnrichedReport } from "@/lib/data/queries";
import type { ReportStatus, UserProfile } from "@/lib/types";

export function ReportsPanel({
  reports,
  posts,
  users,
  onResolve,
  onRemove,
  onWarnUser,
  onSuspendUser,
}: {
  reports: EnrichedReport[];
  posts: EnrichedPost[];
  users: UserProfile[];
  onResolve: (reportId: string, status: ReportStatus, note: string) => void | Promise<void>;
  onRemove: (reportId: string) => void | Promise<void>;
  onWarnUser: (reportId: string, userId: string, reason: string) => void | Promise<void>;
  onSuspendUser: (reportId: string, userId: string, reason: string) => void | Promise<void>;
}) {
  const [active, setActive] = React.useState<EnrichedReport | null>(null);
  const [warnTarget, setWarnTarget] = React.useState<{ report: EnrichedReport; user: UserProfile } | null>(null);
  const [suspendTarget, setSuspendTarget] = React.useState<{ report: EnrichedReport; user: UserProfile } | null>(null);

  const open = reports.filter((r) => r.status === "open");
  const resolved = reports.filter((r) => r.status !== "open");

  function findPost(id: string) {
    return posts.find((p) => p.id === id);
  }

  return (
    <div className="space-y-6">
      <section>
        <h3 className="mb-2 text-sm font-medium text-foreground">Open ({open.length})</h3>
        {open.length === 0 ? (
          <p className="py-6 text-sm text-muted-foreground">No open reports. Nice and quiet.</p>
        ) : (
          <div className="space-y-2">
            {open.map((r) => (
              <ReportRow
                key={r.id}
                report={r}
                post={r.target_type === "post" ? findPost(r.target_id) : undefined}
                resolvedByUser={undefined}
                onIgnoreClick={() => setActive(r)}
                onRemoveClick={r.target_type === "post" ? () => onRemove(r.id) : undefined}
                onWarnClick={(user) => setWarnTarget({ report: r, user })}
                onSuspendClick={(user) => setSuspendTarget({ report: r, user })}
              />
            ))}
          </div>
        )}
      </section>

      {resolved.length > 0 && (
        <section>
          <h3 className="mb-2 text-sm font-medium text-foreground">Resolved history ({resolved.length})</h3>
          <div className="space-y-2">
            {resolved.map((r) => (
              <ReportRow
                key={r.id}
                report={r}
                post={r.target_type === "post" ? findPost(r.target_id) : undefined}
                resolvedByUser={r.resolved_by ? findUserById(users, r.resolved_by) ?? r.resolvedByUser : undefined}
              />
            ))}
          </div>
        </section>
      )}

      <ResolveReportDialog
        report={active}
        onOpenChange={(open) => !open && setActive(null)}
        onResolve={async (status, note) => {
          if (active) await onResolve(active.id, status, note);
          setActive(null);
        }}
      />

      <WarnUserDialog
        target={warnTarget ? { userId: warnTarget.user.id, userName: userDisplayName(warnTarget.user) } : null}
        onOpenChange={(open) => !open && setWarnTarget(null)}
        onConfirm={async (reason) => {
          if (warnTarget) await onWarnUser(warnTarget.report.id, warnTarget.user.id, reason);
          setWarnTarget(null);
        }}
      />

      <BanUserDialog
        user={suspendTarget?.user ?? null}
        onOpenChange={(open) => !open && setSuspendTarget(null)}
        onConfirm={async (reason) => {
          if (suspendTarget) await onSuspendUser(suspendTarget.report.id, suspendTarget.user.id, reason);
          setSuspendTarget(null);
        }}
      />
    </div>
  );
}

function ReportRow({
  report,
  post,
  resolvedByUser,
  onIgnoreClick,
  onRemoveClick,
  onWarnClick,
  onSuspendClick,
}: {
  report: EnrichedReport;
  post?: EnrichedPost;
  resolvedByUser?: UserProfile;
  onIgnoreClick?: () => void;
  onRemoveClick?: () => void;
  onWarnClick?: (user: UserProfile) => void;
  onSuspendClick?: (user: UserProfile) => void;
}) {
  const target = report.target_type === "post" ? post?.author : report.targetUser;
  const isOpen = report.status === "open";

  return (
    <div className="rounded-lg border border-border p-3">
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-center gap-2">
          <Avatar className="size-7">
            <AvatarFallback className="text-xs">{initials(userDisplayName(report.reporter))}</AvatarFallback>
          </Avatar>
          <div>
            <p className="text-sm">
              <Link href={`/users/${report.reporter_id}`} className="font-medium text-foreground hover:underline">
                {userDisplayName(report.reporter)}
              </Link>{" "}
              <span className="text-muted-foreground">reported</span>{" "}
              <Badge variant="outline" className="text-[11px]">{report.target_type}</Badge>
            </p>
            <p className="text-xs text-muted-foreground">{formatDateTime(report.created_at)}</p>
          </div>
        </div>
        <ReportStatusBadge status={report.status} />
      </div>

      <p className="mt-2 text-sm text-foreground">{report.reason}</p>

      {report.target_type === "post" && post && (
        <div className="mt-2 rounded-md bg-muted p-2 text-sm text-muted-foreground">
          <span className="font-medium text-foreground">{userDisplayName(post.author)}: </span>
          {post.content}
        </div>
      )}
      {report.target_type === "user" && target && (
        <Link href={`/users/${target.id}`} className="mt-2 inline-block text-sm text-primary hover:underline">
          View {userDisplayName(target)}&apos;s profile {"→"}
        </Link>
      )}

      {report.status !== "open" && report.resolution_note && (
        <p className="mt-2 text-xs text-muted-foreground">
          Resolution: <span className="text-foreground">{report.resolution_note}</span>
        </p>
      )}
      {report.status !== "open" && report.resolved_at && (
        <p className="mt-1 text-xs text-muted-foreground">
          {report.status === "resolved" ? "Resolved" : "Dismissed"} by{" "}
          <span className="text-foreground">{resolvedByUser ? userDisplayName(resolvedByUser) : "a staff member"}</span>
          {" "}
          {formatDateTime(report.resolved_at)}
        </p>
      )}

      {isOpen && (
        <div className="mt-3 flex flex-wrap gap-2">
          <Button size="sm" variant="outline" onClick={onIgnoreClick}>
            Ignore
          </Button>
          {onRemoveClick && (
            <Button size="sm" variant="outline" onClick={onRemoveClick}>
              Remove
            </Button>
          )}
          {target && (
            <Button size="sm" variant="outline" onClick={() => onWarnClick?.(target)}>
              Warn user
            </Button>
          )}
          {target && (
            <Button size="sm" variant="destructive" onClick={() => onSuspendClick?.(target)}>
              Suspend account
            </Button>
          )}
        </div>
      )}
    </div>
  );
}
