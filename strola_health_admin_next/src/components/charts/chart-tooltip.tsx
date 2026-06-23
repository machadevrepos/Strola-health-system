interface ChartTooltipPayloadEntry {
  name?: string;
  value?: number | string;
  color?: string;
}

interface ChartTooltipProps {
  active?: boolean;
  payload?: ChartTooltipPayloadEntry[];
  label?: string | number;
  formatter?: (value: number | undefined) => string;
}

export function ChartTooltip({ active, payload, label, formatter }: ChartTooltipProps) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-lg border border-border bg-popover px-3 py-2 text-xs shadow-[0_4px_16px_oklch(0.20_0.012_220_/_0.10)]">
      {label !== undefined && <p className="mb-1 font-medium text-foreground">{label}</p>}
      {payload.map((entry, i) => (
        <div key={i} className="flex items-center gap-1.5 text-muted-foreground">
          <span className="size-2 rounded-full" style={{ background: entry.color }} />
          <span>{entry.name}:</span>
          <span className="font-mono font-medium text-foreground">
            {formatter && typeof entry.value === "number" ? formatter(entry.value) : entry.value}
          </span>
        </div>
      ))}
    </div>
  );
}
