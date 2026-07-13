"use client";

import { PageHeader } from "@/components/shell/page-header";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { PremiumView } from "@/components/premium/premium-view";
import { fetchUsers } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

export default function PremiumPage() {
  const { data: users, loading, error, reload } = useApiData(fetchUsers);

  return (
    <div>
      <PageHeader title="Premium" description="Subscribers, expirations, and admin-granted comp access." />
      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {users && <PremiumView users={users} />}
    </div>
  );
}
