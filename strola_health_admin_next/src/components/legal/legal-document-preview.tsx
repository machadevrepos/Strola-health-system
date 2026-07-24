"use client";

import { CaretLeft } from "@phosphor-icons/react";
import { LegalMarkdown } from "@/components/legal/legal-markdown";

// What the app's Settings > Legal screen would show — same brand tokens as
// the rest of the in-app previews (Announcements, App Content), since this
// is genuine in-app UI, not an external surface needing OS-faithful chrome.
export function LegalDocumentPreview({ title, content }: { title: string; content: string }) {
  return (
    <div className="mx-auto w-full max-w-[320px] rounded-[28px] bg-secondary p-3">
      <div className="flex max-h-[420px] flex-col overflow-hidden rounded-2xl bg-background">
        <div className="flex shrink-0 items-center gap-2 border-b border-border px-3 py-2.5">
          <CaretLeft size={16} className="text-muted-foreground" />
          <span className="text-sm font-semibold text-foreground">{title}</span>
        </div>
        <div className="overflow-y-auto p-3.5">
          <LegalMarkdown content={content} />
        </div>
      </div>
    </div>
  );
}
