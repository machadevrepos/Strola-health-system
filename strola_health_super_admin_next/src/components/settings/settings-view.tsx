"use client";

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { FeatureFlagsPanel } from "@/components/settings/feature-flags-panel";
import { ActivityLogPanel } from "@/components/settings/activity-log-panel";
import { AppSettingsPanel } from "@/components/settings/app-settings-panel";
import { BetaTestingPanel } from "@/components/settings/beta-testing-panel";
import type { AppSettings, BetaOverride, FeatureFlag, UserProfile } from "@/lib/types";

export function SettingsView({
  flags,
  users,
  appSettings,
  betaOverrides,
}: {
  flags: FeatureFlag[];
  users: UserProfile[];
  appSettings: AppSettings;
  betaOverrides: BetaOverride[];
}) {
  return (
    <Tabs defaultValue="flags">
      <TabsList>
        <TabsTrigger value="flags">Feature flags</TabsTrigger>
        <TabsTrigger value="beta">Beta testing</TabsTrigger>
        <TabsTrigger value="app">App settings</TabsTrigger>
        <TabsTrigger value="log">Activity log</TabsTrigger>
      </TabsList>
      <TabsContent value="flags" className="mt-4">
        <FeatureFlagsPanel flags={flags} />
      </TabsContent>
      <TabsContent value="beta" className="mt-4">
        <BetaTestingPanel overrides={betaOverrides} flags={flags} users={users} />
      </TabsContent>
      <TabsContent value="app" className="mt-4">
        <AppSettingsPanel settings={appSettings} users={users} />
      </TabsContent>
      <TabsContent value="log" className="mt-4">
        <ActivityLogPanel />
      </TabsContent>
    </Tabs>
  );
}
