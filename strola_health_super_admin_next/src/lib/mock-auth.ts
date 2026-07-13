"use client";

// Stand-in for Firebase Auth when IS_MOCK_MODE is on — no backend, no
// Firebase project needed. "Signs in" by matching the typed email against
// the mock user list (any password works), persists the choice in
// localStorage so a refresh doesn't log the demo out, and exposes the same
// shape `auth-context.tsx` already reads off a real Firebase `User`.

import { mockUsers } from "@/lib/data/mock-store";
import type { Role } from "@/lib/types";

const STORAGE_KEY = "strolla-mock-session";

export interface MockUser {
  uid: string;
  email: string | null;
  displayName: string | null;
}

export interface MockSession {
  user: MockUser;
  role: Role;
}

// The role a blank/unrecognized email falls back to — set per app via
// NEXT_PUBLIC_MOCK_DEFAULT_ROLE (admin-next ships "admin", super-admin-next
// ships "super_admin").
const DEFAULT_ROLE = (process.env.NEXT_PUBLIC_MOCK_DEFAULT_ROLE as Role | undefined) ?? "admin";

export function mockSignIn(email: string): MockSession {
  const match = mockUsers.find((u) => u.email?.toLowerCase() === email.trim().toLowerCase());
  const session: MockSession = match
    ? { user: { uid: match.id, email: match.email, displayName: match.name }, role: match.role }
    : { user: { uid: "usr_demo", email: email.trim() || "demo@strollahealth.com", displayName: "Demo Staff" }, role: DEFAULT_ROLE };
  if (typeof window !== "undefined") {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(session));
  }
  return session;
}

export function mockSignOut(): void {
  if (typeof window !== "undefined") {
    window.localStorage.removeItem(STORAGE_KEY);
  }
}

export function readMockSession(): MockSession | null {
  if (typeof window === "undefined") return null;
  const raw = window.localStorage.getItem(STORAGE_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as MockSession;
  } catch {
    return null;
  }
}
