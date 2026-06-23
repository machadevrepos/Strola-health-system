"use client";

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { DevicesPanel } from "@/components/settings/devices-panel";
import { FeatureFlagsPanel } from "@/components/settings/feature-flags-panel";
import { ActivityLogPanel } from "@/components/settings/activity-log-panel";
import type { Device, FeatureFlag, UserProfile } from "@/lib/types";

export function SettingsView({
  devices,
  flags,
  users,
}: {
  devices: Device[];
  flags: FeatureFlag[];
  users: UserProfile[];
}) {
  return (
    <Tabs defaultValue="devices">
      <TabsList>
        <TabsTrigger value="devices">Device fleet</TabsTrigger>
        <TabsTrigger value="flags">Feature flags</TabsTrigger>
        <TabsTrigger value="log">Activity log</TabsTrigger>
      </TabsList>
      <TabsContent value="devices" className="mt-4">
        <DevicesPanel devices={devices} users={users} />
      </TabsContent>
      <TabsContent value="flags" className="mt-4">
        <FeatureFlagsPanel flags={flags} />
      </TabsContent>
      <TabsContent value="log" className="mt-4">
        <ActivityLogPanel />
      </TabsContent>
    </Tabs>
  );
}
