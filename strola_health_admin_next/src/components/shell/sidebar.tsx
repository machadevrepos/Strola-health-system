"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
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
  GearSix,
  SignOut,
} from "@phosphor-icons/react";
import { cn } from "@/lib/utils";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { initials, ROLE_LABEL } from "@/lib/format";
import { useAuth } from "@/lib/auth-context";

const NAV_ITEMS = [
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
  { href: "/settings", label: "Settings", icon: GearSix },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, role, signOut } = useAuth();
  const operatorName = user?.displayName || user?.email || "Signed in";
  const operatorRole = role ? ROLE_LABEL[role] : "";

  return (
    <aside className="flex h-full w-60 flex-col border-r border-sidebar-border bg-sidebar">
      <div className="flex h-14 items-center gap-2 px-4">
        <div className="flex size-7 items-center justify-center rounded-md bg-primary text-sm font-semibold text-primary-foreground">
          S
        </div>
        <span className="text-sm font-semibold text-foreground">Strolla Admin</span>
      </div>

      <nav className="flex flex-1 flex-col gap-0.5 px-2 py-2">
        {NAV_ITEMS.map((item) => {
          const active = item.href === "/" ? pathname === "/" : pathname.startsWith(item.href);
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              data-active={active}
              className={cn(
                "group flex items-center gap-2.5 rounded-md px-2.5 py-2 text-sm font-medium text-sidebar-foreground/70 transition-colors",
                "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
                "data-[active=true]:bg-sidebar-primary data-[active=true]:text-sidebar-primary-foreground"
              )}
            >
              <Icon size={18} weight={active ? "fill" : "regular"} className="shrink-0" />
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="flex items-center gap-2.5 border-t border-sidebar-border px-3 py-3">
        <Avatar className="size-8">
          <AvatarFallback className="bg-sidebar-accent text-xs font-medium text-sidebar-accent-foreground">
            {initials(operatorName)}
          </AvatarFallback>
        </Avatar>
        <div className="flex-1 overflow-hidden">
          <p className="truncate text-xs font-medium text-sidebar-foreground">{operatorName}</p>
          <p className="truncate text-[11px] text-sidebar-foreground/60">{operatorRole}</p>
        </div>
        <button
          type="button"
          aria-label="Sign out"
          onClick={() => signOut().then(() => router.replace("/login"))}
          className="rounded-md p-1.5 text-sidebar-foreground/50 transition-colors hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
        >
          <SignOut size={16} />
        </button>
      </div>
    </aside>
  );
}
