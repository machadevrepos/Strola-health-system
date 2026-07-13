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
import type { EnrichedPost } from "@/lib/data/queries";

export interface EditPostValues {
  content: string;
  step_count: number | null;
  badge_emoji: string | null;
}

export function EditPostDialog({
  post,
  onOpenChange,
  onSave,
}: {
  post: EnrichedPost | null;
  onOpenChange: (open: boolean) => void;
  onSave: (values: EditPostValues) => void | Promise<void>;
}) {
  const [content, setContent] = React.useState("");
  const [stepCount, setStepCount] = React.useState("");
  const [badgeEmoji, setBadgeEmoji] = React.useState("");
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (!post) return;
    setContent(post.content);
    setStepCount(post.step_count != null ? String(post.step_count) : "");
    setBadgeEmoji(post.badge_emoji ?? "");
  }, [post]);

  async function handleSave() {
    setSubmitting(true);
    try {
      await onSave({
        content: content.trim(),
        step_count: stepCount.trim() ? Number(stepCount) : null,
        badge_emoji: badgeEmoji.trim() || null,
      });
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Dialog open={!!post} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Edit post</DialogTitle>
          <DialogDescription>A correction, not a moderation action — the post stays visible.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-3">
          <div className="grid gap-2">
            <Label htmlFor="post-content">Content</Label>
            <Textarea id="post-content" value={content} onChange={(e) => setContent(e.target.value)} rows={4} autoFocus />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="post-steps">Step count (optional)</Label>
              <Input id="post-steps" type="number" value={stepCount} onChange={(e) => setStepCount(e.target.value)} placeholder="e.g. 8500" />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="post-badge">Badge emoji (optional)</Label>
              <Input id="post-badge" value={badgeEmoji} onChange={(e) => setBadgeEmoji(e.target.value)} placeholder="🔥" />
            </div>
          </div>
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
