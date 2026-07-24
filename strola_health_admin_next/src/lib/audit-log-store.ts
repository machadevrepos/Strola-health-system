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

// Fallback only for the brief window before RequireRole's effect has synced
// the real signed-in user in (see `setAuditLogActor`) — should never be
// what actually shows up in a logged entry in practice.
const UNKNOWN_OPERATOR = "Unknown";

interface AuditLogState {
  actor: string;
  entries: AuditLogEntry[];
  setActor: (actor: string) => void;
  log: (action: string, target: string) => void;
}

export const useAuditLog = create<AuditLogState>((set, get) => ({
  actor: UNKNOWN_OPERATOR,
  entries: [],
  setActor: (actor) => set({ actor }),
  log: (action, target) =>
    set((state) => ({
      entries: [
        {
          id: `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
          actor: get().actor,
          action,
          target,
          timestamp: new Date().toISOString(),
        },
        ...state.entries,
      ].slice(0, 200),
    })),
}));

// Called once from RequireRole with the real signed-in user's name, so every
// entry `logAction` records after that reflects who's actually signed in —
// not a hardcoded placeholder.
export function setAuditLogActor(actor: string) {
  useAuditLog.getState().setActor(actor);
}

export function logAction(action: string, target: string) {
  useAuditLog.getState().log(action, target);
}
