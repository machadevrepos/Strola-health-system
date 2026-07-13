"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { SettingsView } from "@/components/settings/settings-view";
import { fetchAllDevices, fetchAppSettings, fetchBetaOverrides, fetchFeatureFlags, fetchUsers } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

async function loadSettings() {
  const [devices, flags, users, appSettings, betaOverrides] = await Promise.all([
    fetchAllDevices(),
    fetchFeatureFlags(),
    fetchUsers(),
    fetchAppSettings(),
    fetchBetaOverrides(),
  ]);
  return { devices, flags, users, appSettings, betaOverrides };
}

export default function SettingsPage() {
  const { data, loading, error, reload } = useApiData(loadSettings);

  return (
    <div>
      <PageHeader title="Settings" description="Hardware fleet, feature gating, and a record of every admin action this session." />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <SettingsView {...data} />}
    </div>
  );
}
