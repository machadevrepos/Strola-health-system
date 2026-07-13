"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import {
  ChartLineUp,
  Users,
  ShieldWarning,
  Trophy,
  BellRinging,
  Crown,
  LinkSimple,
  TextAa,
  ChartBar,
  Scales,
  Megaphone,
  Devices,
  IdentificationBadge,
  GearSix,
  MagnifyingGlass,
} from "@phosphor-icons/react";
import {
  CommandDialog,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
  CommandSeparator,
} from "@/components/ui/command";
import { fetchUsers } from "@/lib/data/api";
import { userDisplayName } from "@/lib/data/queries";
import { useApiData } from "@/lib/use-api-data";

const DESTINATIONS = [
  { href: "/", label: "Overview", icon: ChartLineUp },
  { href: "/users", label: "Users", icon: Users },
  { href: "/moderation", label: "Moderation", icon: ShieldWarning },
  { href: "/challenges", label: "Challenges & Badges", icon: Trophy },
  { href: "/premium", label: "Premium", icon: Crown },
  { href: "/notifications", label: "Push Notifications", icon: BellRinging },
  { href: "/announcements", label: "Announcements", icon: Megaphone },
  { href: "/connected-apps", label: "Connected Apps", icon: LinkSimple },
  { href: "/app-content", label: "App Content", icon: TextAa },
  { href: "/analytics", label: "Analytics", icon: ChartBar },
  { href: "/legal", label: "Legal", icon: Scales },
  { href: "/fleet", label: "Fleet", icon: Devices },
  { href: "/staff", label: "Staff & Roles", icon: IdentificationBadge },
  { href: "/settings", label: "Settings", icon: GearSix },
];

export function CommandPalette() {
  const [open, setOpen] = React.useState(false);
  const router = useRouter();
  const { data: allUsers } = useApiData(fetchUsers);
  const users = React.useMemo(() => (allUsers ?? []).slice(0, 8), [allUsers]);

  React.useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        setOpen((v) => !v);
      }
    }
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, []);

  function go(href: string) {
    setOpen(false);
    router.push(href);
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="flex h-8 w-64 items-center gap-2 rounded-md border border-border bg-background px-2.5 text-sm text-muted-foreground transition-colors hover:border-ring/40"
      >
        <MagnifyingGlass size={14} />
        <span className="flex-1 text-left">Search or jump to...</span>
        <kbd className="rounded border border-border bg-muted px-1.5 py-0.5 text-[10px] font-medium text-muted-foreground">
          ⌘K
        </kbd>
      </button>
      <CommandDialog open={open} onOpenChange={setOpen}>
        <CommandInput placeholder="Search users, or jump to a section..." />
        <CommandList>
          <CommandEmpty>No results found.</CommandEmpty>
          <CommandGroup heading="Go to">
            {DESTINATIONS.map((d) => (
              <CommandItem key={d.href} value={d.label} onSelect={() => go(d.href)}>
                <d.icon size={16} />
                {d.label}
              </CommandItem>
            ))}
          </CommandGroup>
          <CommandSeparator />
          <CommandGroup heading="Users">
            {users.map((u) => (
              <CommandItem
                key={u.id}
                value={`${userDisplayName(u)} ${u.email ?? ""}`}
                onSelect={() => go(`/users/${u.id}`)}
              >
                <Users size={16} />
                <span>{userDisplayName(u)}</span>
                {u.email && <span className="text-muted-foreground">{u.email}</span>}
              </CommandItem>
            ))}
          </CommandGroup>
        </CommandList>
      </CommandDialog>
    </>
  );
}
