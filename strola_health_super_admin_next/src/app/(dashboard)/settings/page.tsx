"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { SettingsView } from "@/components/settings/settings-view";
import { fetchFeatureFlags } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

export default function SettingsPage() {
  const { data: flags, loading, error, reload } = useApiData(fetchFeatureFlags);

  return (
    <div>
      <PageHeader title="Settings" description="Feature gating and a record of every admin action this session." />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {flags && <SettingsView flags={flags} />}
    </div>
  );
}
