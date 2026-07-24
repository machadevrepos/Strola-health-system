import type { ReactNode } from "react";

// Hand-rolled, deliberately minimal — supports exactly the syntax the
// toolbar in legal-rich-text-editor.tsx can produce: "# "/"## " headings,
// "**bold**", "- " bullet lists, "1. " numbered lists, and
// "[text](url)" links. Not a general CommonMark parser, and not meant to be
// one — legal copy doesn't need tables, code blocks, or nested lists.
function renderInline(text: string, keyPrefix: string): ReactNode[] {
  const nodes: ReactNode[] = [];
  let remaining = text;
  let key = 0;
  const pattern = /(\*\*(.+?)\*\*)|(\[([^\]]+)\]\(([^)]+)\))/;
  while (remaining.length > 0) {
    const match = pattern.exec(remaining);
    if (!match) {
      nodes.push(remaining);
      break;
    }
    if (match.index > 0) nodes.push(remaining.slice(0, match.index));
    if (match[1]) {
      nodes.push(<strong key={`${keyPrefix}-${key++}`}>{match[2]}</strong>);
    } else if (match[3]) {
      nodes.push(
        <a
          key={`${keyPrefix}-${key++}`}
          href={match[5]}
          className="text-primary underline underline-offset-2"
          target="_blank"
          rel="noreferrer"
        >
          {match[4]}
        </a>
      );
    }
    remaining = remaining.slice(match.index + match[0].length);
  }
  return nodes;
}

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
