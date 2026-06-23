"use client";

import { ClockCounterClockwise } from "@phosphor-icons/react";
import { useAuditLog } from "@/lib/audit-log-store";
import { formatDateTime } from "@/lib/format";

export function ActivityLogPanel() {
  const entries = useAuditLog((s) => s.entries);

  if (entries.length === 0) {
    return (
      <div className="flex flex-col items-center gap-2 py-16 text-center text-muted-foreground">
        <ClockCounterClockwise size={24} />
        <p className="text-sm">No actions taken yet this session.</p>
        <p className="max-w-sm text-xs">
          Every ban, edit, hide, grant, and delete you make across the admin panel shows up here in real time.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-1">
      {entries.map((entry) => (
        <div key={entry.id} className="flex items-start gap-3 rounded-md px-2 py-2 text-sm hover:bg-muted">
          <span className="mt-1.5 size-1.5 shrink-0 rounded-full bg-primary" />
          <div className="min-w-0 flex-1">
            <p className="text-foreground">
              <span className="font-medium">{entry.actor}</span> {entry.action.toLowerCase()}
              {entry.target && <span className="text-muted-foreground"> — {entry.target}</span>}
            </p>
          </div>
          <span className="shrink-0 text-xs text-muted-foreground">{formatDateTime(entry.timestamp)}</span>
        </div>
      ))}
    </div>
  );
}
