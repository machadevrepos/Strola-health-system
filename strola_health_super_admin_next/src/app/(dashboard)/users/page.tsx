"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { UsersTable } from "@/components/users/users-table";
import { fetchAllDevices, fetchAnalyticsEvents, fetchUsers } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

async function loadUsers() {
  const [users, devices, events] = await Promise.all([fetchUsers(), fetchAllDevices(), fetchAnalyticsEvents(90)]);
  return { users, devices, events };
}

export default function UsersPage() {
  const { data, loading, error, reload } = useApiData(loadUsers);

  return (
    <div>
      <PageHeader
        title="Users"
        description={data ? `${data.users.length} accounts — search, review, and act on any of them.` : "Loading accounts..."}
      />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && <UsersTable users={data.users} devices={data.devices} events={data.events} />}
    </div>
  );
}
