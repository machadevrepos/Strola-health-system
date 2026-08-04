import type { ReactNode } from "react";
import { renderInlineMarkdown as renderInline } from "@/lib/inline-markdown";

// Block-level parsing here is deliberately minimal — supports exactly the
// syntax the toolbar in legal-rich-text-editor.tsx can produce: "# "/"## "
// headings, "- " bullet lists, "1. " numbered lists, on top of
// renderInline's "**bold**"/"[text](url)". Not a general CommonMark parser,
// and not meant to be one — legal copy doesn't need tables, code blocks, or
// nested lists.

export function LegalMarkdown({ content }: { content: string }) {
  const lines = content.split("\n");
  const blocks: ReactNode[] = [];
  let i = 0;
  let key = 0;

  const isBlockStart = (line: string) => line.startsWith("# ") || line.startsWith("## ") || line.startsWith("- ") || /^\d+\.\s/.test(line);

  while (i < lines.length) {
    const line = lines[i];

    if (line.trim() === "") {
      i++;
      continue;
    }

    if (line.startsWith("## ")) {
      blocks.push(
        <h3 key={key} className="mt-4 text-base font-semibold text-foreground first:mt-0">
          {renderInline(line.slice(3), `h${key++}`)}
        </h3>
      );
      i++;
      continue;
    }
    if (line.startsWith("# ")) {
      blocks.push(
        <h2 key={key} className="mt-5 text-lg font-semibold text-foreground first:mt-0">
          {renderInline(line.slice(2), `h${key++}`)}
        </h2>
      );
      i++;
      continue;
    }
    if (/^\d+\.\s/.test(line)) {
      const items: ReactNode[] = [];
      while (i < lines.length && /^\d+\.\s/.test(lines[i])) {
        items.push(<li key={items.length}>{renderInline(lines[i].replace(/^\d+\.\s/, ""), `ol${key}-${items.length}`)}</li>);
        i++;
      }
      blocks.push(
        <ol key={key++} className="ml-5 list-decimal space-y-1 text-sm text-foreground">
          {items}
        </ol>
      );
      continue;
    }
    if (line.startsWith("- ")) {
      const items: ReactNode[] = [];
      while (i < lines.length && lines[i].startsWith("- ")) {
        items.push(<li key={items.length}>{renderInline(lines[i].slice(2), `ul${key}-${items.length}`)}</li>);
        i++;
      }
      blocks.push(
        <ul key={key++} className="ml-5 list-disc space-y-1 text-sm text-foreground">
          {items}
        </ul>
      );
      continue;
    }

    const paraLines: string[] = [];
    while (i < lines.length && lines[i].trim() !== "" && !isBlockStart(lines[i])) {
      paraLines.push(lines[i]);
      i++;
    }
    blocks.push(
      <p key={key++} className="text-sm leading-relaxed text-foreground">
        {renderInline(paraLines.join(" "), `p${key}`)}
      </p>
    );
  }

  return <div className="space-y-2">{blocks}</div>;
}
