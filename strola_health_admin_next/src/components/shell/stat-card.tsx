import type { ReactNode } from "react";
import { Card } from "@/components/ui/card";
import { cn } from "@/lib/utils";

export function StatCard({
  label,
  value,
  hint,
  icon,
  tone = "default",
  trendLabel,
}: {
  label: string;
  value: ReactNode;
  hint?: string;
  icon?: ReactNode;
  tone?: "default" | "danger" | "success";
  // Signed growth string (e.g. "+12.4%") rendered under the value in
  // green/red — distinct from `hint`, which is neutral-colored context text.
  // Both can be shown at once.
  trendLabel?: string;
}) {
  const trendIsNegative = trendLabel?.trimStart().startsWith("-");
  const trendIsPositive = trendLabel && !trendIsNegative && trendLabel.trim() !== "—";

  return (
    <Card className="gap-1 border-border p-4 shadow-none">
      <div className="flex items-center justify-between">
        <p className="text-xs font-medium text-muted-foreground">{label}</p>
        {icon && <span className="text-muted-foreground">{icon}</span>}
      </div>
      <p
        className={cn(
          "font-mono text-2xl font-semibold tracking-tight",
          tone === "danger" && "text-destructive",
          tone === "success" && "text-success",
          tone === "default" && "text-foreground"
        )}
      >
        {value}
      </p>
      {trendLabel && (
        <p
          className={cn(
            "font-mono text-xs font-medium",
            trendIsPositive && "text-success",
            trendIsNegative && "text-destructive",
            !trendIsPositive && !trendIsNegative && "text-muted-foreground"
          )}
        >
          {trendLabel}
        </p>
      )}
      {hint && <p className="text-xs text-muted-foreground">{hint}</p>}
    </Card>
  );
}
