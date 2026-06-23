"use client";

import * as React from "react";
import Link from "next/link";
import { toast } from "sonner";
import { Plus, BatteryMedium, LinkBreak, CircleNotch } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
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
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { findUserById, userDisplayName } from "@/lib/data/queries";
import { adminUnpairDevice, provisionDevice } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { formatDateTime } from "@/lib/format";
import { logAction } from "@/lib/audit-log-store";
import type { Device, UserProfile } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

export function DeviceTable({ devices: initialDevices, users }: { devices: Device[]; users: UserProfile[] }) {
  const [devices, setDevices] = React.useState(initialDevices);
  const [provisionOpen, setProvisionOpen] = React.useState(false);
  const [serial, setSerial] = React.useState("");
  const [batch, setBatch] = React.useState("");
  const [unpairTarget, setUnpairTarget] = React.useState<Device | null>(null);
  const [provisioning, setProvisioning] = React.useState(false);
  const [unpairing, setUnpairing] = React.useState(false);

  React.useEffect(() => setDevices(initialDevices), [initialDevices]);

  async function provision() {
    if (!serial.trim()) return;
    if (devices.some((d) => d.serial_number === serial.trim())) {
      toast.error(`Serial ${serial.trim()} already exists`);
      return;
    }
    setProvisioning(true);
    try {
      const device = await provisionDevice({ serial_number: serial.trim(), manufacturing_batch: batch.trim() || null });
      setDevices((prev) => [device, ...prev]);
      toast.success(`Provisioned ${device.serial_number}`);
      logAction("Provisioned device", device.serial_number);
      setSerial("");
      setBatch("");
      setProvisionOpen(false);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't provision device"));
    } finally {
      setProvisioning(false);
    }
  }

  async function unpair() {
    if (!unpairTarget) return;
    setUnpairing(true);
    try {
      await adminUnpairDevice(unpairTarget.id);
      setDevices((prev) =>
        prev.map((d) => (d.id === unpairTarget.id ? { ...d, owner_user_id: null, paired_at: null } : d))
      );
      toast.success(`${unpairTarget.serial_number} unpaired`);
      logAction("Force-unpaired device", unpairTarget.serial_number);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't unpair device"));
    } finally {
      setUnpairing(false);
      setUnpairTarget(null);
    }
  }

  return (
    <div className="space-y-3">
      <div className="flex justify-end">
        <Button size="sm" onClick={() => setProvisionOpen(true)}>
          <Plus size={14} /> Provision device
        </Button>
      </div>

      <Table>
        <TableHeader>
          <TableRow className="hover:bg-transparent">
            <TableHead>Serial</TableHead>
            <TableHead>Batch</TableHead>
            <TableHead>Owner</TableHead>
            <TableHead>Firmware</TableHead>
            <TableHead>Battery</TableHead>
            <TableHead>Last seen</TableHead>
            <TableHead className="w-10" />
          </TableRow>
        </TableHeader>
        <TableBody>
          {devices.length === 0 && (
            <TableRow>
              <TableCell colSpan={7} className="h-24 text-center text-sm text-muted-foreground">
                No devices provisioned yet.
              </TableCell>
            </TableRow>
          )}
          {devices.map((d) => {
            const owner = d.owner_user_id ? findUserById(users, d.owner_user_id) : undefined;
            return (
              <TableRow key={d.id}>
                <TableCell className="font-mono">{d.serial_number}</TableCell>
                <TableCell className="text-muted-foreground">{d.manufacturing_batch ?? "—"}</TableCell>
                <TableCell>
                  {owner ? (
                    <Link href={`/users/${owner.id}`} className="hover:underline">
                      {userDisplayName(owner)}
                    </Link>
                  ) : (
                    <Badge variant="secondary">In stock</Badge>
                  )}
                </TableCell>
                <TableCell className="text-muted-foreground">{d.firmware_version ?? "—"}</TableCell>
                <TableCell>
                  {d.battery_level != null ? (
                    <span className="inline-flex items-center gap-1 font-mono">
                      <BatteryMedium size={14} className={d.battery_level < 15 ? "text-destructive" : "text-muted-foreground"} />
                      {d.battery_level}%
                    </span>
                  ) : (
                    "—"
                  )}
                </TableCell>
                <TableCell className="text-muted-foreground">{d.last_seen_at ? formatDateTime(d.last_seen_at) : "—"}</TableCell>
                <TableCell>
                  {d.owner_user_id && (
                    <Button variant="ghost" size="icon-sm" aria-label="Force unpair" onClick={() => setUnpairTarget(d)}>
                      <LinkBreak size={14} />
                    </Button>
                  )}
                </TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>

      <Dialog open={provisionOpen} onOpenChange={setProvisionOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Provision a new device</DialogTitle>
            <DialogDescription>Registers a unit from the factory before it&apos;s ever paired to a user.</DialogDescription>
          </DialogHeader>
          <div className="grid gap-3">
            <div className="grid gap-2">
              <Label htmlFor="dev-serial">Serial number</Label>
              <Input id="dev-serial" value={serial} onChange={(e) => setSerial(e.target.value)} placeholder="STR-10049" autoFocus />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="dev-batch">Manufacturing batch</Label>
              <Input id="dev-batch" value={batch} onChange={(e) => setBatch(e.target.value)} placeholder="B-2026-01" />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setProvisionOpen(false)} disabled={provisioning}>
              Cancel
            </Button>
            <Button disabled={serial.trim().length === 0 || provisioning} onClick={provision}>
              {provisioning && <CircleNotch size={14} className="animate-spin" />}
              Provision
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AlertDialog open={!!unpairTarget} onOpenChange={(open) => !open && setUnpairTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Force-unpair {unpairTarget?.serial_number}?</AlertDialogTitle>
            <AlertDialogDescription>
              The current owner loses their step-tracking connection immediately. Use this for support cases — a lost
              device, a warranty swap — not routine disconnects.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={unpairing}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={unpair} disabled={unpairing} className="bg-destructive text-white hover:bg-destructive/90">
              {unpairing && <CircleNotch size={14} className="animate-spin" />}
              Unpair
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
