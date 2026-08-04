import { onRequest } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import type { LegalDocType, LegalDocumentVersion } from "../lib/types";

/**
 * Function #51. Publicly hosted legal pages — Firebase Hosting rewrites
 * `/legal/**` here (see firebase.json), so this is what App Store Connect's
 * "Privacy Policy URL" and the app's own Settings screen links point at.
 * Reads via the Admin SDK, not the client SDK, so there's no need to open
 * legalDocumentVersions up to unauthenticated Firestore reads just for this,
 * firestore.rules stays exactly as narrow as it already is.
 */

const SLUG_TO_DOC_TYPE: Record<string, LegalDocType> = {
  "privacy-policy": "privacy_policy",
  "terms": "terms",
  "community-guidelines": "community_guidelines",
};

const DOC_LABEL: Record<LegalDocType, string> = {
  privacy_policy: "Privacy Policy",
  terms: "Terms of Service",
  community_guidelines: "Community Guidelines",
};

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

// Only ever renders a URL we ourselves escaped via escapeHtml above, but
// belt-and-braces: reject anything that isn't a plain http(s) link so a
// "javascript:" scheme in admin-authored content can't ever execute.
function safeHref(url: string): string {
  return /^https?:\/\//i.test(url) ? escapeHtml(url) : "#";
}

// Mirrors legal-markdown.tsx's exact supported syntax ("# "/"## " headings,
// "**bold**", "- " bullets, "1. " numbered lists, "[text](url)" links) so a
// document renders identically here as it does in the admin preview — this
// is the server-side (HTML string, not React node) equivalent.
function renderInline(text: string): string {
  const pattern = /(\*\*(.+?)\*\*)|(\[([^\]]+)\]\(([^)]+)\))/g;
  let out = "";
  let lastIndex = 0;
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(text))) {
    out += escapeHtml(text.slice(lastIndex, match.index));
    if (match[1]) {
      out += `<strong>${escapeHtml(match[2])}</strong>`;
    } else if (match[3]) {
      out += `<a href="${safeHref(match[5])}" target="_blank" rel="noreferrer">${escapeHtml(match[4])}</a>`;
    }
    lastIndex = match.index + match[0].length;
  }
  out += escapeHtml(text.slice(lastIndex));
  return out;
}

function renderMarkdown(content: string): string {
  const lines = content.split("\n");
  const blocks: string[] = [];
  let i = 0;

  const isBlockStart = (line: string) => line.startsWith("# ") || line.startsWith("## ") || line.startsWith("- ") || /^\d+\.\s/.test(line);

  while (i < lines.length) {
    const line = lines[i];
    if (line.trim() === "") {
      i++;
      continue;
    }
    if (line.startsWith("## ")) {
      blocks.push(`<h3>${renderInline(line.slice(3))}</h3>`);
      i++;
      continue;
    }
    if (line.startsWith("# ")) {
      blocks.push(`<h2>${renderInline(line.slice(2))}</h2>`);
      i++;
      continue;
    }
    if (/^\d+\.\s/.test(line)) {
      const items: string[] = [];
      while (i < lines.length && /^\d+\.\s/.test(lines[i])) {
        items.push(`<li>${renderInline(lines[i].replace(/^\d+\.\s/, ""))}</li>`);
        i++;
      }
      blocks.push(`<ol>${items.join("")}</ol>`);
      continue;
    }
    if (line.startsWith("- ")) {
      const items: string[] = [];
      while (i < lines.length && lines[i].startsWith("- ")) {
        items.push(`<li>${renderInline(lines[i].slice(2))}</li>`);
        i++;
      }
      blocks.push(`<ul>${items.join("")}</ul>`);
      continue;
    }
    const paraLines: string[] = [];
    while (i < lines.length && lines[i].trim() !== "" && !isBlockStart(lines[i])) {
      paraLines.push(lines[i]);
      i++;
    }
    blocks.push(`<p>${renderInline(paraLines.join(" "))}</p>`);
  }
  return blocks.join("\n");
}

function page({ title, bodyHtml }: { title: string; bodyHtml: string }): string {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(title)} — Strolla Health</title>
<meta name="robots" content="index, follow">
<style>
  :root { color-scheme: light; }
  body { margin: 0; padding: 0; background: #FFF2F2; color: #333333; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
  main { max-width: 720px; margin: 0 auto; padding: 48px 24px 80px; }
  .brand { font-weight: 800; font-size: 20px; letter-spacing: -0.4px; color: #E07A7A; margin-bottom: 32px; }
  h1 { font-size: 28px; font-weight: 700; letter-spacing: -0.5px; margin: 0 0 8px; }
  .meta { color: rgba(51,51,51,0.6); font-size: 13px; margin-bottom: 32px; }
  h2 { font-size: 20px; font-weight: 600; margin: 32px 0 8px; }
  h3 { font-size: 16px; font-weight: 600; margin: 24px 0 6px; }
  p { line-height: 1.65; margin: 0 0 14px; }
  ul, ol { line-height: 1.65; margin: 0 0 14px; padding-left: 22px; }
  li { margin-bottom: 4px; }
  a { color: #E07A7A; }
  .empty { text-align: center; padding: 80px 24px; color: rgba(51,51,51,0.6); }
</style>
</head>
<body>
<main>
  <div class="brand">strolla</div>
  ${bodyHtml}
</main>
</body>
</html>`;
}

export const legalPage = onRequest(async (req, res) => {
  const slug = req.path.replace(/^\/legal\/?/, "").replace(/\/$/, "");
  const docType = SLUG_TO_DOC_TYPE[slug];

  if (!docType) {
    res
      .status(404)
      .set("Content-Type", "text/html; charset=utf-8")
      .set("Cache-Control", "no-store")
      .send(page({ title: "Not found", bodyHtml: `<div class="empty"><h1>Not found</h1><p>No document at this address.</p></div>` }));
    return;
  }

  const snap = await db
    .collection(Collections.legalDocumentVersions)
    .where("doc_type", "==", docType)
    .where("status", "==", "published")
    .limit(1)
    .get();

  if (snap.empty) {
    res
      .status(404)
      .set("Content-Type", "text/html; charset=utf-8")
      .set("Cache-Control", "no-store")
      .send(
        page({
          title: DOC_LABEL[docType],
          bodyHtml: `<div class="empty"><h1>${escapeHtml(DOC_LABEL[docType])}</h1><p>This document hasn't been published yet.</p></div>`,
        })
      );
    return;
  }

  const version = snap.docs[0].data() as LegalDocumentVersion;
  const effectiveDateLabel = version.effective_date
    ? new Date(version.effective_date).toLocaleDateString("en-GB", { year: "numeric", month: "long", day: "numeric" })
    : "—";

  const bodyHtml = `
    <h1>${escapeHtml(DOC_LABEL[docType])}</h1>
    <p class="meta">Version ${version.version} · Effective ${effectiveDateLabel}</p>
    ${renderMarkdown(version.content)}
  `;

  res
    .status(200)
    .set("Content-Type", "text/html; charset=utf-8")
    .set("Cache-Control", "public, max-age=300")
    .send(page({ title: DOC_LABEL[docType], bodyHtml }));
});
