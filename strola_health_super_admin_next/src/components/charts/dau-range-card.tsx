"use client";

import { useMemo, useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { DauTrendChart } from "@/components/charts/dau-trend-chart";
import { dailyActiveUsers, dailyActiveUsersInRange } from "@/lib/data/queries";
import type { AnalyticsEvent } from "@/lib/types";

type RangeOption = "30" | "90" | "365" | "custom";

const RANGE_LABEL: Record<RangeOption, string> = {
  "30": "30 days",
  "90": "90 days",
  "365": "365 days",
  custom: "Custom",
};

function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

export function DauRangeCard({ events }: { events: AnalyticsEvent[] }) {
  const [range, setRange] = useState<RangeOption>("30");

  // Anchored to the latest event actually in the data, not Date.now() — same
  // frozen-mock-timeline reasoning as the query helpers this reads from.
  const latestEventDate = useMemo(() => {
    const latest = events.reduce((max, e) => Math.max(max, +new Date(e.created_at)), 0);
    return latest > 0 ? new Date(latest) : new Date();
  }, [events]);

  const [customStart, setCustomStart] = useState(() => isoDate(new Date(latestEventDate.getTime() - 29 * 86_400_000)));
  const [customEnd, setCustomEnd] = useState(() => isoDate(latestEventDate));

  const data = useMemo(() => {
    if (range === "custom") return dailyActiveUsersInRange(events, customStart, customEnd);
    return dailyActiveUsers(events, Number(range));
  }, [events, range, customStart, customEnd]);

  return (
    <Card className="border-border shadow-none lg:col-span-2">
      <CardHeader>
        <CardTitle>Daily active users</CardTitle>
        <CardDescription>
          {range === "custom" ? `${customStart} to ${customEnd}, from app_opened events.` : `Last ${RANGE_LABEL[range]}, from app_opened events.`}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="flex flex-wrap items-center gap-3">
          <Tabs value={range} onValueChange={(v) => setRange(v as RangeOption)}>
            <TabsList>
              {(Object.keys(RANGE_LABEL) as RangeOption[]).map((option) => (
                <TabsTrigger key={option} value={option}>
                  {RANGE_LABEL[option]}
                </TabsTrigger>
              ))}
            </TabsList>
          </Tabs>
          {range === "custom" && (
            <div className="flex items-center gap-2">
              <Input
                type="date"
                value={customStart}
                max={customEnd}
                onChange={(e) => setCustomStart(e.target.value)}
                className="w-auto"
              />
              <span className="text-xs text-muted-foreground">to</span>
              <Input
                type="date"
                value={customEnd}
                min={customStart}
                max={isoDate(latestEventDate)}
                onChange={(e) => setCustomEnd(e.target.value)}
                className="w-auto"
              />
            </div>
          )}
        </div>
        <DauTrendChart data={data} />
      </CardContent>
    </Card>
  );
}
