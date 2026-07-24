"use client";

import { X } from "@phosphor-icons/react";

// Unlike a push notification, an announcement is native in-app UI — so
// unlike the OS-faithful push previews, this reuses the admin panel's own
// brand tokens directly (they're the same AppColors palette as the mobile
// app) rather than mimicking a separate visual system.
export function AnnouncementBannerPreview({ emoji, message, hasLink }: { emoji: string; message: string; hasLink: boolean }) {
  return (
    <div className="rounded-[28px] bg-secondary p-4">
      <p className="mb-3 px-1 text-[13px] font-medium text-foreground/70">Good morning, Alex 👋</p>
      <div className="flex items-start gap-2.5 rounded-2xl bg-background p-3 shadow-[0_1px_3px_rgba(0,0,0,0.08)]">
        <span className="text-xl leading-none">{emoji || "📣"}</span>
        <p className="min-w-0 flex-1 text-[13.5px] leading-snug text-foreground">
          {message || "Your announcement message goes here."}
        </p>
        <div className="flex shrink-0 items-center gap-2">
          {hasLink && <span className="text-xs font-semibold text-primary">View</span>}
          <X size={13} className="text-muted-foreground" />
        </div>
      </div>
      <div className="mt-3 h-16 rounded-2xl bg-background/60" />
    </div>
  );
}
