"use client";

import * as React from "react";
import { onIdTokenChanged, signOut as firebaseSignOut, type User } from "firebase/auth";
import { getFirebaseAuth } from "@/lib/firebase-client";
import type { Role } from "@/lib/types";

interface AuthState {
  user: User | null;
  role: Role | null;
  loading: boolean;
  signOut: () => Promise<void>;
}

const AuthContext = React.createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = React.useState<User | null>(null);
  const [role, setRole] = React.useState<Role | null>(null);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
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
    await firebaseSignOut(getFirebaseAuth());
  }, []);

  return <AuthContext.Provider value={{ user, role, loading, signOut }}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = React.useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
