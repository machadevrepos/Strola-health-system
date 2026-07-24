"use client";

import { renderToStaticMarkup } from "react-dom/server";
import { LegalMarkdown } from "@/components/legal/legal-markdown";
import { formatDate } from "@/lib/format";

// Opens a new tab with the document formatted for print and triggers the
// browser's print dialog — "Save as PDF" from there produces a real PDF of
// exactly what's on screen, with no PDF-generation library needed. Reuses
// LegalMarkdown's own renderer (via renderToStaticMarkup) so the export
// always matches what the in-app preview shows.
export function exportLegalDocumentPdf(doc: { title: string; version: number; effectiveDate: string; content: string }) {
  const bodyHtml = renderToStaticMarkup(<LegalMarkdown content={doc.content} />);
  const win = window.open("", "_blank", "width=800,height=1000");
  if (!win) return;
  win.document.write(`<!doctype html>
<html>
<head>
<meta charset="utf-8" />
<title>${doc.title} — v${doc.version}</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color: #222; max-width: 680px; margin: 48px auto; padding: 0 24px; line-height: 1.6; }
  h2 { font-size: 22px; margin: 0 0 4px; }
  h3 { font-size: 17px; margin: 22px 0 6px; }
  p, ul, ol { font-size: 14px; margin: 0 0 10px; }
  ul, ol { padding-left: 22px; }
  a { color: #E07A7A; }
  .meta { color: #767676; font-size: 12px; margin: 0 0 28px; border-bottom: 1px solid #eee; padding-bottom: 16px; }
  @media print { body { margin: 0; padding: 24px; } }
</style>
</head>
<body>
  <h2>${doc.title}</h2>
  <p class="meta">Version ${doc.version} &middot; Effective ${formatDate(doc.effectiveDate)}</p>
  ${bodyHtml}
</body>
</html>`);
  win.document.close();
  win.focus();
  win.print();
}
