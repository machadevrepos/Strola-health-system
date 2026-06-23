"use client";

import * as React from "react";
import { Crown, CaretDown } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { GrantPremiumConfirmDialog, type PendingGrant } from "@/components/users/grant-premium-confirm-dialog";

const PRESETS = [
  { label: "7 days", days: 7, reason: "admin_grant" },
  { label: "30 days", days: 30, reason: "admin_grant" },
  { label: "90 days", days: 90, reason: "admin_grant" },
  { label: "6 months (Kickstarter)", days: 182, reason: "kickstarter_backer" },
];

export function GrantPremiumMenu({
  userName,
  onGrant,
}: {
  userName: string;
  onGrant: (until: Date, reason: string) => void | Promise<void>;
}) {
  const [pending, setPending] = React.useState<PendingGrant | null>(null);

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger render={<Button variant="outline" size="sm" />}>
          <Crown size={14} /> Grant premium <CaretDown size={12} />
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuGroup>
            <DropdownMenuLabel>Comp period</DropdownMenuLabel>
            <DropdownMenuSeparator />
            {PRESETS.map((preset) => (
              <DropdownMenuItem
                key={preset.label}
                onClick={() => {
                  const until = new Date();
                  until.setDate(until.getDate() + preset.days);
                  setPending({ userName, until, reason: preset.reason });
                }}
              >
                {preset.label}
              </DropdownMenuItem>
            ))}
          </DropdownMenuGroup>
        </DropdownMenuContent>
      </DropdownMenu>

      <GrantPremiumConfirmDialog
        pending={pending}
        onOpenChange={(open) => !open && setPending(null)}
        onConfirm={async () => {
          if (pending) await onGrant(pending.until, pending.reason);
          setPending(null);
        }}
      />
    </>
  );
}
