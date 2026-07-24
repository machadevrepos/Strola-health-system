import type { ReactNode } from "react";
import type { BadgeRequirementMetric } from "@/lib/types";
import { formatCompact } from "@/lib/format";

// Mirrors the app's own HexBadge (lib/presentation/widgets/hex_badge.dart)
// so the catalog here looks like what members actually see on the
// Achievements screen — a gradient hexagon, not a raw emoji.
const GRADIENT: Record<"steps" | "streaks" | "challenges" | "muted", string> = {
  steps: "linear-gradient(135deg, var(--color-success), color-mix(in oklch, var(--color-success) 65%, black))",
  streaks: "linear-gradient(135deg, var(--color-primary), var(--color-destructive))",
  challenges: "linear-gradient(135deg, var(--color-brand-accent), var(--color-primary))",
  muted: "var(--color-muted-foreground)",
};

const HEX_CLIP = "polygon(50% 0%, 100% 26%, 100% 74%, 50% 100%, 0% 74%, 0% 26%)";

export type HexBadgeCategory = "steps" | "streaks" | "challenges" | "muted";

export function HexBadge({
  category,
  big,
  icon,
  small,
  size = 56,
}: {
  category: HexBadgeCategory;
  big?: string;
  icon?: ReactNode;
  small: string;
  size?: number;
}) {
  return (
    <div
      className="flex shrink-0 flex-col items-center justify-center gap-0.5 text-white"
      style={{ width: size, height: size * 1.05, clipPath: HEX_CLIP, background: GRADIENT[category] }}
    >
      {icon ? (
        icon
      ) : (
        <span className="text-sm leading-none font-extrabold tracking-tight">{big}</span>
      )}
      <span className="px-1 text-center text-[6.5px] leading-none font-bold tracking-wide uppercase">{small}</span>
    </div>
  );
}

const CATEGORY_BY_METRIC: Record<BadgeRequirementMetric, HexBadgeCategory> = {
  total_steps: "steps",
  session_steps: "steps",
  streak_days: "streaks",
  challenges_completed: "challenges",
  early_morning_sessions: "muted",
  community_posts: "muted",
};

const SMALL_LABEL: Record<HexBadgeCategory, string> = {
  steps: "steps",
  streaks: "day streak",
  challenges: "challenges",
  muted: "retired",
};

/** Derives the hexagon's category/big-number/small-label from a badge's
 * requirement fields — the same "50K STEPS" / "30 DAY STREAK" shorthand the
 * app's own hardcoded badge lists use. */
export function hexBadgePropsForBadge(badge: { requirement_metric: BadgeRequirementMetric; requirement_value: number; enabled: boolean }) {
  const category = badge.enabled ? CATEGORY_BY_METRIC[badge.requirement_metric] : "muted";
  return {
    category,
    big: category === "muted" ? undefined : formatCompact(badge.requirement_value),
    small: SMALL_LABEL[category],
  };
}
