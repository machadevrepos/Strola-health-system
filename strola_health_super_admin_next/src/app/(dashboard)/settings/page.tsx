"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { SettingsView } from "@/components/settings/settings-view";
import { fetchAppSettings, fetchBetaOverrides, fetchFeatureFlags, fetchUsers } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

async function loadSettings() {
  const [flags, users, appSettings, betaOverrides] = await Promise.all([
    fetchFeatureFlags(),
    fetchUsers(),
    fetchAppSettings(),
    fetchBetaOverrides(),
  ]);
  return { flags, users, appSettings, betaOverrides };
}

export default function SettingsPage() {
  const { data, loading, error, reload } = useApiData(loadSettings);

  return (
    <div>
      <PageHeader title="Settings" description="Feature gating, beta overrides, app defaults, and a record of every admin action this session." />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <SettingsView {...data} />}
    </div>
  );
}
