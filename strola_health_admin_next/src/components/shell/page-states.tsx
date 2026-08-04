import type { Icon } from "@phosphor-icons/react";
import { ChartBar, CircleNotch, WarningCircle } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";

export function PageLoading() {
  return (
    <div className="flex items-center justify-center py-24">
      <CircleNotch size={22} className="animate-spin text-muted-foreground" />
    </div>
  );
}

export function PageError({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-24 text-center">
      <WarningCircle size={24} className="text-destructive" />
      <p className="text-sm text-muted-foreground">{message}</p>
      <Button variant="outline" size="sm" onClick={onRetry}>
        Try again
      </Button>
    </div>
  );
}

/**
 * A chart/stat block with genuinely zero data (e.g. a fresh backend with no
 * real users yet) — distinct from PageError (nothing went wrong, there's
 * just nothing to show), and distinct from PageLoading (this is a settled
 * state, not "in flight"). Matches the chart's own height so it doesn't
 * cause the surrounding card grid to jump when data does arrive.
 */
export function ChartEmptyState({
  message = "No data yet.",
  height = 220,
  icon: IconComponent = ChartBar,
}: {
  message?: string;
  height?: number;
  icon?: Icon;
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 text-center" style={{ height }}>
      <IconComponent size={22} className="text-muted-foreground/40" />
      <p className="text-sm text-muted-foreground">{message}</p>
    </div>
  );
}
