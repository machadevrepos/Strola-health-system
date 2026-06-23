"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { CircleNotch, ShieldWarning } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/lib/auth-context";
import type { Role } from "@/lib/types";

export function RequireRole({ allow, children }: { allow: Role[]; children: React.ReactNode }) {
  const { user, role, loading, signOut } = useAuth();
  const router = useRouter();

  React.useEffect(() => {
    if (!loading && !user) router.replace("/login");
  }, [loading, user, router]);

  if (loading || !user) {
    return (
      <div className="flex h-dvh items-center justify-center bg-background">
        <CircleNotch size={24} className="animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (role && !allow.includes(role)) {
    return (
      <div className="flex h-dvh flex-col items-center justify-center gap-3 bg-background px-4 text-center">
        <ShieldWarning size={28} className="text-destructive" />
        <p className="text-sm font-medium text-foreground">Your account doesn&apos;t have access to this console.</p>
        <Button variant="outline" size="sm" onClick={() => signOut().then(() => router.replace("/login"))}>
          Sign out
        </Button>
      </div>
    );
  }

  return <>{children}</>;
}
