"use client";

import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { ChartTooltip } from "@/components/charts/chart-tooltip";
import { ChartEmptyState } from "@/components/shell/page-states";

const CHART_HEIGHT = 220;

export function DauTrendChart({
  data,
  seriesName = "Active users",
}: {
  data: { date: string; count: number }[];
  seriesName?: string;
}) {
  const hasData = data.some((d) => d.count > 0);
  if (!hasData) {
    return <ChartEmptyState height={CHART_HEIGHT} message="No activity recorded yet — this fills in once real users start opening the app." />;
  }

  const formatted = data.map((d) => ({
    ...d,
    label: new Date(d.date).toLocaleDateString("en-GB", { day: "numeric", month: "short" }),
  }));

  return (
    <ResponsiveContainer width="100%" height={CHART_HEIGHT}>
      <AreaChart data={formatted} margin={{ top: 8, right: 8, left: -16, bottom: 0 }}>
        <defs>
          <linearGradient id="dauFill" x1="0" y1="0" x2="0" y2="1">
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
          interval={Math.ceil(formatted.length / 8)}
        />
        <YAxis
          tickLine={false}
          axisLine={false}
          width={32}
          tick={{ fontSize: 11, fill: "var(--color-muted-foreground)" }}
        />
        <Tooltip content={<ChartTooltip />} cursor={{ stroke: "var(--color-border)" }} />
        <Area
          type="monotone"
          dataKey="count"
          name={seriesName}
          stroke="var(--color-primary)"
          strokeWidth={2}
          fill="url(#dauFill)"
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
