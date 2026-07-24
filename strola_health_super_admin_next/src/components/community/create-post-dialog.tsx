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

export interface NewPostValues {
  content: string;
  imageUrl: string | null;
}

export function CreatePostDialog({
  open,
  onOpenChange,
  onConfirm,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: (values: NewPostValues) => void | Promise<void>;
}) {
  const [content, setContent] = React.useState("");
  const [imageUrl, setImageUrl] = React.useState("");
  const [submitting, setSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (open) {
      setContent("");
      setImageUrl("");
    }
  }, [open]);

  async function handleConfirm() {
    setSubmitting(true);
    try {
      await onConfirm({ content: content.trim(), imageUrl: imageUrl.trim() || null });
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Post as Strolla Health</DialogTitle>
          <DialogDescription>
            Published immediately to the community feed under the official Strolla Health account.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-2">
          <Label htmlFor="new-post-content">Post content</Label>
          <Textarea
            id="new-post-content"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            placeholder="Share an update, tip, or announcement with the community..."
            rows={5}
            autoFocus
          />
        </div>
        <div className="grid gap-2">
          <Label htmlFor="new-post-image">Image URL (optional)</Label>
          <Input id="new-post-image" value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} placeholder="https://..." />
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button disabled={content.trim().length === 0 || submitting} onClick={handleConfirm}>
            {submitting && <CircleNotch size={14} className="animate-spin" />}
            Publish post
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
