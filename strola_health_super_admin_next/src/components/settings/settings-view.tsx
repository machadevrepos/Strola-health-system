"use client";

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { FeatureFlagsPanel } from "@/components/settings/feature-flags-panel";
import { ActivityLogPanel } from "@/components/settings/activity-log-panel";
import type { FeatureFlag } from "@/lib/types";

export function SettingsView({ flags }: { flags: FeatureFlag[] }) {
  return (
    <Tabs defaultValue="flags">
      <TabsList>
        <TabsTrigger value="flags">Feature flags</TabsTrigger>
        <TabsTrigger value="log">Activity log</TabsTrigger>
      </TabsList>
      <TabsContent value="flags" className="mt-4">
        <FeatureFlagsPanel flags={flags} />
      </TabsContent>
      <TabsContent value="log" className="mt-4">
        <ActivityLogPanel />
      </TabsContent>
    </Tabs>
  );
}
