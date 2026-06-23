"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { UsersTable } from "@/components/users/users-table";
import { fetchUsers } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

export default function UsersPage() {
  const { data: users, loading, error, reload } = useApiData(fetchUsers);

  return (
    <div>
      <PageHeader
        title="Users"
        description={users ? `${users.length} accounts — search, review, and act on any of them.` : "Loading accounts..."}
      />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {users && <UsersTable users={users} />}
    </div>
  );
}
