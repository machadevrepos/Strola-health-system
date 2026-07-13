"use client";

import * as React from "react";
import Link from "next/link";
import { toast } from "sonner";
import {
  Plus,
  BatteryMedium,
  LinkBreak,
  CircleNotch,
  ArrowsLeftRight,
  DownloadSimple,
  Trash,
  DotsThree,
} from "@phosphor-icons/react";
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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
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
import { findUserById, listPromotableUsers, userDisplayName } from "@/lib/data/queries";
import { adminUnpairDevice, deleteDevice, markDeviceReplaced, provisionDevice, pushFirmwareUpdate, reassignDevice } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { formatDate, formatDateTime } from "@/lib/format";
import { logAction } from "@/lib/audit-log-store";
import type { Device, UserProfile } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

export function DevicesPanel({ devices: initialDevices, users }: { devices: Device[]; users: UserProfile[] }) {
  const [devices, setDevices] = React.useState(initialDevices);
  const [provisionOpen, setProvisionOpen] = React.useState(false);
  const [serial, setSerial] = React.useState("");
  const [batch, setBatch] = React.useState("");
  const [unpairTarget, setUnpairTarget] = React.useState<Device | null>(null);
  const [provisioning, setProvisioning] = React.useState(false);
  const [unpairing, setUnpairing] = React.useState(false);
  const [reassignTarget, setReassignTarget] = React.useState<Device | null>(null);
  const [reassignUserId, setReassignUserId] = React.useState("");
  const [reassigning, setReassigning] = React.useState(false);
  const [firmwareTarget, setFirmwareTarget] = React.useState<Device | null>(null);
  const [firmwareVersion, setFirmwareVersion] = React.useState("");
  const [pushingFirmware, setPushingFirmware] = React.useState(false);
  const [replaceTarget, setReplaceTarget] = React.useState<Device | null>(null);
  const [replacing, setReplacing] = React.useState(false);
  const [deleteDeviceTarget, setDeleteDeviceTarget] = React.useState<Device | null>(null);
  const [deletingDevice, setDeletingDevice] = React.useState(false);

  React.useEffect(() => setDevices(initialDevices), [initialDevices]);
  React.useEffect(() => {
    if (firmwareTarget) setFirmwareVersion(firmwareTarget.firmware_version ?? "");
  }, [firmwareTarget]);

  const paired = devices.filter((d) => d.owner_user_id);
  const unpaired = devices.filter((d) => !d.owner_user_id && !d.replaced_at);
  const promotable = listPromotableUsers(users);

  async function confirmReassign() {
    if (!reassignTarget || !reassignUserId) return;
    setReassigning(true);
    try {
      const updated = await reassignDevice(reassignTarget.id, reassignUserId);
      setDevices((prev) => prev.map((d) => (d.id === reassignTarget.id ? updated : d)));
      toast.success(`${reassignTarget.serial_number} reassigned to ${userDisplayName(findUserById(users, reassignUserId))}`);
      logAction("Reassigned device", `${reassignTarget.serial_number} → ${userDisplayName(findUserById(users, reassignUserId))}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't reassign this device"));
    } finally {
      setReassigning(false);
      setReassignTarget(null);
      setReassignUserId("");
    }
  }

  async function confirmPushFirmware() {
    if (!firmwareTarget || !firmwareVersion.trim()) return;
    setPushingFirmware(true);
    try {
      const updated = await pushFirmwareUpdate(firmwareTarget.id, firmwareVersion.trim());
      setDevices((prev) => prev.map((d) => (d.id === firmwareTarget.id ? updated : d)));
      toast.success(`Firmware ${firmwareVersion.trim()} pushed to ${firmwareTarget.serial_number}`);
      logAction("Pushed firmware update", `${firmwareTarget.serial_number} → ${firmwareVersion.trim()}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't push this firmware update"));
    } finally {
      setPushingFirmware(false);
      setFirmwareTarget(null);
    }
  }

  async function confirmMarkReplaced() {
    if (!replaceTarget) return;
    setReplacing(true);
    try {
      const updated = await markDeviceReplaced(replaceTarget.id);
      setDevices((prev) => prev.map((d) => (d.id === replaceTarget.id ? updated : d)));
      toast.success(`${replaceTarget.serial_number} marked as replaced`);
      logAction("Marked device replaced", replaceTarget.serial_number);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't mark this device replaced"));
    } finally {
      setReplacing(false);
      setReplaceTarget(null);
    }
  }

  async function confirmDeleteDevice() {
    if (!deleteDeviceTarget) return;
    setDeletingDevice(true);
    try {
      await deleteDevice(deleteDeviceTarget.id);
      setDevices((prev) => prev.filter((d) => d.id !== deleteDeviceTarget.id));
      toast.success(`${deleteDeviceTarget.serial_number} deleted`);
      logAction("Deleted device", deleteDeviceTarget.serial_number);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't delete this device"));
    } finally {
      setDeletingDevice(false);
      setDeleteDeviceTarget(null);
    }
  }

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
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-sm font-medium text-foreground">Fleet</h3>
          <p className="text-xs text-muted-foreground">
            {paired.length} paired {"·"} {unpaired.length} in stock
          </p>
        </div>
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
                <TableCell>
                  <p className="font-mono text-sm">{d.serial_number}</p>
                  <p className="font-mono text-xs text-muted-foreground">{d.ble_mac ?? "no MAC yet"} · provisioned {formatDate(d.created_at)}</p>
                </TableCell>
                <TableCell className="text-muted-foreground">{d.manufacturing_batch ?? "—"}</TableCell>
                <TableCell>
                  {d.replaced_at ? (
                    <Badge variant="outline">Replaced</Badge>
                  ) : owner ? (
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
                  {!d.replaced_at && (
                    <DropdownMenu>
                      <DropdownMenuTrigger
                        render={<button type="button" className="rounded-md p-1.5 text-muted-foreground hover:bg-muted hover:text-foreground" aria-label="Device actions" />}
                      >
                        <DotsThree size={18} weight="bold" />
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => { setReassignTarget(d); setReassignUserId(d.owner_user_id ?? ""); }}>
                          <ArrowsLeftRight size={14} /> Reassign
                        </DropdownMenuItem>
                        <DropdownMenuItem onClick={() => setFirmwareTarget(d)}>
                          <DownloadSimple size={14} /> Push firmware update
                        </DropdownMenuItem>
                        {d.owner_user_id && (
                          <DropdownMenuItem onClick={() => setUnpairTarget(d)}>
                            <LinkBreak size={14} /> Force unpair
                          </DropdownMenuItem>
                        )}
                        {!d.owner_user_id && !d.paired_at ? (
                          <DropdownMenuItem variant="destructive" onClick={() => setDeleteDeviceTarget(d)}>
                            <Trash size={14} /> Delete (never paired)
                          </DropdownMenuItem>
                        ) : (
                          <DropdownMenuItem variant="destructive" onClick={() => setReplaceTarget(d)}>
                            <Trash size={14} /> Mark replaced
                          </DropdownMenuItem>
                        )}
                      </DropdownMenuContent>
                    </DropdownMenu>
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

      <Dialog open={!!reassignTarget} onOpenChange={(open) => !open && setReassignTarget(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Reassign {reassignTarget?.serial_number}</DialogTitle>
            <DialogDescription>
              Pairs this device to a different user directly — a support-desk shortcut for a device physically handed
              to someone else, rather than making them unpair and re-pair it themselves.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-2">
            <Label htmlFor="reassign-user">New owner</Label>
            <Select value={reassignUserId} onValueChange={(v) => setReassignUserId(v ?? "")}>
              <SelectTrigger id="reassign-user">
                <SelectValue placeholder="Choose a user">
                  {reassignUserId ? userDisplayName(findUserById(users, reassignUserId)) : "Choose a user"}
                </SelectValue>
              </SelectTrigger>
              <SelectContent>
                {promotable.map((u) => (
                  <SelectItem key={u.id} value={u.id}>
                    {userDisplayName(u)} — {u.email ?? `@${u.username}`}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setReassignTarget(null)} disabled={reassigning}>
              Cancel
            </Button>
            <Button disabled={!reassignUserId || reassigning} onClick={confirmReassign}>
              {reassigning && <CircleNotch size={14} className="animate-spin" />}
              Reassign
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={!!firmwareTarget} onOpenChange={(open) => !open && setFirmwareTarget(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Push firmware update — {firmwareTarget?.serial_number}</DialogTitle>
            <DialogDescription>Sets the version this device reports next time it connects.</DialogDescription>
          </DialogHeader>
          <div className="grid gap-2">
            <Label htmlFor="firmware-version">Version</Label>
            <Input id="firmware-version" value={firmwareVersion} onChange={(e) => setFirmwareVersion(e.target.value)} placeholder="1.5.0" autoFocus />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setFirmwareTarget(null)} disabled={pushingFirmware}>
              Cancel
            </Button>
            <Button disabled={firmwareVersion.trim().length === 0 || pushingFirmware} onClick={confirmPushFirmware}>
              {pushingFirmware && <CircleNotch size={14} className="animate-spin" />}
              Push update
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AlertDialog open={!!replaceTarget} onOpenChange={(open) => !open && setReplaceTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Mark {replaceTarget?.serial_number} as replaced?</AlertDialogTitle>
            <AlertDialogDescription>
              Retires this unit permanently (lost, warranty swap) — unlike a plain unpair, it won&apos;t show up as
              available stock again. The current owner (if any) is unpaired as part of this.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={replacing}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmMarkReplaced} disabled={replacing} className="bg-destructive text-white hover:bg-destructive/90">
              {replacing && <CircleNotch size={14} className="animate-spin" />}
              Mark replaced
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <AlertDialog open={!!deleteDeviceTarget} onOpenChange={(open) => !open && setDeleteDeviceTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete {deleteDeviceTarget?.serial_number}?</AlertDialogTitle>
            <AlertDialogDescription>
              This unit has never been paired, so there&apos;s no ownership or warranty history to lose — it&apos;s
              removed from the fleet entirely. For a device that&apos;s already been used, use &quot;Mark
              replaced&quot; instead.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deletingDevice}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDeleteDevice} disabled={deletingDevice} className="bg-destructive text-white hover:bg-destructive/90">
              {deletingDevice && <CircleNotch size={14} className="animate-spin" />}
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
