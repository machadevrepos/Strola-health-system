import { Badge } from "@/components/ui/badge";
import { ROLE_LABEL } from "@/lib/format";
import type { Role, UserProfile } from "@/lib/types";

// Every chip in the app uses the same light/tinted treatment: a soft
// percentage-opacity fill of the semantic color with the color itself (or a
// darker "strong" variant for amber, which is too light to read as text on
// its own tint) as the text. No solid/saturated chip fills — that reads as
// heavy on a dense admin screen full of them.

export function RoleBadge({ role }: { role: Role }) {
  if (role === "super_admin") return <Badge className="bg-primary/12 text-primary">{ROLE_LABEL[role]}</Badge>;
  if (role === "admin") return <Badge className="bg-secondary text-foreground">{ROLE_LABEL[role]}</Badge>;
  return <Badge variant="outline">{ROLE_LABEL[role]}</Badge>;
}

export function SubscriptionBadge({ subscription }: { subscription: UserProfile["subscription"] }) {
  // Tier badges deliberately use a different color axis than account-status
  // badges (success green / destructive red): Premium is a commercial tier,
  // not a health signal, so it carries the brand color instead of reusing
  // "green = good" — keeps it visually distinct from an adjacent Active pill.
  const { tier, status } = subscription;
  if (tier === "premium" && status === "active") {
    return <Badge className="bg-primary/12 text-primary">Premium</Badge>;
  }
  if (status === "trialing") {
    return <Badge className="bg-brand-accent/20 text-brand-accent-strong">Trial</Badge>;
  }
  if (status === "cancelled") {
    return <Badge variant="outline">Cancelling</Badge>;
  }
  return <Badge variant="secondary">Free</Badge>;
}

export function AccountStatusBadge({ user }: { user: UserProfile }) {
  if (user.deleted) return <Badge variant="outline">Deleted</Badge>;
  if (user.banned) return <Badge className="bg-destructive/12 text-destructive">Banned</Badge>;
  return <Badge className="bg-success/15 text-success">Active</Badge>;
}

export function ReportStatusBadge({ status }: { status: "open" | "resolved" | "dismissed" }) {
  if (status === "open") return <Badge className="bg-destructive/12 text-destructive">Open</Badge>;
  if (status === "resolved") return <Badge className="bg-success/15 text-success">Resolved</Badge>;
  return <Badge variant="secondary">Dismissed</Badge>;
}

export function ChallengeStatusBadge({ status }: { status: "upcoming" | "active" | "ended" }) {
  if (status === "active") return <Badge className="bg-success/15 text-success">Active</Badge>;
  if (status === "upcoming") return <Badge className="bg-brand-accent/20 text-brand-accent-strong">Upcoming</Badge>;
  return <Badge variant="secondary">Ended</Badge>;
}
