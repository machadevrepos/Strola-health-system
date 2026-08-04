"use client";

import { Bar, BarChart, CartesianGrid, ReferenceLine, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { ChartTooltip } from "@/components/charts/chart-tooltip";
import { ChartEmptyState } from "@/components/shell/page-states";
import { formatNumber } from "@/lib/format";

export function StepsBarChart({
  data,
  goal,
}: {
  data: { date: string; steps: number }[];
  goal: number;
}) {
  if (data.every((d) => d.steps === 0)) {
    return <ChartEmptyState height={200} message="No steps recorded yet." />;
  }

  const formatted = data.map((d) => ({
    ...d,
    label: new Date(d.date).toLocaleDateString("en-GB", { day: "numeric", month: "short" }),
  }));

  return (
    <ResponsiveContainer width="100%" height={200}>
      <BarChart data={formatted} margin={{ top: 8, right: 8, left: -16, bottom: 0 }}>
        <CartesianGrid vertical={false} stroke="var(--color-border)" strokeDasharray="3 3" />
        <XAxis
          dataKey="label"
          tickLine={false}
          axisLine={false}
          tick={{ fontSize: 11, fill: "var(--color-muted-foreground)" }}
          interval={Math.ceil(formatted.length / 8)}
        />
        <YAxis tickLine={false} axisLine={false} width={36} tick={{ fontSize: 11, fill: "var(--color-muted-foreground)" }} />
        <Tooltip content={<ChartTooltip formatter={(v) => formatNumber(v ?? 0)} />} cursor={{ fill: "var(--color-muted)" }} />
        <ReferenceLine y={goal} stroke="var(--color-brand-accent)" strokeDasharray="4 4" strokeWidth={1.5} />
        <Bar dataKey="steps" name="Steps" radius={[4, 4, 0, 0]} fill="var(--color-primary)" />
      </BarChart>
    </ResponsiveContainer>
  );
}
