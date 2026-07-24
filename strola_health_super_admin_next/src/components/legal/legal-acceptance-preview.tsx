"use client";

import { Button } from "@/components/ui/button";

// The blocking re-accept prompt an in-app gate would show — not built yet
// (see the LegalAcceptance type comment), but this is what an admin should
// be able to check before publishing a version that requires it.
export function LegalAcceptancePreview({ title }: { title: string }) {
  return (
    <div className="mx-auto flex w-full max-w-[320px] items-center justify-center rounded-[28px] bg-secondary p-3">
      <div className="w-full rounded-2xl bg-background p-4 shadow-[0_8px_24px_rgba(0,0,0,0.12)]">
        <p className="text-base font-semibold text-foreground">{title} Updated</p>
        <p className="mt-1.5 text-sm text-muted-foreground">
          We&apos;ve updated our {title}. Please review and accept before continuing.
        </p>
        <div className="mt-4 flex flex-col gap-2">
          <Button variant="outline" className="w-full">
            Read {title}
          </Button>
          <Button className="w-full">Accept</Button>
        </div>
      </div>
    </div>
  );
}
