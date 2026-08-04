"use client";

import * as React from "react";
import Link from "next/link";
import { toast } from "sonner";
import { UserMinus } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { RoleChangeDialog, type PendingRoleChange } from "@/components/users/role-change-dialog";
import { PromoteStaffDialog } from "@/components/staff/promote-staff-dialog";
import { userDisplayName } from "@/lib/data/queries";
import { changeUserRole } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { useAuth } from "@/lib/auth-context";
import { formatDate, initials, ROLE_LABEL } from "@/lib/format";
import { logAction } from "@/lib/audit-log-store";
import type { Role, UserProfile } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

export function StaffTable({
  staff: initialStaff,
  promotable,
}: {
  staff: UserProfile[];
  promotable: UserProfile[];
}) {
  const { role: viewerRole } = useAuth();
  // Backend-enforced too (setUserRole requires super_admin for any change
  // that touches the admin/super_admin tier) — gating it here as well so a
  // plain admin sees a disabled control instead of a permission error after
  // picking a target and confirming.
  const isSuperAdmin = viewerRole === "super_admin";
  const [staff, setStaff] = React.useState(initialStaff);
  const [promoteOpen, setPromoteOpen] = React.useState(false);
  const [pendingTarget, setPendingTarget] = React.useState<UserProfile | null>(null);
  const [pendingRole, setPendingRole] = React.useState<PendingRoleChange | null>(null);

  React.useEffect(() => setStaff(initialStaff), [initialStaff]);

  const promotableNow = promotable.filter((u) => !staff.some((s) => s.id === u.id));

  function requestRoleChange(user: UserProfile, role: Role) {
    if (role === user.role) return;
    setPendingTarget(user);
    setPendingRole({ userName: userDisplayName(user), role });
  }

  async function confirmRoleChange() {
    if (!pendingTarget || !pendingRole) return;
    const { role } = pendingRole;
    try {
      await changeUserRole(pendingTarget.id, role);
      if (role === "user") {
        setStaff((prev) => prev.filter((s) => s.id !== pendingTarget.id));
        toast.success(`${userDisplayName(pendingTarget)} removed from staff`);
        logAction("Removed staff access", userDisplayName(pendingTarget));
      } else {
        setStaff((prev) => prev.map((s) => (s.id === pendingTarget.id ? { ...s, role } : s)));
        toast.success(`${userDisplayName(pendingTarget)} is now ${ROLE_LABEL[role]}`);
        logAction(`Changed role to ${ROLE_LABEL[role]}`, userDisplayName(pendingTarget));
      }
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't change role"));
    } finally {
      setPendingTarget(null);
      setPendingRole(null);
    }
  }

  async function promote(user: UserProfile, role: "admin" | "super_admin") {
    try {
      await changeUserRole(user.id, role);
      setStaff((prev) => [...prev, { ...user, role }]);
      toast.success(`${userDisplayName(user)} promoted to ${ROLE_LABEL[role]}`);
      logAction(`Promoted to ${ROLE_LABEL[role]}`, userDisplayName(user));
      setPromoteOpen(false);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't promote user"));
    }
  }

  return (
    <div className="space-y-3">
      {!isSuperAdmin && (
        <p className="rounded-md border border-border bg-secondary/40 p-3 text-xs text-muted-foreground">
          Only super admins can change staff access — you can review who has it, but promoting, demoting, and removing
          are disabled for your role.
        </p>
      )}
      <div className="flex justify-end">
        <Button size="sm" onClick={() => setPromoteOpen(true)} disabled={!isSuperAdmin}>
          Promote a user
        </Button>
      </div>

      <Table>
        <TableHeader>
          <TableRow className="hover:bg-transparent">
            <TableHead>Staff member</TableHead>
            <TableHead>Role</TableHead>
            <TableHead>Staff since</TableHead>
            <TableHead className="w-32" />
          </TableRow>
        </TableHeader>
        <TableBody>
          {staff.map((member) => (
            <TableRow key={member.id}>
              <TableCell>
                <Link href={`/users/${member.id}`} className="flex items-center gap-2.5 hover:underline">
                  <Avatar className="size-8">
                    <AvatarFallback className="text-xs">{initials(userDisplayName(member))}</AvatarFallback>
                  </Avatar>
                  <div>
                    <p className="font-medium text-foreground">{userDisplayName(member)}</p>
                    <p className="text-xs text-muted-foreground">{member.email}</p>
                  </div>
                </Link>
              </TableCell>
              <TableCell>
                <Select value={member.role} onValueChange={(v) => v && requestRoleChange(member, v as Role)} disabled={!isSuperAdmin}>
                  <SelectTrigger size="sm" className="w-36">
                    <SelectValue>{ROLE_LABEL[member.role]}</SelectValue>
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="admin">{ROLE_LABEL.admin}</SelectItem>
                    <SelectItem value="super_admin">{ROLE_LABEL.super_admin}</SelectItem>
                  </SelectContent>
                </Select>
              </TableCell>
              <TableCell className="text-muted-foreground">{formatDate(member.created_at)}</TableCell>
              <TableCell>
                <Button variant="ghost" size="sm" onClick={() => requestRoleChange(member, "user")} disabled={!isSuperAdmin}>
                  <UserMinus size={14} /> Remove
                </Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      <PromoteStaffDialog
        open={promoteOpen}
        onOpenChange={setPromoteOpen}
        candidates={promotableNow}
        onPromote={promote}
      />
      <RoleChangeDialog
        pending={pendingRole}
        onOpenChange={(open) => {
          if (!open) {
            setPendingRole(null);
            setPendingTarget(null);
          }
        }}
        onConfirm={confirmRoleChange}
      />
    </div>
  );
}
