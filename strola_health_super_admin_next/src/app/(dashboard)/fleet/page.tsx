"use client";

import { Devices, BatteryWarning, Package, LinkSimple } from "@phosphor-icons/react";
import { PageHeader } from "@/components/shell/page-header";
import { StatCard } from "@/components/shell/stat-card";
import { PageError, PageLoading } from "@/components/shell/page-states";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { DeviceTable } from "@/components/fleet/device-table";
import { fetchAllDevices, fetchUsers } from "@/lib/data/api";
import { fleetStats } from "@/lib/data/queries";
import { useApiData } from "@/lib/use-api-data";
import { formatNumber } from "@/lib/format";

async function loadFleet() {
  const [devices, users] = await Promise.all([fetchAllDevices(), fetchUsers()]);
  return { devices, users };
}

export default function FleetPage() {
  const { data, loading, error, reload } = useApiData(loadFleet);

  return (
    <div>
      <PageHeader
        title="Fleet"
        description="Provision hardware, track battery health, and force-unpair devices for support cases."
      />

      {loading && <PageLoading />}
      {error && <PageError message={error} onRetry={reload} />}
      {data && (
        <>
          {(() => {
            const stats = fleetStats(data.devices);
            return (
              <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
                <StatCard label="Total devices" value={formatNumber(stats.total)} icon={<Devices size={16} />} />
                <StatCard label="Paired" value={formatNumber(stats.paired)} icon={<LinkSimple size={16} />} />
                <StatCard label="In stock" value={formatNumber(stats.inStock)} icon={<Package size={16} />} />
                <StatCard
                  label="Low battery"
                  value={formatNumber(stats.lowBattery)}
                  tone={stats.lowBattery > 0 ? "danger" : "default"}
                  icon={<BatteryWarning size={16} />}
                />
              </div>
            );
          })()}

          <Card className="mt-3 border-border shadow-none">
            <CardHeader>
              <CardTitle>All devices</CardTitle>
            </CardHeader>
            <CardContent>
              <DeviceTable devices={data.devices} users={data.users} />
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}
