"use client";

import * as React from "react";
import { CircleNotch } from "@phosphor-icons/react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import type { EnrichedReport } from "@/lib/data/queries";
import type { ReportStatus } from "@/lib/types";

export function ResolveReportDialog({
  report,
  onOpenChange,
  onResolve,
}: {
  report: EnrichedReport | null;
  onOpenChange: (open: boolean) => void;
  onResolve: (status: ReportStatus, note: string) => void | Promise<void>;
}) {
  const [note, setNote] = React.useState("");
  const [submitting, setSubmitting] = React.useState<ReportStatus | null>(null);

  React.useEffect(() => {
    if (report) setNote("");
  }, [report]);

  async function handleResolve(status: ReportStatus) {
    setSubmitting(status);
    try {
      await onResolve(status, note.trim());
    } finally {
      setSubmitting(null);
    }
  }

  return (
    <Dialog open={!!report} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Resolve report</DialogTitle>
          <DialogDescription>{report?.reason}</DialogDescription>
        </DialogHeader>
        <div className="grid gap-2">
          <Label htmlFor="resolution-note">Resolution note (visible to other admins)</Label>
          <Textarea
            id="resolution-note"
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="What action did you take, and why?"
            rows={3}
            autoFocus
          />
        </div>
        <DialogFooter className="sm:justify-between">
          <Button
            variant="outline"
            onClick={() => handleResolve("dismissed")}
            disabled={note.trim().length === 0 || submitting !== null}
          >
            {submitting === "dismissed" && <CircleNotch size={14} className="animate-spin" />}
            Ignore, no action needed
          </Button>
          <Button onClick={() => handleResolve("resolved")} disabled={note.trim().length === 0 || submitting !== null}>
            {submitting === "resolved" && <CircleNotch size={14} className="animate-spin" />}
            Mark resolved
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
