"use client";

import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";
import { ChartTooltip } from "@/components/charts/chart-tooltip";
import { formatNumber } from "@/lib/format";

const COLORS: Record<string, string> = {
  Premium: "var(--color-primary)",
  Trial: "var(--color-brand-accent)",
  Free: "var(--color-border)",
};

export function SubscriptionDonut({ data }: { data: { tier: string; count: number }[] }) {
  const total = data.reduce((sum, d) => sum + d.count, 0);

  return (
    <div className="flex items-center gap-6">
      <ResponsiveContainer width={140} height={140}>
        <PieChart>
          <Pie data={data} dataKey="count" nameKey="tier" innerRadius={42} outerRadius={64} paddingAngle={2} stroke="none">
            {data.map((d) => (
              <Cell key={d.tier} fill={COLORS[d.tier] ?? "var(--color-muted)"} />
            ))}
          </Pie>
          <Tooltip content={<ChartTooltip formatter={(v) => formatNumber(v ?? 0)} />} />
        </PieChart>
      </ResponsiveContainer>
      <div className="space-y-2">
        {data.map((d) => (
          <div key={d.tier} className="flex items-center gap-2 text-sm">
            <span className="size-2.5 rounded-full" style={{ background: COLORS[d.tier] ?? "var(--color-muted)" }} />
            <span className="text-muted-foreground">{d.tier}</span>
            <span className="font-mono font-medium text-foreground">{d.count}</span>
            <span className="text-xs text-muted-foreground">
              ({total > 0 ? Math.round((d.count / total) * 100) : 0}%)
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
