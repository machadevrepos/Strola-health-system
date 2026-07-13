"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { ConnectedAppsView } from "@/components/connected-apps/connected-apps-view";
import { fetchIntegrationConnections, fetchUsers } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

async function loadConnectedApps() {
  const [users, connections] = await Promise.all([fetchUsers(), fetchIntegrationConnections()]);
  return { users, connections };
}

export default function ConnectedAppsPage() {
  const { data, loading, error, reload } = useApiData(loadConnectedApps);

  return (
    <div>
      <PageHeader title="Connected Apps" description="Which health platforms and wearables users have linked to Strolla." />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <ConnectedAppsView users={data.users} connections={data.connections} />}
    </div>
  );
}
