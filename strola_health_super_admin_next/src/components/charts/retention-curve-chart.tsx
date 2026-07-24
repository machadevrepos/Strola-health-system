"use client";

import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { ChartTooltip } from "@/components/charts/chart-tooltip";
import type { RetentionPoint } from "@/lib/data/queries";

export function RetentionCurveChart({ points }: { points: RetentionPoint[] }) {
  const formatted = points.map((p) => ({
    ...p,
    label: `Day ${p.offsetDays}`,
    // Distinguish "0% retained" from "no eligible cohort yet" — the latter
    // renders as a gap rather than a misleading flat zero.
    value: p.eligible > 0 ? p.pct : null,
  }));

  return (
    <div className="space-y-2">
      <ResponsiveContainer width="100%" height={220}>
        <AreaChart data={formatted} margin={{ top: 8, right: 8, left: -16, bottom: 0 }}>
          <defs>
            <linearGradient id="retentionFill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="var(--color-primary)" stopOpacity={0.22} />
              <stop offset="100%" stopColor="var(--color-primary)" stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid vertical={false} stroke="var(--color-border)" strokeDasharray="3 3" />
          <XAxis
            dataKey="label"
            tickLine={false}
            axisLine={false}
            tick={{ fontSize: 11, fill: "var(--color-muted-foreground)" }}
          />
          <YAxis
            tickLine={false}
            axisLine={false}
            width={36}
            domain={[0, 100]}
            tickFormatter={(v) => `${v}%`}
            tick={{ fontSize: 11, fill: "var(--color-muted-foreground)" }}
          />
          <Tooltip content={<ChartTooltip formatter={(v) => `${v ?? 0}%`} />} cursor={{ stroke: "var(--color-border)" }} />
          <Area
            type="monotone"
            dataKey="value"
            name="Retained"
            stroke="var(--color-primary)"
            strokeWidth={2}
            fill="url(#retentionFill)"
            connectNulls
          />
        </AreaChart>
      </ResponsiveContainer>
      <p className="text-xs text-muted-foreground">
        % who reopened the app that many days after signing up. Offsets with too small a signup cohort in the
        30-day window are left blank rather than shown as an unreliable percentage.
      </p>
    </div>
  );
}
