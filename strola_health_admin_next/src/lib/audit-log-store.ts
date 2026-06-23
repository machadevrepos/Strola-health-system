"use client";

import { create } from "zustand";

// Session-only audit trail of admin actions. This is the one piece of state
// that genuinely needs to be shared across unrelated component trees (a ban
// on the Users page and a hide on the Moderation page both need to land in
// the same log) — everything else in this dummy-data phase stays local
// per-page state. Swap for a real `GET/POST /admin/audit-log` once the
// backend is wired up; the call sites (`logAction(...)`) don't change.

export interface AuditLogEntry {
  id: string;
  actor: string;
  action: string;
  target: string;
  timestamp: string;
}

// Stand-in for the signed-in staff member until real Firebase Auth is wired
// up — matches the same placeholder used in the sidebar.
const CURRENT_OPERATOR = "Maya Whitfield";

interface AuditLogState {
  entries: AuditLogEntry[];
  log: (action: string, target: string) => void;
}

export const useAuditLog = create<AuditLogState>((set) => ({
  entries: [],
  log: (action, target) =>
    set((state) => ({
      entries: [
        {
          id: `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
          actor: CURRENT_OPERATOR,
          action,
          target,
          timestamp: new Date().toISOString(),
        },
        ...state.entries,
      ].slice(0, 200),
    })),
}));

export function logAction(action: string, target: string) {
  useAuditLog.getState().log(action, target);
}
