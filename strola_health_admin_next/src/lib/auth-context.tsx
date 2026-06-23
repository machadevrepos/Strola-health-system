"use client";

import * as React from "react";
import { onIdTokenChanged, signOut as firebaseSignOut, type User } from "firebase/auth";
import { getFirebaseAuth } from "@/lib/firebase-client";
import { IS_MOCK_MODE } from "@/lib/mock-mode";
import { mockSignIn as performMockSignIn, mockSignOut, readMockSession, type MockUser } from "@/lib/mock-auth";
import type { Role } from "@/lib/types";

interface AuthState {
  user: User | MockUser | null;
  role: Role | null;
  loading: boolean;
  signOut: () => Promise<void>;
  // Only meaningful (and only ever called) in mock mode — the login page
  // routes through this instead of writing to mock-auth.ts directly, since
  // that's the only way the rest of the already-mounted app finds out a
  // mock "sign-in" happened. Real mode picks the change up via Firebase's
  // own onIdTokenChanged listener instead.
  mockSignIn: (email: string) => void;
}

const AuthContext = React.createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = React.useState<User | MockUser | null>(null);
  const [role, setRole] = React.useState<Role | null>(null);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    if (IS_MOCK_MODE) {
      // No Firebase at all in mock mode — the "session" is just whatever
      // mock-auth.ts wrote to localStorage on a previous visit (refresh
      // case); a fresh sign-in updates state directly via mockSignIn below.
      const session = readMockSession();
      setUser(session?.user ?? null);
      setRole(session?.role ?? null);
      setLoading(false);
      return;
    }

    const auth = getFirebaseAuth();
    // onIdTokenChanged (not onAuthStateChanged) so a role change picked up on
    // the next token refresh updates this without requiring a re-login.
    const unsubscribe = onIdTokenChanged(auth, async (nextUser) => {
      setUser(nextUser);
      if (nextUser) {
        const result = await nextUser.getIdTokenResult();
        setRole((result.claims.role as Role | undefined) ?? "user");
      } else {
        setRole(null);
      }
      setLoading(false);
    });
    return unsubscribe;
  }, []);

  const signOut = React.useCallback(async () => {
    if (IS_MOCK_MODE) {
      mockSignOut();
      setUser(null);
      setRole(null);
      return;
    }
    await firebaseSignOut(getFirebaseAuth());
  }, []);

  const mockSignIn = React.useCallback((email: string) => {
    const session = performMockSignIn(email);
    setUser(session.user);
    setRole(session.role);
  }, []);

  return <AuthContext.Provider value={{ user, role, loading, signOut, mockSignIn }}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = React.useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
