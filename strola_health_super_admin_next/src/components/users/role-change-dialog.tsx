"use client";

import * as React from "react";
import { CircleNotch } from "@phosphor-icons/react";
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
import { ROLE_LABEL } from "@/lib/format";
import type { Role } from "@/lib/types";

export interface PendingRoleChange {
  userName: string;
  role: Role;
}

export function RoleChangeDialog({
  pending,
  onOpenChange,
  onConfirm,
}: {
  pending: PendingRoleChange | null;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void | Promise<void>;
}) {
  const [submitting, setSubmitting] = React.useState(false);
  const isElevation = pending?.role === "admin" || pending?.role === "super_admin";

  async function handleConfirm() {
    setSubmitting(true);
    try {
      await onConfirm();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AlertDialog open={!!pending} onOpenChange={onOpenChange}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>
            Change {pending?.userName} to {pending ? ROLE_LABEL[pending.role] : ""}?
          </AlertDialogTitle>
          <AlertDialogDescription>
            {isElevation
              ? "This grants access to the admin panel itself — user search, moderation, and (for Super admin) role and fleet management. Only do this for staff."
              : "This removes their admin/super admin access. They keep their regular account and activity."}
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={submitting}>Cancel</AlertDialogCancel>
          <AlertDialogAction onClick={handleConfirm} disabled={submitting}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Confirm
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
