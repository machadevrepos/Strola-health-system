"use client";

import { ClockCounterClockwise } from "@phosphor-icons/react";
import { useAuditLog } from "@/lib/audit-log-store";
import { formatDateTime, initials } from "@/lib/format";

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
    <div>
      {entries.map((entry, i) => (
        <div key={entry.id} className="relative flex gap-3 pb-5 last:pb-0">
          {i < entries.length - 1 && <span className="absolute top-8 bottom-0 left-[15px] w-px bg-border" aria-hidden />}
          <div className="z-10 flex size-8 shrink-0 items-center justify-center rounded-full bg-secondary text-[11px] font-semibold text-foreground">
            {initials(entry.actor)}
          </div>
          <div className="min-w-0 flex-1 pt-0.5">
            <p className="text-sm font-semibold text-foreground">{entry.actor}</p>
            <p className="text-sm text-foreground">{entry.action}</p>
            {entry.target && <p className="mt-0.5 text-xs text-muted-foreground">{entry.target}</p>}
          </div>
          <span className="shrink-0 pt-0.5 text-xs text-muted-foreground">{formatDateTime(entry.timestamp)}</span>
        </div>
      ))}
    </div>
  );
}
