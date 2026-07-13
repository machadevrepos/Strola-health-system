"use client";

import * as React from "react";
import Link from "next/link";
import { toast } from "sonner";
import { LinkSimple, LinkBreak, Warning, CircleNotch } from "@phosphor-icons/react";
import { StatCard } from "@/components/shell/stat-card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { FunnelChart } from "@/components/charts/funnel-chart";
import { CONNECTED_APP_LABEL, type ConnectedAppProvider, connectedAppsBreakdown, findUserById, userDisplayName } from "@/lib/data/queries";
import { disconnectIntegration } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { logAction } from "@/lib/audit-log-store";
import { formatDate, formatDateTime, formatNumber } from "@/lib/format";
import type { IntegrationConnection, UserProfile } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

// Every connection this page's own error-state examples ever seed is a real
// health-app provider — this is just the type-safe fallback for the wider
// DataSource union IntegrationConnection.provider technically allows.
function providerLabel(provider: IntegrationConnection["provider"]): string {
  return CONNECTED_APP_LABEL[provider as ConnectedAppProvider] ?? provider;
}

export function ConnectedAppsView({
  users,
  connections: initialConnections,
}: {
  users: UserProfile[];
  connections: IntegrationConnection[];
}) {
  const [connections, setConnections] = React.useState(initialConnections);
  const [disconnectTarget, setDisconnectTarget] = React.useState<IntegrationConnection | null>(null);
  const [disconnecting, setDisconnecting] = React.useState(false);

  React.useEffect(() => setConnections(initialConnections), [initialConnections]);

  const breakdown = connectedAppsBreakdown(connections);
  const connectedUserCount = new Set(connections.filter((c) => c.status === "connected").map((c) => c.user_id)).size;
  const erroredConnections = connections.filter((c) => c.status === "error");
  const mostPopular = breakdown[0];

  async function confirmDisconnect() {
    if (!disconnectTarget) return;
    setDisconnecting(true);
    try {
      const updated = await disconnectIntegration(disconnectTarget.id);
      setConnections((prev) => prev.map((c) => (c.id === disconnectTarget.id ? updated : c)));
      toast.success("Disconnected");
      logAction("Force-disconnected integration", `${userDisplayName(findUserById(users, disconnectTarget.user_id))} — ${providerLabel(disconnectTarget.provider)}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't disconnect this integration"));
    } finally {
      setDisconnecting(false);
      setDisconnectTarget(null);
    }
  }

  return (
    <div>
      <div className="mb-4 grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatCard label="Users with a connected app" value={formatNumber(connectedUserCount)} icon={<LinkSimple size={16} />} />
        <StatCard label="Total connections" value={formatNumber(connections.length)} icon={<LinkSimple size={16} />} />
        <StatCard label="Most popular" value={mostPopular?.count ? mostPopular.stage : "—"} icon={<LinkSimple size={16} />} />
        <StatCard
          label="Needs reconnecting"
          value={erroredConnections.length}
          tone={erroredConnections.length > 0 ? "danger" : "default"}
          icon={<Warning size={16} />}
        />
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        <Card className="border-border shadow-none lg:col-span-2">
          <CardHeader>
            <CardTitle>Connections by app</CardTitle>
            <CardDescription>Distinct users currently connected, per platform.</CardDescription>
          </CardHeader>
          <CardContent>
            <FunnelChart data={breakdown} />
          </CardContent>
        </Card>

        <Card className="border-border shadow-none">
          <CardHeader>
            <CardTitle>Needs attention</CardTitle>
            <CardDescription>Connections in an error state.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            {erroredConnections.length === 0 && <p className="text-sm text-muted-foreground">Nothing needs attention.</p>}
            {erroredConnections.map((c) => (
              <div key={c.id} className="rounded-md border border-border p-2.5">
                <div className="flex items-center justify-between gap-2">
                  <Link href={`/users/${c.user_id}`} className="text-sm font-medium text-foreground hover:underline">
                    {userDisplayName(findUserById(users, c.user_id))}
                  </Link>
                  <Badge variant="outline" className="text-[11px]">{providerLabel(c.provider)}</Badge>
                </div>
                <p className="mt-1 text-xs text-muted-foreground">{c.error_message}</p>
                <p className="mt-1 text-xs text-muted-foreground">Last synced {c.last_synced_at ? formatDateTime(c.last_synced_at) : "never"}</p>
                <div className="mt-2 flex justify-end">
                  <Button variant="outline" size="sm" onClick={() => setDisconnectTarget(c)}>
                    <LinkBreak size={13} /> Disconnect
                  </Button>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>

      <Card className="mt-4 border-border shadow-none">
        <CardHeader>
          <CardTitle>All connections</CardTitle>
          <CardDescription>Every platform link any user has made, including scopes and when it was last synced.</CardDescription>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow className="hover:bg-transparent">
                <TableHead>User</TableHead>
                <TableHead>App</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Scopes</TableHead>
                <TableHead>Connected</TableHead>
                <TableHead>Last synced</TableHead>
                <TableHead className="w-24" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {connections.length === 0 && (
                <TableRow>
                  <TableCell colSpan={7} className="h-24 text-center text-sm text-muted-foreground">
                    No connections yet.
                  </TableCell>
                </TableRow>
              )}
              {connections.map((c) => (
                <TableRow key={c.id}>
                  <TableCell>
                    <Link href={`/users/${c.user_id}`} className="hover:underline">
                      {userDisplayName(findUserById(users, c.user_id))}
                    </Link>
                  </TableCell>
                  <TableCell>{providerLabel(c.provider)}</TableCell>
                  <TableCell>
                    {c.status === "connected" && <Badge className="bg-success/15 text-success">Connected</Badge>}
                    {c.status === "error" && <Badge className="bg-destructive/12 text-destructive">Error</Badge>}
                    {c.status === "disconnected" && <Badge variant="secondary">Disconnected</Badge>}
                  </TableCell>
                  <TableCell className="text-xs text-muted-foreground">{c.scopes.join(", ") || "—"}</TableCell>
                  <TableCell className="text-muted-foreground">{c.connected_at ? formatDate(c.connected_at) : "—"}</TableCell>
                  <TableCell className="text-muted-foreground">{c.last_synced_at ? formatDateTime(c.last_synced_at) : "—"}</TableCell>
                  <TableCell>
                    {c.status !== "disconnected" && (
                      <Button variant="ghost" size="icon-sm" aria-label="Disconnect" onClick={() => setDisconnectTarget(c)}>
                        <LinkBreak size={14} />
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <AlertDialog open={!!disconnectTarget} onOpenChange={(open) => !open && setDisconnectTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              Disconnect {disconnectTarget ? providerLabel(disconnectTarget.provider) : "this app"}?
            </AlertDialogTitle>
            <AlertDialogDescription>
              {disconnectTarget && userDisplayName(findUserById(users, disconnectTarget.user_id))} will need to
              reconnect from their own device to sync again. Their existing synced data isn&apos;t affected.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={disconnecting}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDisconnect} disabled={disconnecting} className="bg-destructive text-white hover:bg-destructive/90">
              {disconnecting && <CircleNotch size={14} className="animate-spin" />}
              Disconnect
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
