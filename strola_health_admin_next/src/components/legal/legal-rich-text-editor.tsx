"use client";

import * as React from "react";
import { LinkSimple, ListBullets, ListNumbers, TextB, TextHOne, TextHTwo } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";

interface TransformResult {
  text: string;
  start: number;
  end: number;
}

function wrapSelection(text: string, start: number, end: number, prefix: string, suffix: string): TransformResult {
  const selected = text.slice(start, end) || "text";
  const next = text.slice(0, start) + prefix + selected + suffix + text.slice(end);
  return { text: next, start: start + prefix.length, end: start + prefix.length + selected.length };
}

// Applied per-line, not per-list — a numbered-list click always inserts
// "1. " on every touched line rather than auto-numbering 1/2/3, the same
// simplification most lightweight markdown toolbars make. Good enough for
// legal copy; the admin can renumber by hand if it matters.
function prefixLines(text: string, start: number, end: number, prefix: string): TransformResult {
  const lineStart = text.lastIndexOf("\n", start - 1) + 1;
  let lineEnd = text.indexOf("\n", end);
  if (lineEnd === -1) lineEnd = text.length;
  const segment = text.slice(lineStart, lineEnd);
  const lines = segment.split("\n").map((l) => (l.startsWith(prefix) ? l : `${prefix}${l}`));
  const joined = lines.join("\n");
  const next = text.slice(0, lineStart) + joined + text.slice(lineEnd);
  return { text: next, start: lineStart, end: lineStart + joined.length };
}

function insertLink(text: string, start: number, end: number): TransformResult {
  const label = text.slice(start, end) || "link text";
  const token = `[${label}](https://)`;
  const next = text.slice(0, start) + token + text.slice(end);
  const urlStart = start + label.length + 3; // just after "[label]("
  return { text: next, start: urlStart, end: urlStart + "https://".length };
}

export function LegalRichTextEditor({ value, onChange }: { value: string; onChange: (value: string) => void }) {
  const textareaRef = React.useRef<HTMLTextAreaElement>(null);

  function apply(transform: (text: string, start: number, end: number) => TransformResult) {
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
      <div className="flex flex-wrap items-center gap-0.5 rounded-t-lg border border-b-0 border-input bg-secondary/40 p-1">
        <Button type="button" variant="ghost" size="icon-sm" title="Heading" onClick={() => apply((t, s, e) => prefixLines(t, s, e, "# "))}>
          <TextHOne size={15} />
        </Button>
        <Button type="button" variant="ghost" size="icon-sm" title="Subheading" onClick={() => apply((t, s, e) => prefixLines(t, s, e, "## "))}>
          <TextHTwo size={15} />
        </Button>
        <Button type="button" variant="ghost" size="icon-sm" title="Bold" onClick={() => apply((t, s, e) => wrapSelection(t, s, e, "**", "**"))}>
          <TextB size={15} />
        </Button>
        <Button type="button" variant="ghost" size="icon-sm" title="Bullet list" onClick={() => apply((t, s, e) => prefixLines(t, s, e, "- "))}>
          <ListBullets size={15} />
        </Button>
        <Button type="button" variant="ghost" size="icon-sm" title="Numbered list" onClick={() => apply((t, s, e) => prefixLines(t, s, e, "1. "))}>
          <ListNumbers size={15} />
        </Button>
        <Button type="button" variant="ghost" size="icon-sm" title="Link" onClick={() => apply(insertLink)}>
          <LinkSimple size={15} />
        </Button>
      </div>
      <Textarea
        ref={textareaRef}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        rows={16}
        className="rounded-t-none border-t-0 font-mono text-sm"
      />
    </div>
  );
}
