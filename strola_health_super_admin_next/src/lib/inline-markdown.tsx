import type { ReactNode } from "react";

// Hand-rolled, deliberately minimal — supports exactly "**bold**" and
// "[text](url)" links, the two things a toolbar-driven single-line editor
// can produce. Shared by legal-markdown.tsx (which adds its own block-level
// headings/lists on top) and the App Content editor's short single-string
// entries, which never need those.
export function renderInlineMarkdown(text: string, keyPrefix: string): ReactNode[] {
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
