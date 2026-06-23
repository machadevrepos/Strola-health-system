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
import type { EnrichedPost } from "@/lib/data/queries";

export function EditPostDialog({
  post,
  onOpenChange,
  onSave,
}: {
  post: EnrichedPost | null;
  onOpenChange: (open: boolean) => void;
  onSave: (content: string) => void | Promise<void>;
}) {
  const [content, setContent] = React.useState("");
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (post) setContent(post.content);
  }, [post]);

  async function handleSave() {
    setSubmitting(true);
    try {
      await onSave(content.trim());
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Dialog open={!!post} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Edit post content</DialogTitle>
          <DialogDescription>A correction, not a moderation action — the post stays visible.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-2">
          <Label htmlFor="post-content">Content</Label>
          <Textarea id="post-content" value={content} onChange={(e) => setContent(e.target.value)} rows={4} autoFocus />
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button disabled={content.trim().length === 0 || submitting} onClick={handleSave}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Save
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
