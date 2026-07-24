// A ranked horizontal-bar breakdown for independent (non-sequential)
// values — feature adoption %, screen-view counts, firmware version
// spread, step-goal distribution. Distinct from FunnelChart, which is
// specifically for a sequential funnel (its stage-to-stage conversion
// captions wouldn't mean anything here).
export function BarList({
  items,
  valueLabel,
}: {
  items: { label: string; value: number; displayValue?: string }[];
  // How to render each row's value when `displayValue` isn't given, e.g. (v) => `${v}%`.
  valueLabel?: (value: number) => string;
}) {
  const max = Math.max(1, ...items.map((i) => i.value));
  return (
    <div className="space-y-2.5">
      {items.map((item) => (
        <div key={item.label} className="flex items-center gap-3">
          <span className="w-32 shrink-0 truncate text-xs text-muted-foreground" title={item.label}>
            {item.label}
          </span>
          <div className="h-2 flex-1 overflow-hidden rounded-full bg-muted">
            <div className="h-full rounded-full bg-primary" style={{ width: `${(item.value / max) * 100}%` }} />
          </div>
          <span className="w-16 shrink-0 text-right font-mono text-xs font-medium text-foreground">
            {item.displayValue ?? valueLabel?.(item.value) ?? item.value}
          </span>
        </div>
      ))}
      {items.length === 0 && <p className="text-sm text-muted-foreground">No data yet.</p>}
    </div>
  );
}
