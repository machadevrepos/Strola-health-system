"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { PremiumView } from "@/components/premium/premium-view";
import { fetchAnalyticsEvents, fetchAppSettings, fetchUsers } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

async function loadPremium() {
  const [users, events, appSettings] = await Promise.all([fetchUsers(), fetchAnalyticsEvents(30), fetchAppSettings()]);
  return { users, events, appSettings };
}

export default function PremiumPage() {
  const { data, loading, error, reload } = useApiData(loadPremium);

  return (
    <div>
      <PageHeader title="Subscriptions" description="Active premium, revenue, trial conversion, and admin-granted comp access." />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <PremiumView users={data.users} events={data.events} appSettings={data.appSettings} />}
    </div>
  );
}
