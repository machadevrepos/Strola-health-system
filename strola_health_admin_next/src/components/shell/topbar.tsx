"use client";

import Link from "next/link";
import { Bell } from "@phosphor-icons/react";
import { CommandPalette } from "@/components/shell/command-palette";
import { Badge } from "@/components/ui/badge";
import { fetchReports } from "@/lib/data/api";
import { useApiData } from "@/lib/use-api-data";

export function Topbar() {
  const { data: reports } = useApiData(fetchReports);
  const openReports = reports?.filter((r) => r.status === "open").length ?? 0;

  return (
    <header className="flex h-14 items-center justify-between border-b border-border px-5">
      <CommandPalette />
      <Link
        href="/moderation"
        className="flex items-center gap-2 rounded-md px-2.5 py-1.5 text-sm text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
      >
        <Bell size={16} />
        {openReports > 0 && (
          <Badge variant="destructive" className="h-5 min-w-5 justify-center px-1 text-[11px]">
            {openReports}
          </Badge>
        )}
      </Link>
    </header>
  );
}
