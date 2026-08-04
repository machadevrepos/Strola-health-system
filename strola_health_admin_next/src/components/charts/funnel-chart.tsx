"use client";

import { Bar, BarChart, CartesianGrid, Cell, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { ChartTooltip } from "@/components/charts/chart-tooltip";
import { ChartEmptyState } from "@/components/shell/page-states";
import { formatNumber } from "@/lib/format";

const COLORS = ["var(--color-primary)", "var(--color-primary)", "var(--color-success)"];

export function FunnelChart({ data }: { data: { stage: string; count: number }[] }) {
  if (data.every((d) => d.count === 0)) {
    return <ChartEmptyState height={180} message="No users in the funnel yet." />;
  }

  return (
    <div className="space-y-3">
      <ResponsiveContainer width="100%" height={180}>
        <BarChart data={data} layout="vertical" margin={{ top: 0, right: 24, left: 0, bottom: 0 }}>
          <CartesianGrid horizontal={false} stroke="var(--color-border)" strokeDasharray="3 3" />
          <XAxis type="number" hide />
          <YAxis
            type="category"
            dataKey="stage"
            tickLine={false}
            axisLine={false}
            width={140}
            tick={{ fontSize: 12, fill: "var(--color-foreground)" }}
          />
          <Tooltip content={<ChartTooltip formatter={(v) => formatNumber(v ?? 0)} />} cursor={{ fill: "var(--color-muted)" }} />
          <Bar dataKey="count" radius={[0, 6, 6, 0]} barSize={28}>
            {data.map((_, i) => (
              <Cell key={i} fill={COLORS[i % COLORS.length]} fillOpacity={i === 0 ? 1 : 0.55 + i * 0.2} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
      <div className="flex justify-between px-1 text-xs text-muted-foreground">
        {data.slice(1).map((d, i) => {
          const prev = data[i].count;
          const rate = prev > 0 ? Math.round((d.count / prev) * 100) : 0;
          return (
            <span key={d.stage}>
              {data[i].stage} {"→"} {d.stage}:{" "}
              <span className="font-mono font-medium text-foreground">{rate}%</span>
            </span>
          );
        })}
      </div>
    </div>
  );
}
