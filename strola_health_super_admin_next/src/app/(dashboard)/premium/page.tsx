"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { PremiumView } from "@/components/premium/premium-view";
import { fetchAppSettings, fetchUsers } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

async function loadPremium() {
  const [users, appSettings] = await Promise.all([fetchUsers(), fetchAppSettings()]);
  return { users, appSettings };
}

export default function PremiumPage() {
  const { data, loading, error, reload } = useApiData(loadPremium);

  return (
    <div>
      <PageHeader title="Premium" description="Subscribers, expirations, and admin-granted comp access." />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <PremiumView users={data.users} appSettings={data.appSettings} />}
    </div>
  );
}
