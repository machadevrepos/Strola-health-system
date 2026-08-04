"use client";

import * as React from "react";
import { LinkSimple, TextB } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { insertLink, wrapSelection } from "@/lib/text-editor-transforms";

// App Content entries are single UI strings (a button label, a toast, a
// screen heading), never a document — no headings/lists here, just bold and
// links, the same "**bold**"/"[text](url)" syntax legal-rich-text-editor.tsx
// uses, rendered by the same renderInlineMarkdown on the preview side.
export function AppContentRichTextEditor({
  value,
  onChange,
  textareaRef,
  rows = 2,
}: {
  value: string;
  onChange: (value: string) => void;
  textareaRef: React.RefObject<HTMLTextAreaElement | null>;
  rows?: number;
}) {
  function apply(transform: (text: string, start: number, end: number) => { text: string; start: number; end: number }) {
    const el = textareaRef.current;
    if (!el) return;
    const result = transform(value, el.selectionStart, el.selectionEnd);
    onChange(result.text);
    requestAnimationFrame(() => {
      el.focus();
      el.setSelectionRange(result.start, result.end);
    });
  }

  return (
    <div>
      <div className="flex items-center gap-0.5 rounded-t-lg border border-b-0 border-input bg-secondary/40 p-1">
        <Button type="button" variant="ghost" size="icon-sm" title="Bold" onClick={() => apply((t, s, e) => wrapSelection(t, s, e, "**", "**"))}>
          <TextB size={15} />
        </Button>
        <Button type="button" variant="ghost" size="icon-sm" title="Link" onClick={() => apply(insertLink)}>
          <LinkSimple size={15} />
        </Button>
      </div>
      <Textarea
        ref={textareaRef}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        rows={rows}
        className="rounded-t-none border-t-0"
      />
    </div>
  );
}
