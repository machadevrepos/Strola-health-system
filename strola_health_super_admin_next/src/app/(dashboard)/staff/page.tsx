"use client";

import { IdentificationBadge, Crown } from "@phosphor-icons/react";
import { PageHeader } from "@/components/shell/page-header";
import { StatCard } from "@/components/shell/stat-card";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { StaffTable } from "@/components/staff/staff-table";
import { fetchUsers } from "@/lib/data/api";
import { listPromotableUsers, listStaff } from "@/lib/data/queries";
import { useApiData } from "@/lib/use-api-data";
import { formatNumber } from "@/lib/format";

async function loadStaff() {
  const users = await fetchUsers();
  return { staff: listStaff(users), promotable: listPromotableUsers(users) };
}

export default function StaffPage() {
  const { data, loading, error, reload } = useApiData(loadStaff);
  const superAdmins = data?.staff.filter((s) => s.role === "super_admin").length ?? 0;

  return (
    <div>
      <PageHeader
        title="Staff & Roles"
        description="Grant or revoke admin and super admin access. Super-admin only."
      />

      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && (
        <>
          <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
            <StatCard label="Total staff" value={formatNumber(data.staff.length)} icon={<IdentificationBadge size={16} />} />
            <StatCard label="Super admins" value={formatNumber(superAdmins)} icon={<Crown size={16} />} />
          </div>

          <Card className="mt-3 border-border shadow-none">
            <CardHeader>
              <CardTitle>Staff members</CardTitle>
            </CardHeader>
            <CardContent>
              <StaffTable staff={data.staff} promotable={data.promotable} />
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}
