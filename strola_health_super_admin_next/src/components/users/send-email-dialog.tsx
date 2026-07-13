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
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { userDisplayName } from "@/lib/data/queries";
import type { UserProfile } from "@/lib/types";

export function SendEmailDialog({
  user,
  onOpenChange,
  onConfirm,
}: {
  user: UserProfile | null;
  onOpenChange: (open: boolean) => void;
  onConfirm: (values: { subject: string; body: string }) => void | Promise<void>;
}) {
  const [subject, setSubject] = React.useState("");
  const [body, setBody] = React.useState("");
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (user) {
      setSubject("");
      setBody("");
    }
  }, [user]);

  async function handleSend() {
    setSubmitting(true);
    try {
      await onConfirm({ subject: subject.trim(), body: body.trim() });
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Dialog open={!!user} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Email {user ? userDisplayName(user) : "this user"}</DialogTitle>
          <DialogDescription>
            Sent to {user?.email ?? "their registered email"} as a one-off message, separate from any push
            notification or in-app announcement.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-3">
          <div className="grid gap-2">
            <Label htmlFor="email-subject">Subject</Label>
            <Input id="email-subject" value={subject} onChange={(e) => setSubject(e.target.value)} autoFocus />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="email-body">Message</Label>
            <Textarea id="email-body" value={body} onChange={(e) => setBody(e.target.value)} rows={5} />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button
            disabled={subject.trim().length === 0 || body.trim().length === 0 || submitting}
            onClick={handleSend}
          >
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Send email
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
